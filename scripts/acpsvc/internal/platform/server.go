// Package platform 的 HTTP 面:平台端点、Bearer 多密钥、限流、SSE。
// 与 TS 版端点/JSON 形状兼容;新增:id 断点重放、角色 403、429/409 语义(S-0003 第 4、5 节)。
package platform

import (
	"bufio"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/acpclient"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/backend"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/fsimpl"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/session"
	"golang.org/x/time/rate"
)

// modelCatalog 是各 agent 的合法模型别名与默认(三端别名表 + pi-rs-agent 0.3.0 模型锁;
// pi 中会话换模待 pi-rs-agent 支持 set_config_option 后开放)。
var modelCatalog = map[string]struct {
	Models       []string // 建会话 model 参数合法面(spawn env 道,全清单)
	SwitchModels []string // 中会话换模合法面(四模型面,与 Models 全等)
	SwitchMode   string   // 换模道:rebuild=重拉适配器+resume 续接(claude);set=set_config_option 直通(codex)
	Default      string
}{
	// claude 适配器把 set_config_option 的任意串解析成 SDK 档位词再经 managed env 映射回
	// zp-cc GLM(适配器源码与 ds 别名实跑自证,2026-10-14),换模走重建道:
	// 以新 ANTHROPIC_MODEL 重拉适配器、session/resume 原 id 续接,会话号与事件环不变
	"claude": {Models: []string{"zp-cc-glm53[1m]", "zp-cc-glm53fh[1m]", "ds-cc-pro", "ds-cc-flash"},
		SwitchModels: []string{"zp-cc-glm53[1m]", "zp-cc-glm53fh[1m]", "ds-cc-pro", "ds-cc-flash"},
		SwitchMode:   "rebuild", Default: "zp-cc-glm53[1m]"},
	// codex 适配器认目录全别名,set_config_option 直通;第四别名 zp-cx-glm5t(目录在册)
	"codex": {Models: []string{"zp-cx-glm53", "zp-cx-glm5t", "ds-cx-pro", "ds-cx-flash"},
		SwitchModels: []string{"zp-cx-glm53", "zp-cx-glm5t", "ds-cx-pro", "ds-cx-flash"},
		SwitchMode:   "set", Default: "ds-cx-pro"},
	"pi": {Models: []string{"ds-cx-flash", "zp-cx-chat", "ds-cx-pro", "zp-cc-glm53fh"},
		SwitchModels: nil, Default: "ds-cx-flash"},
}

// handleModels 出各 agent 合法模型别名与默认(桥动态取用,免硬编码)。
func (s *Server) handleModels(w http.ResponseWriter, r *http.Request) {
	agent := r.URL.Query().Get("agent")
	out := map[string]any{}
	for a, c := range modelCatalog {
		if agent != "" && a != agent {
			continue
		}
		out[a] = map[string]any{"models": c.Models, "default": c.Default,
			"switchable": len(c.SwitchModels) > 0, "switch_models": c.SwitchModels}
	}
	if agent != "" && len(out) == 0 {
		jsonWrite(w, 400, map[string]any{"error": "未知 agent:" + agent})
		return
	}
	jsonWrite(w, 200, out)
}

// handleSessionModel 中会话换模,按 catalog.SwitchMode 分道:codex(set)直通 ACP 原生
// session/set_config_option(configId=model);claude(rebuild)走 rebuildModel 重建道。
// 回合在途 409(不排队);非法别名 400 带合法清单;适配者未实现(如 pi)400 明示。
func (s *Server) handleSessionModel(w http.ResponseWriter, r *http.Request) {
	var body struct {
		SessionID string `json:"sessionId"`
		Model     string `json:"model"`
	}
	if !readBody(w, r, &body) {
		return
	}
	sess := s.table.Get(body.SessionID)
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	cat, ok := modelCatalog[sess.Agent]
	if !ok || len(cat.SwitchModels) == 0 {
		jsonWrite(w, 400, map[string]any{"error": "该后端暂不支持中会话换模:" + sess.Agent})
		return
	}
	legal := false
	for _, m := range cat.SwitchModels {
		if m == body.Model {
			legal = true
			break
		}
	}
	if !legal {
		jsonWrite(w, 400, map[string]any{"error": "该别名仅支持建会话时指定,中会话换模可用:" +
			strings.Join(cat.SwitchModels, ", "), "legal": cat.SwitchModels})
		return
	}
	if sess.PromptInFlight() {
		jsonWrite(w, 409, map[string]any{"error": "prompt_in_flight"})
		return
	}
	def, ok := backend.Find(sess.Agent)
	if !ok {
		jsonWrite(w, 500, map[string]any{"error": "注册表缺 agent:" + sess.Agent})
		return
	}
	if cat.SwitchMode == "rebuild" {
		s.rebuildModel(w, r, sess, def, body.Model)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), handshakeTO)
	defer cancel()
	res, err := sess.Adapter().Request(ctx, "session/set_config_option", map[string]any{
		"sessionId": sess.AcpSessionID(), "configId": "model", "value": body.Model,
	})
	if err != nil {
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": sess.Adapter().StderrTail()})
		return
	}
	if s.log != nil {
		s.log.Info("session_model", "cat", "audit", "action", "session/model",
			"session_id", sess.ID, "agent", sess.Agent, "model", body.Model)
	}
	var out struct {
		ConfigOptions json.RawMessage `json:"configOptions"`
	}
	_ = json.Unmarshal(res, &out)
	jsonWrite(w, 200, map[string]any{"ok": true, "sessionId": sess.ID, "model": body.Model,
		"configOptions": out.ConfigOptions})
}

// spawnModelEnv 在注册表 env 上叠加模型道:claude 注 ANTHROPIC_MODEL(spawn env 直达,
// 任意网关别名生效),codex 生成会话级 CODEX_HOME;model 空返回烤库默认 env。
func (s *Server) spawnModelEnv(def backend.Def, model string) ([]string, error) {
	env := append([]string(nil), def.Env...)
	if model == "" {
		return env, nil
	}
	switch def.Name {
	case "claude":
		env = append(env, "ANTHROPIC_MODEL="+model)
	case "codex":
		home, err := s.codexHomeWithModel(model)
		if err != nil {
			return nil, err
		}
		env = append(env, "CODEX_HOME="+home)
	}
	return env, nil
}

// codexHomeFromEnv 从 spawn env 抽 CODEX_HOME(会话 Close 自回收用;非 codex 空)。
func codexHomeFromEnv(env []string) string {
	for _, kv := range env {
		if strings.HasPrefix(kv, "CODEX_HOME=") {
			return strings.TrimPrefix(kv, "CODEX_HOME=")
		}
	}
	return ""
}

// rebuildModel 是 claude 中会话换模的重建道:适配器 set_config_option 只认 SDK 档位词,
// 任意别名被解析回落(适配器源码与 ds 档实跑自证,2026-10-14),故以新 ANTHROPIC_MODEL
// 重拉适配器、session/resume 原 id 续接(transcript 在盘);事件环、权限桥、会话号不变。
// wire 的适配器事件以 AcpID 匹配(空会话重建后适配器发新号)。
// 占 prompt 位串行化:重建期间新 prompt 与并发换模回 409;失败不动原会话。
func (s *Server) rebuildModel(w http.ResponseWriter, r *http.Request, sess *session.Session, def backend.Def, model string) {
	if model == sess.Model {
		jsonWrite(w, 200, map[string]any{"ok": true, "sessionId": sess.ID, "model": model, "noop": true})
		return
	}
	rel, ok := sess.TryPrompt()
	if !ok {
		jsonWrite(w, 409, map[string]any{"error": "prompt_in_flight"})
		return
	}
	defer rel()
	env, err := s.spawnModelEnv(def, model)
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": "模型面生成失败:" + err.Error()})
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), handshakeTO)
	defer cancel()
	ag, err := s.spawn(def, env, sess.Cwd)
	if err != nil {
		jsonWrite(w, 502, map[string]any{"error": "agent 未就绪:" + err.Error()})
		return
	}
	caps := map[string]any{
		"fs":       map[string]any{"readTextFile": def.FS, "writeTextFile": def.FS},
		"terminal": def.Terminal,
	}
	if _, err := ag.Request(ctx, "initialize", map[string]any{"protocolVersion": 1, "clientCapabilities": caps}); err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	// 空会话(未发过 prompt,无 transcript 可续)直接底层重建换新号;
	// 已有对话走 session/resume 原号续接。对外会话号两者都恒不变。
	newAcpID := sess.AcpSessionID()
	if !sess.Prompted() {
		var sn struct {
			SessionID     string          `json:"sessionId"`
			ConfigOptions json.RawMessage `json:"configOptions"`
		}
		res, err := ag.Request(ctx, "session/new", map[string]any{"cwd": sess.Cwd, "mcpServers": []any{}})
		if err != nil || json.Unmarshal(res, &sn) != nil || sn.SessionID == "" {
			ag.Close()
			jsonWrite(w, 502, map[string]any{"error": "换模重建失败:" + err.Error(), "adapterStderr": ag.StderrTail()})
			return
		}
		newAcpID = sn.SessionID
	} else if _, err := ag.Request(ctx, "session/resume", map[string]any{
		"sessionId": newAcpID, "cwd": sess.Cwd, "mcpServers": []any{},
	}); err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": "换模续接失败:" + err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	old := sess.Adapter()
	sess.SwapAdapter(ag, newAcpID)
	sess.Model = model
	s.wire(sess)
	if s.log != nil {
		s.log.Info("rebuild_swapped", "cat", "audit", "session_id", sess.ID,
			"acp_id", newAcpID, "prompted", sess.Prompted())
	}
	go old.Close()
	if s.log != nil {
		s.log.Info("session_model", "cat", "audit", "action", "session/model(rebuild)",
			"session_id", sess.ID, "agent", sess.Agent, "model", model)
	}
	jsonWrite(w, 200, map[string]any{"ok": true, "sessionId": sess.ID, "model": model, "rebuilt": true})
}

// modelLineRe 匹配烤库 codex config 的 model 行(会话级模型覆盖用)。
var modelLineRe = regexp.MustCompile(`(?m)^model = ".*"$`)

// 限流与超时常量(建议默认,REQ-0007 R6;未压测)。
const (
	shortRouteRate  = 30 // 短请求桶:每 10 秒 30 次
	shortRouteBurst = 30
	promptTimeout   = 600 * time.Second
	handshakeTO     = 30 * time.Second
	bodyMax         = 1 << 20 // 1 MiB
	sseHeartbeat    = 15 * time.Second
)

// Config 是服务装配参数。
type Config struct {
	Port    int
	DataDir string // keys.json 与 token 所在(默认 /var/lib/acpsup)
	Log     *slog.Logger
	// SpawnFunc 覆盖默认子进程拉起(测试注假);空则按注册表真拉。
	// env 是该会话的追加环境(含模型选择注入)。
	SpawnFunc func(def backend.Def, env []string, cwd string) (*acpclient.Agent, error)
}

// Server 是平台面。
type Server struct {
	cfg   Config
	log   *slog.Logger
	table *session.Table
	terms *fsimpl.Terminals
	reg   []backend.Def

	keysMu sync.Mutex
	keys   []Key

	limMu    sync.Mutex
	limiters map[string]*rate.Limiter

	permIdxMu sync.Mutex

	vnc     *vncManager
	permIdx map[string]*session.Slot // 权限槽全局簿(requestId -> 槽)

	httpSrv *http.Server
}

// New 装配服务;会话上限取建议默认(全局 8、每密钥 4)。
// agent 白名单错配(ACPSUP_AGENTS 含未注册名/零名单)即装配失败——启动期硬错。
func New(cfg Config) (*Server, error) {
	if cfg.DataDir == "" {
		cfg.DataDir = "/var/lib/acpsup"
	}
	reg, err := backend.Allowed()
	if err != nil {
		return nil, fmt.Errorf("agent 白名单:%w", err)
	}
	perKeyMax := 4
	if v := os.Getenv("ACPSUP_KEY_SESSIONS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n >= 0 {
			perKeyMax = n
		}
	}
	if testAuthOff {
		perKeyMax = 0
	}
	// 全局会话上限可调(ACPSUP_SESSION_MAX,默认 8);无 close 面时调用方积累会压满,运营按需放宽
	globalMax := 8
	if v := os.Getenv("ACPSUP_SESSION_MAX"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			globalMax = n
		}
	}
	// VNC 直显面:重启清孤儿栈(确定性口映射走 CDP Browser.close 自退道)
	vncMgr := newVNCManager(filepath.Join(cfg.DataDir, "vnc"), cfg.Log)
	vncMgr.bootSweepAsync() // 孤儿清不阻塞启动(占槽最多吃 30s+,验收窗等不起)

	// 会话级 CODEX_HOME 基目录:重启旧账兜底清空(表空,存留即残件)
	_ = os.RemoveAll(filepath.Join(cfg.DataDir, "codex"))
	_ = os.MkdirAll(filepath.Join(cfg.DataDir, "codex"), 0o700)
	return &Server{
		cfg:      cfg,
		log:      cfg.Log,
		table:    session.NewTable(globalMax, perKeyMax),
		terms:    fsimpl.NewTerminals(),
		reg:      reg,
		limiters: make(map[string]*rate.Limiter),
		permIdx:  make(map[string]*session.Slot),
		vnc:      vncMgr,
	}, nil
}

// testAuthOff 是测试模式(ACPSUP_AUTH_OFF=1):任意请求放行,身份记 test/admin;
// 回收时去环境变量重启即回默认拒绝。
var testAuthOff = os.Getenv("ACPSUP_AUTH_OFF") == "1"

// KeysPath 是密钥文件路径。
func (s *Server) KeysPath() string { return filepath.Join(s.cfg.DataDir, "keys.json") }

// TokenPath 是旧 token 文件路径(TS 版兼容面)。
func (s *Server) TokenPath() string { return filepath.Join(s.cfg.DataDir, "token") }

// EnsureKeys 首启装密钥表:有 keys.json 读之;没有则建(产 admin 一把,打印一次;
// 旧 token 存在时导入为 legacy admin,现行调用方不用换 token)。
func (s *Server) EnsureKeys() error {
	if err := os.MkdirAll(s.cfg.DataDir, 0o700); err != nil {
		return err
	}
	s.keysMu.Lock()
	defer s.keysMu.Unlock()
	if b, err := os.ReadFile(s.KeysPath()); err == nil {
		var doc struct {
			Keys []Key `json:"keys"`
		}
		if err := json.Unmarshal(b, &doc); err != nil {
			return fmt.Errorf("keys.json 解析失败: %w", err)
		}
		s.keys = doc.Keys
		return nil
	} else if !os.IsNotExist(err) {
		return err
	}
	s.keys = nil
	tok, _ := os.ReadFile(s.TokenPath())
	if t := strings.TrimSpace(string(tok)); t != "" {
		s.keys = append(s.keys, Key{
			ID: "legacy", Hash: HashToken(t), Label: "imported-acpsup",
			Role: RoleAdmin, Created: time.Now().UTC(),
		})
	}
	newTok, hash, err := NewToken()
	if err != nil {
		return err
	}
	id, _ := randomID()
	s.keys = append(s.keys, Key{ID: id, Hash: hash, Label: "admin", Role: RoleAdmin, Created: time.Now().UTC()})
	if err := s.saveKeysLocked(); err != nil {
		return err
	}
	// token 文件同步写新 admin 键(操作者 bearer 约定):换档脚本的停机/验收从该文件取凭证,
	// 缺它会连锁假红+回滚(2026-10-14 实例实证);首启必写,后续换档保真
	if err := os.WriteFile(s.TokenPath(), []byte(newTok+"\n"), 0o600); err != nil {
		return fmt.Errorf("token 文件写失败:%w", err)
	}
	fmt.Fprintf(os.Stderr, "acpsup 新管理密钥(打印一次):%s\n", newTok)
	return nil
}

func (s *Server) saveKeysLocked() error {
	b, err := json.MarshalIndent(map[string]any{"keys": s.keys}, "", " ")
	if err != nil {
		return err
	}
	return os.WriteFile(s.KeysPath(), b, 0o600)
}

func randomID() (string, error) {
	b := make([]byte, 4)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return "k_" + hex.EncodeToString(b), nil
}

func (s *Server) limiter(keyID string) *rate.Limiter {
	s.limMu.Lock()
	defer s.limMu.Unlock()
	l, ok := s.limiters[keyID]
	if !ok {
		l = rate.NewLimiter(rate.Every(10*time.Second/shortRouteRate), shortRouteBurst)
		s.limiters[keyID] = l
	}
	return l
}

type ctxKey int

const keyCtx ctxKey = 1

func (s *Server) auth(next http.HandlerFunc, adminOnly bool, shortRoute bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		keyID := ""
		rec := &statusRecorder{ResponseWriter: w, code: 200}
		w = rec
		defer func() {
			s.access(r, keyID, rec.code)
		}()
		var tokenStr string
		if h := r.Header.Get("Authorization"); strings.HasPrefix(h, "Bearer ") {
			tokenStr = strings.TrimPrefix(h, "Bearer ")
		}
		var key Key
		if testAuthOff {
			key = Key{ID: "test", Role: RoleAdmin}
		} else {
			s.keysMu.Lock()
			keys := append([]Key(nil), s.keys...)
			s.keysMu.Unlock()
			var err error
			key, err = Check(keys, tokenStr)
			if err != nil {
				jsonWrite(w, 401, map[string]any{"error": "unauthorized"})
				return
			}
		}
		keyID = key.ID
		if adminOnly {
			if err := key.AdminOnly(); err != nil {
				jsonWrite(w, 403, map[string]any{"error": "forbidden"})
				return
			}
		}
		// 测试模式身份无意义(全员同一桶),限流随鉴权一起关;全局会话上限仍护机
		if shortRoute && !testAuthOff && !s.limiter(keyID).Allow() {
			w.Header().Set("Retry-After", "5")
			jsonWrite(w, 429, map[string]any{"error": "rate_limited"})
			return
		}
		ctx := context.WithValue(r.Context(), keyCtx, key)
		next(w, r.WithContext(ctx))
	}
}

type statusRecorder struct {
	http.ResponseWriter
	code int
}

func (r *statusRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	h, ok := r.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, errors.New("内层 ResponseWriter 不支持 Hijack")
	}
	return h.Hijack()
}

// Unwrap 暴露内层(coder/websocket 经 Unwrap 探测 http.Hijacker)。
func (r *statusRecorder) Unwrap() http.ResponseWriter { return r.ResponseWriter }

func (r *statusRecorder) WriteHeader(code int) {
	r.code = code
	r.ResponseWriter.WriteHeader(code)
}

func (r *statusRecorder) Flush() {
	if f, ok := r.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func jsonWrite(w http.ResponseWriter, code int, body any) {
	b, _ := json.Marshal(body)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_, _ = w.Write(append(b, '\n'))
}

func (s *Server) access(r *http.Request, keyID string, status int) {
	if s.log == nil {
		return
	}
	// 访问日志只记元数据;恒不记请求体(prompt 正文)与 Authorization。
	s.log.Info("http",
		"cat", "access",
		"method", r.Method,
		"path", r.URL.Path,
		"status", status,
		"key_id", keyID,
		"peer", r.RemoteAddr,
	)
}

// Handler 装路由(测试面也用它)。
func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.auth(s.handleHealth, false, true))
	mux.HandleFunc("POST /session/new", s.auth(s.handleSessionNew, false, true))
	mux.HandleFunc("POST /session/prompt", s.auth(s.handlePrompt, false, false))
	mux.HandleFunc("POST /session/cancel", s.auth(s.handleCancel, false, true))
	mux.HandleFunc("GET /vnc", s.auth(s.handleVNC, false, true))
	mux.HandleFunc("GET /vnc/desktop", s.auth(s.handleVNCDesktopKey, true, true))
	mux.HandleFunc("GET /events", s.auth(s.handleEvents, false, false))
	mux.HandleFunc("POST /permission", s.auth(s.handlePermission, false, true))
	mux.HandleFunc("GET /file", s.auth(s.handleFile, false, true))
	mux.HandleFunc("GET /models", s.auth(s.handleModels, false, true))
	mux.HandleFunc("POST /session/model", s.auth(s.handleSessionModel, false, true))
	mux.HandleFunc("POST /session/resume", s.auth(s.handleSessionResume, false, true))
	mux.HandleFunc("POST /shutdown", s.auth(s.handleShutdown, true, true))
	mux.HandleFunc("POST /keys", s.auth(s.handleKeyCreate, true, true))
	mux.HandleFunc("GET /keys", s.auth(s.handleKeyList, true, true))
	mux.HandleFunc("POST /keys/{id}/revoke", s.auth(s.handleKeyRevoke, true, true))
	return mux
}

// ListenAndServe 起服务(仅回环);内置空闲会话回收
// (ACPSUP_SESSION_IDLE 分钟,默认 30;无 close 面时防调用方积累压满上限)。
func (s *Server) ListenAndServe() error {
	go func() {
		ttl := 30 * time.Minute
		if v := os.Getenv("ACPSUP_SESSION_IDLE"); v != "" {
			if n, err := strconv.Atoi(v); err == nil && n > 0 {
				ttl = time.Duration(n) * time.Minute
			}
		}
		for range time.Tick(time.Minute) {
			if n := s.table.SweepIdle(ttl); n > 0 && s.log != nil {
				s.log.Info("session_sweep", "cat", "audit", "action", "session/sweep", "evicted", n)
			}
		}
	}()
	s.httpSrv = &http.Server{
		Addr:              fmt.Sprintf("127.0.0.1:%d", s.cfg.Port),
		Handler:           s.Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       120 * time.Second,
		// ReadTimeout/WriteTimeout 保持 0:600 秒 prompt 与 SSE 由路由级 context 控制
	}
	return s.httpSrv.ListenAndServe()
}

// ---- 路由 ----

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	agents := make([]map[string]any, 0, len(s.reg))
	for _, d := range s.reg {
		entry := map[string]any{"name": d.Name, "ready": false, "err": nil}
		if d.Kind == backend.KindNative {
			if err := backend.PiReady(d.Argv); err != nil {
				entry["err"] = err.Error()
			} else {
				entry["ready"] = true
			}
		} else if _, err := d.Resolve(); err != nil {
			entry["err"] = err.Error()
		} else {
			entry["ready"] = true
		}
		agents = append(agents, entry)
	}
	jsonWrite(w, 200, map[string]any{"ok": true, "acpsup": version(), "build": os.Getenv("ACPSUP_BUILD"), "agents": agents})
}

func (s *Server) spawn(def backend.Def, env []string, cwd string) (*acpclient.Agent, error) {
	if s.cfg.SpawnFunc != nil {
		return s.cfg.SpawnFunc(def, env, cwd)
	}
	argv, err := def.Resolve()
	if err != nil {
		return nil, err
	}
	return acpclient.Spawn(def.Name, argv, env, cwd)
}

// codexHomeBase 是会话级 CODEX_HOME 的基目录(DataDir/codex);重启即旧账兜底清空。
func (s *Server) codexHomeBase() string { return filepath.Join(s.cfg.DataDir, "codex") }

// codexHomeWithModel 生成会话级 CODEX_HOME:烤库 config 改 model 行(四模型面)。
// 目录归 DataDir/codex(会话 Close 自回收;旧版落系统 /tmp 每会话 ~110M 不回收,已根修);
// catalog 用绝对路径不受影响。
func (s *Server) codexHomeWithModel(model string) (string, error) {
	base, err := os.ReadFile("/root/.codex/config.toml")
	if err != nil {
		return "", err
	}
	replaced := modelLineRe.ReplaceAll(base, []byte("model = \""+model+"\""))
	home, err := os.MkdirTemp(s.codexHomeBase(), "codex-*")
	if err != nil {
		return "", err
	}
	if err := os.WriteFile(filepath.Join(home, "config.toml"), replaced, 0o600); err != nil {
		return "", err
	}
	return home, nil
}

func (s *Server) handleSessionNew(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Agent string `json:"agent"`
		Cwd   string `json:"cwd"`
		Model string `json:"model"`
	}
	if !readBody(w, r, &body) {
		return
	}
	def, ok := backend.Find(body.Agent)
	if !ok {
		jsonWrite(w, 400, map[string]any{"error": "未知 agent:" + body.Agent})
		return
	}
	cwd := body.Cwd
	if !strings.HasPrefix(cwd, "/") {
		cwd = "/tmp"
	}
	// cwd 语义(hx-web 桥面对齐):调用方传容器内绝对路径;不存在的目录在白名单前缀下
	// 自动建(ACPSUP_CWD_ALLOW 逗号分隔,默认 /tmp,/srv/work),之外报 400
	if fi, err := os.Stat(cwd); err == nil && fi.IsDir() {
		// 存在且是目录,直接用
	} else if err := mkdirAllowlisted(cwd); err != nil {
		jsonWrite(w, 400, map[string]any{"error": err.Error()})
		return
	}
	// 四模型面(2026-10-13):可选 model 指定网关别名,叠加道见 spawnModelEnv;未给用烤库默认
	env, err := s.spawnModelEnv(def, body.Model)
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": "模型面生成失败:" + err.Error()})
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), handshakeTO)
	defer cancel()

	ag, err := s.spawn(def, env, cwd)
	if err != nil {
		jsonWrite(w, 400, map[string]any{"error": "agent 未就绪:" + err.Error()})
		return
	}
	caps := map[string]any{
		"fs":       map[string]any{"readTextFile": def.FS, "writeTextFile": def.FS},
		"terminal": def.Terminal,
	}
	initRes, err := ag.Request(ctx, "initialize", map[string]any{"protocolVersion": 1, "clientCapabilities": caps})
	if err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	snRes, err := ag.Request(ctx, "session/new", map[string]any{"cwd": cwd, "mcpServers": []any{}})
	if err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	var sn struct {
		SessionID     string          `json:"sessionId"`
		ConfigOptions json.RawMessage `json:"configOptions"`
	}
	if err := json.Unmarshal(snRes, &sn); err != nil || sn.SessionID == "" {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": "适配器未回 sessionId"})
		return
	}
	key, _ := r.Context().Value(keyCtx).(Key)
	sess := session.NewSession(sn.SessionID, def.Name, cwd, key.ID, ag)
	sess.Model = body.Model
	sess.Home = codexHomeFromEnv(env)
	if err := s.table.Add(sess); err != nil {
		sess.Close()
		jsonWrite(w, 429, map[string]any{"error": "session_limited"})
		return
	}
	s.wire(sess)
	if s.log != nil {
		s.log.Info("session_new", "cat", "audit", "action", "session/new",
			"key_id", key.ID, "session_id", sess.ID, "agent", def.Name, "cwd", clipStr(cwd, 256))
	}
	jsonWrite(w, 200, map[string]any{"sessionId": sess.ID, "agent": def.Name, "model": body.Model,
		"initialize": json.RawMessage(initRes), "configOptions": sn.ConfigOptions})
}

// wire 装配一个会话的回调:事件入环、fs/terminal 真实现、权限桥 120 秒。
func (s *Server) wire(sess *session.Session) {
	ag := sess.Adapter()
	ag.StderrOut = s.stderrTap()
	ag.OnUpdate = func(params json.RawMessage) {
		var p struct {
			SessionID string          `json:"sessionId"`
			Update    json.RawMessage `json:"update"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			if s.log != nil {
				s.log.Warn("update_unmarshal_fail", "cat", "audit", "session_id", sess.ID, "err", err.Error())
			}
			return
		}
		if p.SessionID == sess.AcpSessionID() {
			sess.Broadcast(session.Envelope{Kind: "session/update", Update: p.Update})
		} else if s.log != nil {
			s.log.Warn("update_mismatch", "cat", "audit", "session_id", sess.ID,
				"acp_id", sess.AcpSessionID(), "got", p.SessionID)
		}
	}
	ag.OnServerRequest = func(method string, params json.RawMessage, respond func(any), respondErr func(int, string)) {
		s.serverRequest(sess, method, params, respond, respondErr)
	}
}

func (s *Server) stderrTap() io.Writer { return nil } // 调试级别接日志面;M1 保持 stderr 尾环即可

func (s *Server) serverRequest(sess *session.Session, method string, params json.RawMessage, respond func(any), respondErr func(int, string)) {
	defer func() {
		if e := recover(); e != nil {
			respondErr(-32000, fmt.Sprint(e))
		}
	}()
	switch method {
	case "fs/read_text_file":
		var p fsimpl.ReadParams
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if out, err := fsimpl.ReadTextFileBounded(p); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(out)
		}
	case "fs/write_text_file":
		var p fsimpl.WriteParams
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if err := fsimpl.WriteTextFileBounded(p); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(map[string]any{})
		}
	case "terminal/create":
		var p fsimpl.CreateParams
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if id, err := s.terms.Create(p); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(map[string]any{"terminalId": id})
		}
	case "terminal/output":
		var p struct {
			TerminalID string `json:"terminalId"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if out, err := s.terms.Output(p.TerminalID); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(map[string]any{"output": out})
		}
	case "terminal/wait_for_exit":
		var p struct {
			TerminalID string `json:"terminalId"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		go func() {
			if code, err := s.terms.WaitForExit(p.TerminalID); err != nil {
				respondErr(-32000, err.Error())
			} else {
				respond(map[string]any{"exitCode": code})
			}
		}()
	case "terminal/kill":
		var p struct {
			TerminalID string `json:"terminalId"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if err := s.terms.Kill(p.TerminalID); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(map[string]any{})
		}
	case "terminal/release":
		var p struct {
			TerminalID string `json:"terminalId"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			respondErr(-32000, err.Error())
			return
		}
		if err := s.terms.Release(p.TerminalID); err != nil {
			respondErr(-32000, err.Error())
		} else {
			respond(map[string]any{})
		}
	case "session/request_permission":
		slot, reqID := sess.NewSlot()
		s.permIdxMu.Lock()
		s.permIdx[reqID] = slot
		s.permIdxMu.Unlock()
		sess.Broadcast(session.Envelope{Kind: "permission", RequestID: reqID, Request: params})
		if s.log != nil {
			s.log.Info("permission", "cat", "audit", "action", "permission_request",
				"session_id", sess.ID, "request_id", reqID)
		}
		go func() {
			out := slot.Wait(context.Background())
			respond(json.RawMessage(out))
			s.permIdxMu.Lock()
			delete(s.permIdx, reqID)
			s.permIdxMu.Unlock()
			if s.log != nil {
				s.log.Info("permission", "cat", "audit", "action", "permission_resolved",
					"session_id", sess.ID, "request_id", reqID, "outcome", clipStr(string(out), 64))
			}
		}()
	default:
		respondErr(-32601, "acpsup 未实现 "+method)
	}
}

// cwdAllowRoots 是 cwd 自动建的白名单前缀(环境变量覆盖,逗号分隔)。
func cwdAllowRoots() []string {
	v := os.Getenv("ACPSUP_CWD_ALLOW")
	if v == "" {
		return []string{"/srv/work/"} // R5 收紧:去 /tmp 调试遗留(共识 hx-arch,与 fleet#91 /srv/work/<agent> 对齐)
	}
	var out []string
	for _, p := range strings.Split(v, ",") {
		p = strings.TrimSpace(p)
		if p != "" {
			if !strings.HasSuffix(p, "/") {
				p += "/"
			}
			out = append(out, p)
		}
	}
	return out
}

// mkdirAllowlisted 在白名单前缀下建目录(含父目录);之外返回可读错误。
func mkdirAllowlisted(cwd string) error {
	for _, root := range cwdAllowRoots() {
		if !strings.HasPrefix(cwd, root) {
			continue
		}
		// R5/kimi:前缀匹配后 EvalSymlinks 防逃逸——/srv/work/<agent>/ln -> / 会绕过前缀判定
		if resolved, err := filepath.EvalSymlinks(cwd); err == nil && !strings.HasPrefix(resolved+"/", root) {
			return fmt.Errorf("cwd 解析出白名单(%s -> %s):%s", cwd, resolved, root)
		}
		if err := os.MkdirAll(cwd, 0o755); err != nil {
			return fmt.Errorf("cwd 建不了(%s):%v", cwd, err)
		}
		return nil
	}
	return fmt.Errorf("cwd 无效(需存在的绝对路径目录,或在自动建白名单 %v 下):%s", cwdAllowRoots(), cwd)
}

// handleSessionResume 续会话(契约③,pi-rs-agent 仓 5bfe832):spawn 后 initialize →
// session/resume {sessionId, cwd, mcpServers: []};cwd 由调用方给(须等会话记录的 cwd,
// 后端 fail-closed 校验);后端不支持的请求原样 502 透传错误面。
func (s *Server) handleSessionResume(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Agent     string `json:"agent"`
		SessionID string `json:"sessionId"`
		Cwd       string `json:"cwd"`
		Model     string `json:"model"`
	}
	if !readBody(w, r, &body) {
		return
	}
	if body.SessionID == "" {
		jsonWrite(w, 400, map[string]any{"error": "sessionId 必填"})
		return
	}
	if s.table.Get(body.SessionID) != nil {
		jsonWrite(w, 409, map[string]any{"error": "session_exists(该 id 已在表,复用即可)"})
		return
	}
	def, ok := backend.Find(body.Agent)
	if !ok {
		jsonWrite(w, 400, map[string]any{"error": "未知 agent:" + body.Agent})
		return
	}
	cwd := body.Cwd
	if !strings.HasPrefix(cwd, "/") {
		jsonWrite(w, 400, map[string]any{"error": "resume 需绝对 cwd(须等会话记录的 cwd)"})
		return
	}
	if fi, err := os.Stat(cwd); err == nil && fi.IsDir() {
	} else if err := mkdirAllowlisted(cwd); err != nil {
		jsonWrite(w, 400, map[string]any{"error": err.Error()})
		return
	}
	env, err := s.spawnModelEnv(def, body.Model)
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": err.Error()})
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), handshakeTO)
	defer cancel()
	ag, err := s.spawn(def, env, cwd)
	if err != nil {
		jsonWrite(w, 400, map[string]any{"error": "agent 未就绪:" + err.Error()})
		return
	}
	caps := map[string]any{
		"fs":       map[string]any{"readTextFile": def.FS, "writeTextFile": def.FS},
		"terminal": def.Terminal,
	}
	if _, err := ag.Request(ctx, "initialize", map[string]any{"protocolVersion": 1, "clientCapabilities": caps}); err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	if _, err := ag.Request(ctx, "session/resume", map[string]any{
		"sessionId": body.SessionID, "cwd": cwd, "mcpServers": []any{},
	}); err != nil {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": "resume 失败(未知 id 或 cwd 错配):" + err.Error(), "adapterStderr": ag.StderrTail()})
		return
	}
	key, _ := r.Context().Value(keyCtx).(Key)
	sess := session.NewSession(body.SessionID, def.Name, cwd, key.ID, ag)
	sess.Model = body.Model
	sess.Home = codexHomeFromEnv(env)
	if err := s.table.Add(sess); err != nil {
		sess.Close()
		jsonWrite(w, 429, map[string]any{"error": "session_limited"})
		return
	}
	s.wire(sess)
	if s.log != nil {
		s.log.Info("session_resume", "cat", "audit", "action", "session/resume",
			"key_id", key.ID, "session_id", sess.ID, "agent", def.Name, "cwd", clipStr(cwd, 256))
	}
	jsonWrite(w, 200, map[string]any{"sessionId": sess.ID, "agent": def.Name, "model": body.Model, "resumed": true})
}

// handleFile 是文件承接面:取该会话 cwd 子树内的一个文件(桥/平台读不到容器 FS 的补面)。
// 安全边界:会话必须在表(空闲逐出后失效)、路径绝对且 Clean 后仍在该会话 cwd 子树内、4MiB 封顶。
func (s *Server) handleFile(w http.ResponseWriter, r *http.Request) {
	sid := r.URL.Query().Get("sessionId")
	path := r.URL.Query().Get("path")
	sess := s.table.Get(sid)
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话(空闲逐出或不存在)"})
		return
	}
	if !filepath.IsAbs(path) {
		jsonWrite(w, 400, map[string]any{"error": "path 需绝对路径"})
		return
	}
	clean := filepath.Clean(path)
	rel, err := filepath.Rel(sess.Cwd, clean)
	if err != nil || rel == ".." || strings.HasPrefix(rel, "../") {
		jsonWrite(w, 403, map[string]any{"error": "path 越出会话 cwd 子树"})
		return
	}
	content, err := fsimpl.ReadTextFileBounded(fsimpl.ReadParams{Path: clean})
	if err != nil {
		jsonWrite(w, 404, map[string]any{"error": err.Error()})
		return
	}
	if s.log != nil {
		s.log.Info("file_read", "cat", "audit", "action", "file/read",
			"session_id", sess.ID, "path", clipStr(clean, 256), "bytes", len(content))
	}
	jsonWrite(w, 200, map[string]any{"path": clean, "content": content})
}

func (s *Server) handlePrompt(w http.ResponseWriter, r *http.Request) {
	var body struct {
		SessionID string `json:"sessionId"`
		Text      string `json:"text"`
	}
	if !readBody(w, r, &body) {
		return
	}
	sess := s.table.Get(body.SessionID)
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	release, ok := sess.TryPrompt()
	if !ok {
		jsonWrite(w, 409, map[string]any{"error": "prompt_in_flight"})
		return
	}
	defer release()
	sess.MarkPrompted()
	if s.log != nil {
		s.log.Info("prompt", "cat", "audit", "action", "session/prompt",
			"session_id", sess.ID, "agent", sess.Agent, "prompt_bytes", len(body.Text))
	}
	ctx, cancel := context.WithTimeout(context.Background(), promptTimeout)
	defer cancel()
	res, err := sess.Adapter().Request(ctx, "session/prompt", map[string]any{
		"sessionId": sess.AcpSessionID(),
		"prompt":    []any{map[string]any{"type": "text", "text": body.Text}},
	})
	if err != nil {
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": sess.Adapter().StderrTail()})
		return
	}
	jsonWrite(w, 200, map[string]any{"stopReason": json.RawMessage(res)})
}

func (s *Server) handleCancel(w http.ResponseWriter, r *http.Request) {
	var body struct {
		SessionID string `json:"sessionId"`
	}
	if !readBody(w, r, &body) {
		return
	}
	sess := s.table.Get(body.SessionID)
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	sess.Adapter().Notify("session/cancel", map[string]any{"sessionId": sess.AcpSessionID()})
	if s.log != nil {
		s.log.Info("session_cancel", "cat", "audit", "action", "session/cancel", "session_id", sess.ID)
	}
	jsonWrite(w, 200, map[string]any{"ok": true})
}

func (s *Server) handleEvents(w http.ResponseWriter, r *http.Request) {
	sess := s.table.Get(r.URL.Query().Get("sessionId"))
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	after := uint64(0)
	if v := r.Header.Get("Last-Event-ID"); v != "" {
		after, _ = strconv.ParseUint(v, 10, 64)
	}
	if v := r.URL.Query().Get("after"); v != "" {
		after, _ = strconv.ParseUint(v, 10, 64)
	}
	fl, ok := w.(http.Flusher)
	if !ok {
		jsonWrite(w, 500, map[string]any{"error": "streaming 不可用"})
		return
	}
	w.Header().Set("Content-Type", "text/event-stream")
	w.WriteHeader(200)

	evs, gap := sess.Replay(after)
	for _, ev := range evs {
		writeSSE(w, ev)
	}
	fl.Flush()
	if s.log != nil && gap {
		s.log.Warn("events", "cat", "access", "session_id", sess.ID, "replay", "gap")
	}
	ch, unsub := sess.Subscribe()
	defer unsub()
	heartbeat := time.NewTicker(sseHeartbeat)
	defer heartbeat.Stop()
	for {
		select {
		case ev := <-ch:
			writeSSE(w, ev)
			fl.Flush()
		case <-heartbeat.C:
			_, _ = io.WriteString(w, ": ping\n\n")
			fl.Flush()
		case <-sess.Done():
			return
		case <-r.Context().Done():
			return
		}
	}
}

func writeSSE(w io.Writer, ev session.Event) {
	b, _ := json.Marshal(ev.Data)
	if ev.ID > 0 {
		_, _ = fmt.Fprintf(w, "id: %d\ndata: %s\n\n", ev.ID, b)
	} else {
		_, _ = fmt.Fprintf(w, "data: %s\n\n", b)
	}
}

func (s *Server) handlePermission(w http.ResponseWriter, r *http.Request) {
	var body struct {
		RequestID string `json:"requestId"`
		OptionID  string `json:"optionId"`
	}
	if !readBody(w, r, &body) {
		return
	}
	s.permIdxMu.Lock()
	slot := s.permIdx[body.RequestID]
	delete(s.permIdx, body.RequestID)
	s.permIdxMu.Unlock()
	if slot == nil {
		jsonWrite(w, 404, map[string]any{"error": "无待决权限请求"})
		return
	}
	if slot.Reply(body.OptionID) {
		jsonWrite(w, 200, map[string]any{"ok": true})
	} else {
		jsonWrite(w, 404, map[string]any{"error": "权限请求已失效"})
	}
}

func (s *Server) handleShutdown(w http.ResponseWriter, r *http.Request) {
	if s.log != nil {
		s.log.Info("shutdown", "cat", "audit", "action", "shutdown")
	}
	jsonWrite(w, 200, map[string]any{"ok": true})
	go func() {
		time.Sleep(50 * time.Millisecond)
		if s.httpSrv != nil {
			_ = s.httpSrv.Close()
		}
		os.Exit(0)
	}()
}

// ---- 密钥管理面 ----

func (s *Server) handleKeyCreate(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Label string `json:"label"`
		Role  Role   `json:"role"`
	}
	if !readBody(w, r, &body) {
		return
	}
	if body.Role == "" {
		body.Role = RoleCaller
	}
	if body.Role != RoleAdmin && body.Role != RoleCaller {
		jsonWrite(w, 400, map[string]any{"error": "role 非法"})
		return
	}
	tok, hash, err := NewToken()
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": err.Error()})
		return
	}
	id, err := randomID()
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": err.Error()})
		return
	}
	s.keysMu.Lock()
	s.keys = append(s.keys, Key{ID: id, Hash: hash, Label: body.Label, Role: body.Role, Created: time.Now().UTC()})
	err = s.saveKeysLocked()
	s.keysMu.Unlock()
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": err.Error()})
		return
	}
	if s.log != nil {
		s.log.Info("key_create", "cat", "audit", "action", "key/create", "key_id", id, "role", body.Role)
	}
	jsonWrite(w, 200, map[string]any{"id": id, "token": tok})
}

func (s *Server) handleKeyList(w http.ResponseWriter, r *http.Request) {
	s.keysMu.Lock()
	defer s.keysMu.Unlock()
	out := make([]map[string]any, 0, len(s.keys))
	for _, k := range s.keys {
		out = append(out, map[string]any{"id": k.ID, "label": k.Label, "role": k.Role, "disabled": k.Disabled, "created": k.Created})
	}
	jsonWrite(w, 200, map[string]any{"keys": out})
}

func (s *Server) handleKeyRevoke(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	s.keysMu.Lock()
	found := false
	for i := range s.keys {
		if s.keys[i].ID == id {
			s.keys[i].Disabled = true
			found = true
		}
	}
	var err error
	if found {
		err = s.saveKeysLocked()
	}
	s.keysMu.Unlock()
	if !found {
		jsonWrite(w, 404, map[string]any{"error": "无此密钥"})
		return
	}
	if err != nil {
		jsonWrite(w, 500, map[string]any{"error": err.Error()})
		return
	}
	if s.log != nil {
		s.log.Info("key_revoke", "cat", "audit", "action", "key/revoke", "key_id", id)
	}
	jsonWrite(w, 200, map[string]any{"ok": true})
}

// ---- 杂项 ----

func readBody(w http.ResponseWriter, r *http.Request, v any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, bodyMax)
	b, err := io.ReadAll(r.Body)
	if err != nil {
		jsonWrite(w, 413, map[string]any{"error": "请求体过大或读失败"})
		return false
	}
	if len(b) == 0 {
		return true
	}
	if err := json.Unmarshal(b, v); err != nil {
		jsonWrite(w, 400, map[string]any{"error": "请求体不是合法 JSON"})
		return false
	}
	return true
}

func clipStr(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

func version() string { return "0.2.0" }

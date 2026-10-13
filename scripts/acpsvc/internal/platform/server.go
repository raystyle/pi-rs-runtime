// Package platform 的 HTTP 面:平台端点、Bearer 多密钥、限流、SSE。
// 与 TS 版端点/JSON 形状兼容;新增:id 断点重放、角色 403、429/409 语义(S-0003 第 4、5 节)。
package platform

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
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
	permIdx   map[string]*session.Slot // 权限槽全局簿(requestId -> 槽)

	httpSrv *http.Server
}

// New 装配服务;会话上限取建议默认(全局 8、每密钥 4)。
func New(cfg Config) *Server {
	if cfg.DataDir == "" {
		cfg.DataDir = "/var/lib/acpsup"
	}
	perKeyMax := 4
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
	return &Server{
		cfg:      cfg,
		log:      cfg.Log,
		table:    session.NewTable(globalMax, perKeyMax),
		terms:    fsimpl.NewTerminals(),
		reg:      backend.Registry(),
		limiters: make(map[string]*rate.Limiter),
		permIdx:  make(map[string]*session.Slot),
	}
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
	mux.HandleFunc("GET /events", s.auth(s.handleEvents, false, false))
	mux.HandleFunc("POST /permission", s.auth(s.handlePermission, false, true))
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
	jsonWrite(w, 200, map[string]any{"ok": true, "acpsup": version(), "agents": agents})
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

// codexHomeWithModel 生成会话级 CODEX_HOME:烤库 config 改 model 行(四模型面)。
// 目录留在系统临时目录,随实例生命周期;catalog 用绝对路径不受影响。
func codexHomeWithModel(model string) (string, error) {
	base, err := os.ReadFile("/root/.codex/config.toml")
	if err != nil {
		return "", err
	}
	replaced := modelLineRe.ReplaceAll(base, []byte("model = \""+model+"\""))
	home, err := os.MkdirTemp("", "acpsup-codex-*")
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
	// 四模型面(2026-10-13):可选 model 指定网关别名;claude 注 ANTHROPIC_MODEL,
	// codex 生成会话级 CODEX_HOME;未给用烤库默认
	env := append([]string(nil), def.Env...)
	if body.Model != "" {
		switch def.Name {
		case "claude":
			env = append(env, "ANTHROPIC_MODEL="+body.Model)
		case "codex":
			home, err := codexHomeWithModel(body.Model)
			if err != nil {
				jsonWrite(w, 500, map[string]any{"error": "codex 模型面生成失败:" + err.Error()})
				return
			}
			env = append(env, "CODEX_HOME="+home)
		}
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
		SessionID string `json:"sessionId"`
	}
	if err := json.Unmarshal(snRes, &sn); err != nil || sn.SessionID == "" {
		ag.Close()
		jsonWrite(w, 502, map[string]any{"error": "适配器未回 sessionId"})
		return
	}
	key, _ := r.Context().Value(keyCtx).(Key)
	sess := session.NewSession(sn.SessionID, def.Name, cwd, key.ID, ag)
	if err := s.table.Add(sess); err != nil {
		ag.Close()
		jsonWrite(w, 429, map[string]any{"error": "session_limited"})
		return
	}
	s.wire(sess)
	if s.log != nil {
		s.log.Info("session_new", "cat", "audit", "action", "session/new",
			"key_id", key.ID, "session_id", sess.ID, "agent", def.Name, "cwd", clipStr(cwd, 256))
	}
	jsonWrite(w, 200, map[string]any{"sessionId": sess.ID, "agent": def.Name, "model": body.Model, "initialize": json.RawMessage(initRes)})
}

// wire 装配一个会话的回调:事件入环、fs/terminal 真实现、权限桥 120 秒。
func (s *Server) wire(sess *session.Session) {
	ag := sess.Ag
	ag.StderrOut = s.stderrTap()
	ag.OnUpdate = func(params json.RawMessage) {
		var p struct {
			SessionID string          `json:"sessionId"`
			Update    json.RawMessage `json:"update"`
		}
		if err := json.Unmarshal(params, &p); err != nil {
			return
		}
		if p.SessionID == sess.ID {
			sess.Broadcast(session.Envelope{Kind: "session/update", Update: p.Update})
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
	if s.log != nil {
		s.log.Info("prompt", "cat", "audit", "action", "session/prompt",
			"session_id", sess.ID, "agent", sess.Agent, "prompt_bytes", len(body.Text))
	}
	ctx, cancel := context.WithTimeout(context.Background(), promptTimeout)
	defer cancel()
	res, err := sess.Ag.Request(ctx, "session/prompt", map[string]any{
		"sessionId": sess.ID,
		"prompt":    []any{map[string]any{"type": "text", "text": body.Text}},
	})
	if err != nil {
		jsonWrite(w, 502, map[string]any{"error": err.Error(), "adapterStderr": sess.Ag.StderrTail()})
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
	sess.Ag.Notify("session/cancel", map[string]any{"sessionId": sess.ID})
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

func version() string { return "0.1.0" }

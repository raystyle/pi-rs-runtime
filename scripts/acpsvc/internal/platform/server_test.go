package platform

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/acpclient"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/backend"
)

// fakeAdapter:initialize/session/new 应答;prompt 前先推一条 update 通知。
const fakeAdapter = `#!/bin/sh
while IFS= read -r line; do
  id=$(printf '%s' "$line" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')
  case "$line" in
    *'"initialize"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"protocolVersion":1}}\n' "$id" ;;
    *'"session/new"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"sessionId":"fake-sess"}}\n' "$id" ;;
    *'"session/prompt"'*)
      printf '{"jsonrpc":"2.0","method":"session/update","params":{"sessionId":"fake-sess","update":{"sessionUpdate":"agent_message_chunk"}}}\n'
      printf '{"jsonrpc":"2.0","id":%s,"result":{"stopReason":{"stopReason":"end_turn"}}}\n' "$id" ;;
    *'"session/resume"'*)
      case "$line" in *"resume-sid-ok"*) printf '{"jsonrpc":"2.0","id":%s,"result":{}}\n' "$id" ;; *) printf '{"jsonrpc":"2.0","id":%s,"error":{"code":-32000,"message":"unknown session"}}\n' "$id" ;; esac ;;
  esac
done
`

func newTestServer(t *testing.T) (*Server, string) {
	t.Helper()
	dir := t.TempDir()
	script := filepath.Join(dir, "fake.sh")
	if err := os.WriteFile(script, []byte(fakeAdapter), 0o755); err != nil {
		t.Fatal(err)
	}
	// 预置一把 legacy 管理令牌与一把 caller 密钥
	token := "test-admin-token"
	if err := os.MkdirAll(filepath.Join(dir, "data"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "data", "token"), []byte(token+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	callerTok := "acp_caller_test"
	s := New(Config{
		DataDir: filepath.Join(dir, "data"),
		SpawnFunc: func(def backend.Def, env []string, cwd string) (*acpclient.Agent, error) {
			return acpclient.Spawn(def.Name, []string{script}, env, cwd)
		},
	})
	if err := s.EnsureKeys(); err != nil {
		t.Fatalf("keys: %v", err)
	}
	// 追加 caller 密钥(直接写文件态,避免打印)
	s.keysMu.Lock()
	s.keys = append(s.keys, Key{ID: "k_caller", Hash: HashToken(callerTok), Label: "t", Role: RoleCaller, Created: time.Now().UTC()})
	_ = s.saveKeysLocked()
	s.keysMu.Unlock()
	return s, token
}

func doJSON(t *testing.T, h http.Handler, method, path, token string, body any) (*http.Response, []byte) {
	t.Helper()
	var r io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		r = bytes.NewReader(b)
	}
	req := httptest.NewRequest(method, path, r)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec.Result(), rec.Body.Bytes()
}

func TestHealthAuth(t *testing.T) {
	s, tok := newTestServer(t)
	h := s.Handler()
	resp, _ := doJSON(t, h, "GET", "/health", "", nil)
	if resp.StatusCode != 401 {
		t.Fatalf("无 token = %d, want 401", resp.StatusCode)
	}
	resp, body := doJSON(t, h, "GET", "/health", tok, nil)
	if resp.StatusCode != 200 || !strings.Contains(string(body), `"claude"`) {
		t.Fatalf("health = %d %s", resp.StatusCode, body)
	}
}

func TestSessionPromptEvents(t *testing.T) {
	s, tok := newTestServer(t)
	h := s.Handler()
	resp, body := doJSON(t, h, "POST", "/session/new", tok, map[string]any{"agent": "claude", "cwd": "/tmp"})
	if resp.StatusCode != 200 || !strings.Contains(string(body), "fake-sess") {
		t.Fatalf("session/new = %d %s", resp.StatusCode, body)
	}
	resp, body = doJSON(t, h, "POST", "/session/prompt", tok, map[string]any{"sessionId": "fake-sess", "text": "只回复 ok"})
	if resp.StatusCode != 200 || !strings.Contains(string(body), "end_turn") {
		t.Fatalf("prompt = %d %s", resp.StatusCode, body)
	}
	// SSE 回放带 id;after=1 只剩后续。
	// 处理器在订阅环里长驻,用可取消 ctx 驱动返回(修挂死:httptest 默认 ctx 永不完成)
	sseGet := func(after string) string {
		ctx, cancel := context.WithCancel(context.Background())
		req := httptest.NewRequest("GET", "/events?sessionId=fake-sess&after="+after, nil).WithContext(ctx)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		done := make(chan struct{})
		go func() { h.ServeHTTP(rec, req); close(done) }()
		time.Sleep(400 * time.Millisecond) // 回放+订阅跑完
		cancel()
		<-done
		return rec.Body.String()
	}
	if body := sseGet("0"); !strings.Contains(body, "id: 1") || !strings.Contains(body, "agent_message_chunk") {
		t.Fatalf("events 回放缺 id/update: %q", body)
	}
	if body := sseGet("1"); strings.Contains(body, "agent_message_chunk") {
		t.Fatalf("after=1 不应再回放首条: %q", body)
	}
}

func TestRolesAndKeys(t *testing.T) {
	s, tok := newTestServer(t)
	h := s.Handler()
	caller := "acp_caller_test"
	// caller 调管理面 403
	resp, _ := doJSON(t, h, "POST", "/shutdown", caller, nil)
	if resp.StatusCode != 403 {
		t.Fatalf("caller shutdown = %d, want 403", resp.StatusCode)
	}
	// admin 造一把 caller 密钥
	resp, body := doJSON(t, h, "POST", "/keys", tok, map[string]any{"label": "x", "role": "caller"})
	if resp.StatusCode != 200 || !strings.Contains(string(body), "acp_") {
		t.Fatalf("keys = %d %s", resp.StatusCode, body)
	}
	// 新 caller 可调业务面
	resp, _ = doJSON(t, h, "GET", "/health", extractToken(t, body), nil)
	if resp.StatusCode != 200 {
		t.Fatalf("新 caller health = %d", resp.StatusCode)
	}
}

func extractToken(t *testing.T, body []byte) string {
	t.Helper()
	var out struct {
		Token string `json:"token"`
	}
	if err := json.Unmarshal(body, &out); err != nil || out.Token == "" {
		t.Fatalf("token 抽取失败: %s", body)
	}
	return out.Token
}

func TestRateLimit(t *testing.T) {
	s, tok := newTestServer(t)
	// 确定性道:先直接耗尽该密钥的桶(不依赖调用速度),再走 HTTP 断言 429
	l := s.limiter("legacy")
	for i := 0; i < shortRouteBurst; i++ {
		if !l.Allow() {
			t.Fatalf("桶内第 %d 次应放行", i+1)
		}
	}
	if l.Allow() {
		t.Fatal("超桶应拒")
	}
	resp, _ := doJSON(t, s.Handler(), "GET", "/health", tok, nil)
	if resp.StatusCode != 429 {
		t.Fatalf("桶尽后 health = %d, want 429", resp.StatusCode)
	}
}

func TestPromptInFlight409(t *testing.T) {
	s, tok := newTestServer(t)
	h := s.Handler()
	_, _ = doJSON(t, h, "POST", "/session/new", tok, map[string]any{"agent": "claude"})
	// 先手动占住 prompt 位,再打 prompt 应 409
	sess := s.table.Get("fake-sess")
	if sess == nil {
		t.Fatal("会话缺席")
	}
	rel, ok := sess.TryPrompt()
	if !ok {
		t.Fatal("占位失败")
	}
	resp, _ := doJSON(t, h, "POST", "/session/prompt", tok, map[string]any{"sessionId": "fake-sess", "text": "x"})
	if resp.StatusCode != 409 {
		t.Fatalf("并发 prompt = %d, want 409", resp.StatusCode)
	}
	rel()
}

func TestSessionResume(t *testing.T) {
	s, tok := newTestServer(t)
	h := s.Handler()
	// 未知 id:适配器 fail-closed,502 透传
	resp, body := doJSON(t, h, "POST", "/session/resume", tok, map[string]any{"agent": "claude", "sessionId": "nope", "cwd": "/tmp"})
	if resp.StatusCode != 502 || !strings.Contains(string(body), "resume 失败") {
		t.Fatalf("未知 id resume = %d %s, want 502", resp.StatusCode, body)
	}
	// 成功道:fake 只认 resume-sid-ok
	resp, body = doJSON(t, h, "POST", "/session/resume", tok, map[string]any{"agent": "claude", "sessionId": "resume-sid-ok", "cwd": "/tmp"})
	if resp.StatusCode != 200 || !strings.Contains(string(body), `"resumed":true`) {
		t.Fatalf("resume = %d %s", resp.StatusCode, body)
	}
	// 同 id 已在表:409 复用语义
	resp, _ = doJSON(t, h, "POST", "/session/resume", tok, map[string]any{"agent": "claude", "sessionId": "resume-sid-ok", "cwd": "/tmp"})
	if resp.StatusCode != 409 {
		t.Fatalf("重复 resume = %d, want 409", resp.StatusCode)
	}
}

func TestUnknownAgent400(t *testing.T) {
	s, tok := newTestServer(t)
	resp, _ := doJSON(t, s.Handler(), "POST", "/session/new", tok, map[string]any{"agent": "nope"})
	if resp.StatusCode != 400 {
		t.Fatalf("未知 agent = %d, want 400", resp.StatusCode)
	}
}

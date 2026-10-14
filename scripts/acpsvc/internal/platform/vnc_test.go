package platform

import (
	"context"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/session"
)

// writeBin 落一个可执行假件脚本。
func writeBin(t *testing.T, dir, name, body string) string {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.WriteFile(p, []byte("#!/bin/sh\n"+body), 0o755); err != nil {
		t.Fatal(err)
	}
	return p
}

const fakeChromeServer = `
port=""
for a in "$@"; do case "$a" in --remote-debugging-port=*) port="${a#*=}";; esac; done
exec python3 -c "
import http.server, json, sys
port=int(sys.argv[1])
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        b=json.dumps({'webSocketDebuggerUrl':'ws://127.0.0.1:%d/devtools/browser/fake'%port}).encode()
        self.send_response(200); self.send_header('Content-Length',str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self,*a): pass
http.server.HTTPServer(('127.0.0.1',port),H).serve_forever()
" "$port"
`

func vncTestServer(t *testing.T) (*Server, string, string) {
	t.Helper()
	s, admin := newTestServer(t)
	// 第二把 caller 键(跨键 404 用)
	s.keysMu.Lock()
	other := "acp_caller_other"
	s.keys = append(s.keys, Key{ID: "k_other", Hash: HashToken(other), Label: "t2", Role: RoleCaller, Created: time.Now().UTC()})
	_ = s.saveKeysLocked()
	s.keysMu.Unlock()
	return s, admin, other
}

func TestVNCNoSession404(t *testing.T) {
	s, tok, _ := vncTestServer(t)
	srv := httptest.NewServer(s.Handler())
	defer srv.Close()
	// 未知会话:404,不升级
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, _, err := websocket.Dial(ctx, srv.URL+"/vnc?sessionId=nope",
		&websocket.DialOptions{HTTPHeader: authHeader(tok)})
	if err == nil {
		t.Fatal("未知会话不应升级")
	}
	// 跨键:同 404 正文(不暴露他人会话存在)
	s.vnc.hookEnsure = func(*session.Session) (*vncStack, error) { t.Fatal("跨键不应 Ensure"); return nil, nil }
	_, _, err = websocket.Dial(ctx, srv.URL+"/vnc?sessionId=fake-sess1",
		&websocket.DialOptions{HTTPHeader: authHeader("acp_caller_other")})
	if err == nil {
		t.Fatal("跨键不应升级")
	}
	// 无 Bearer:401
	_, _, err = websocket.Dial(ctx, srv.URL+"/vnc?sessionId=fake-sess1", nil)
	if err == nil {
		t.Fatal("无鉴权不应升级")
	}
}

func authHeader(tok string) (h map[string][]string) {
	return map[string][]string{"Authorization": {"Bearer " + tok}}
}

// 桥回环:假 x11vnc(cat 回显)经 WS↔RFB 直通,字节一致;第二条 WS 替换第一条。
func TestVNCBridgeEcho(t *testing.T) {
	s, tok, _ := vncTestServer(t)
	sess := s.table.Get("fake-sess1")
	if sess == nil {
		// 建会话(fake-sess1 归 k_caller)
		resp, _ := doJSON(t, s.Handler(), "POST", "/session/new", "acp_caller_test", map[string]any{"agent": "claude", "cwd": "/tmp"})
		if resp.StatusCode != 200 {
			t.Fatalf("session/new = %d", resp.StatusCode)
		}
		sess = s.table.Get("fake-sess1")
	}
	fakeDir := t.TempDir()
	s.vnc.x11vncBin = writeBin(t, fakeDir, "fake-x11vnc", "exec cat")
	st := &vncStack{
		mgr: s.vnc, id: sess.ID, slot: 0, dir: fakeDir,
		display: vncDisplayBase, cdpPort: vncCdpBase,
		xvfbDone: make(chan struct{}), chromeDn: make(chan struct{}),
	}
	s.vnc.hookEnsure = func(*session.Session) (*vncStack, error) { return st, nil }

	srv := httptest.NewServer(s.Handler())
	defer srv.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	c, _, err := websocket.Dial(ctx, srv.URL+"/vnc?sessionId=fake-sess1",
		&websocket.DialOptions{HTTPHeader: authHeader(tok), Subprotocols: []string{"binary"}})
	if err != nil {
		t.Fatalf("升级失败: %v", err)
	}
	defer c.CloseNow()
	if c.Subprotocol() != "binary" {
		t.Fatalf("子协议 = %q", c.Subprotocol())
	}
	if err := c.Write(ctx, websocket.MessageBinary, []byte("RFB-ECHO")); err != nil {
		t.Fatal(err)
	}
	_, got, err := c.Read(ctx)
	if err != nil {
		t.Fatalf("读回显: %v", err)
	}
	if string(got) != "RFB-ECHO" {
		t.Fatalf("回环字节不符: %q", got)
	}
	// 子协议不带 binary:升级后即被策略关闭
	c2, _, err := websocket.Dial(ctx, srv.URL+"/vnc?sessionId=fake-sess1",
		&websocket.DialOptions{HTTPHeader: authHeader(tok)})
	if err == nil {
		if _, _, rerr := c2.Read(ctx); rerr == nil {
			t.Fatal("非 binary 子协议应被关闭")
		}
		c2.CloseNow()
	}
}

// Ensure 假栈全链:xauth→Xvfb→chrome(CDP 就绪)→cdp.ws;teardown 走自退链,
// 假 chrome 不回 CDP close 即标泄漏(槽不复用、目录保留)。
func TestVNCEnsureFakeStack(t *testing.T) {
	s, _, _ := vncTestServer(t)
	// 会话不存在也行:Ensure 只吃 ID/OnClose/Touch;造裸会话进表
	sess := session.NewSession("vnc-ensure-1", "claude", "/tmp", "k", nil)
	if err := s.table.Add(sess); err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	s.vnc.xauthBin = writeBin(t, dir, "fake-xauth", `while [ $# -gt 0 ]; do [ "$1" = "-f" ] && { shift; touch "$1"; exit 0; }; shift; done`)
	s.vnc.xvfbBin = writeBin(t, dir, "fake-xvfb", `d="${1#:}"
mkdir -p /tmp/.X11-unix
touch "/tmp/.X11-unix/X$d"
exec sleep 60`)
	t.Cleanup(func() {
		_ = os.Remove("/tmp/.X11-unix/X" + strconv.Itoa(vncDisplayBase))
		_ = exec.Command("pkill", "-f", filepath.Join(dir, "fake-chrome")).Run()
		_ = exec.Command("pkill", "-f", filepath.Join(dir, "fake-xvfb")).Run()
	})
	s.vnc.xdpyinfo = writeBin(t, dir, "fake-xdpyinfo", "exit 0")
	s.vnc.chromeBin = writeBin(t, dir, "fake-chrome", strings.TrimPrefix(fakeChromeServer, "\n"))
	s.vnc.extraIPv4s = func() []string { return nil }

	st, err := s.vnc.Ensure(sess)
	if err != nil {
		t.Fatalf("Ensure: %v", err)
	}
	ws, rerr := os.ReadFile(filepath.Join(st.dir, "cdp.ws"))
	if rerr != nil || !strings.Contains(string(ws), "/devtools/browser/") {
		t.Fatalf("cdp.ws 缺: %v %q", rerr, ws)
	}
	_, serr := os.Stat(xSocket(st.display))
	t.Logf("栈: slot=%d display=%d cdp=%d healthy=%v socketIn=%v", st.slot, st.display, st.cdpPort, st.healthy(), serr == nil)
	if _, herr := cdpVersion(st.cdpPort, 2*time.Second); herr != nil {
		t.Logf("cdp: %v", herr)
	}
	// 健检再取同栈
	st2, err := s.vnc.Ensure(sess)
	if err != nil || st2 != st {
		t.Fatalf("健康栈应复用: %v %p/%p", err, st2, st)
	}
	// 拆卸:假 chrome 收不到 Browser.close(WS URL 假)→ 泄漏语义
	st.teardown()
	s.vnc.mu.Lock()
	leaky := s.vnc.slots[st.slot] != nil && s.vnc.slots[st.slot].leaky
	s.vnc.mu.Unlock()
	if !leaky {
		t.Fatal("停不掉的栈应标泄漏")
	}
	if _, err := os.Stat(filepath.Join(st.dir, "chrome.log")); err != nil {
		t.Fatalf("泄漏栈目录应保留(日志取证): %v", err)
	}
	// 会话 Close 触发钩子(幂等,不再 panic)
	var closed atomic.Bool
	sess.OnClose(func() { closed.Store(true) })
	sess.Close()
	time.Sleep(300 * time.Millisecond)
	if !closed.Load() {
		t.Fatal("OnClose 钩子未执行")
	}
}

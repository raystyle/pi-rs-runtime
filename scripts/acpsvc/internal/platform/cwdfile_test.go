package platform

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"encoding/json"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/acpclient"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/backend"
	"net/http/httptest"
)

func TestMkdirAllowlisted(t *testing.T) {
	base := t.TempDir()
	t.Setenv("ACPSUP_CWD_ALLOW", base+"/w")
	p := filepath.Join(base, "w", "jobs", "20261013")
	if err := mkdirAllowlisted(p); err != nil {
		t.Fatalf("白名单内应可建: %v", err)
	}
	if fi, err := os.Stat(p); err != nil || !fi.IsDir() {
		t.Fatalf("目录未落: %v", err)
	}
	if err := mkdirAllowlisted(base + "/elsewhere/deep"); err == nil {
		t.Fatal("白名单外应拒")
	}
	if err := mkdirAllowlisted(base + "/w-escape"); err == nil {
		t.Fatal("前缀咬字(/w-escape 不是 /w/ 子树)应拒")
	}
}

// fakeAdaptorShell:最小 stdio 会话(建会话应答 sessionId=file-sess)。
const fileFake = `#!/bin/sh
while IFS= read -r line; do
  id=$(printf '%s' "$line" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')
  case "$line" in
    *'"initialize"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"protocolVersion":1}}\n' "$id" ;;
    *'"session/new"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"sessionId":"file-sess"}}\n' "$id" ;;
  esac
done
`

func TestFileFaceJailAndRead(t *testing.T) {
	dir := t.TempDir()
	script := filepath.Join(dir, "fake.sh")
	if err := os.WriteFile(script, []byte(fileFake), 0o755); err != nil {
		t.Fatal(err)
	}
	dataDir := filepath.Join(dir, "data")
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		t.Fatal(err)
	}
	tok := "file-face-test-token"
	if err := os.WriteFile(filepath.Join(dataDir, "token"), []byte(tok+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	s := New(Config{
		DataDir: dataDir,
		SpawnFunc: func(def backend.Def, env []string, cwd string) (*acpclient.Agent, error) {
			return acpclient.Spawn(def.Name, []string{script}, env, cwd)
		},
	})
	if err := s.EnsureKeys(); err != nil {
		t.Fatal(err)
	}
	if k, err := Check(s.keys, tok); err != nil || k.ID != "legacy" {
		t.Fatalf("Check 预检失败: keys=%+v err=%v", s.keys, err)
	}
	h := s.Handler()
	auth := "Bearer " + tok
	// 工作根建在白名单外不可,先手工建(测试进程可建任何处)
	work := filepath.Join(dir, "work")
	if err := os.MkdirAll(work, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(work, "a.txt"), []byte("hello"), 0o644); err != nil {
		t.Fatal(err)
	}
	// 建会话,cwd=work
	sid := func() string {
		req := httptest.NewRequest("POST", "/session/new", strings.NewReader(`{"agent":"claude","cwd":"`+work+`"}`))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", auth)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		var out struct {
			SessionID string `json:"sessionId"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil || out.SessionID == "" {
			t.Fatalf("session/new = %d %s", rec.Code, rec.Body.String())
		}
		return out.SessionID
	}()
	get := func(path string) int {
		req := httptest.NewRequest("GET", "/file?sessionId="+sid+"&path="+path, nil)
		req.Header.Set("Authorization", auth)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec.Code
	}
	if c := get(filepath.Join(work, "a.txt")); c != 200 {
		t.Fatalf("子树内读 = %d", c)
	}
	if c := get(filepath.Join(dir, "secret.txt")); c != 403 {
		t.Fatalf("越树应 403, got %d", c)
	}
	if c := get("relative.txt"); c != 400 {
		t.Fatalf("相对路径应 400, got %d", c)
	}
}

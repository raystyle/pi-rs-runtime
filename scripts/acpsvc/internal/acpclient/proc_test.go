package acpclient

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// fakeAdapter 回 id 匹配的应答;pingreq 触发一条服务端请求。
const fakeAdapter = `#!/bin/sh
while IFS= read -r line; do
  id=$(printf '%s' "$line" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')
  case "$line" in
    *'"initialize"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"protocolVersion":1}}\n' "$id" ;;
    *'"pingreq"'*)
      printf '{"jsonrpc":"2.0","id":"s1","method":"session/request_permission","params":{"options":[]}}\n'
      printf '{"jsonrpc":"2.0","id":%s,"result":{"ok":true}}\n' "$id" ;;
    *'"session/prompt"'*) printf '{"jsonrpc":"2.0","id":%s,"result":{"stopReason":"end_turn"}}\n' "$id" ;;
  esac
done
`

func writeFake(t *testing.T) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "fake-adapter.sh")
	if err := os.WriteFile(p, []byte(fakeAdapter), 0o755); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestSpawnRequestRoundtrip(t *testing.T) {
	ag, err := Spawn("fake", []string{writeFake(t)}, nil, "/tmp")
	if err != nil {
		t.Fatalf("spawn: %v", err)
	}
	defer ag.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	res, err := ag.Request(ctx, "initialize", map[string]any{"protocolVersion": 1})
	if err != nil {
		t.Fatalf("request: %v", err)
	}
	var init struct {
		ProtocolVersion int `json:"protocolVersion"`
	}
	if err := json.Unmarshal(res, &init); err != nil || init.ProtocolVersion != 1 {
		t.Fatalf("init = %s err=%v", res, err)
	}
}

func TestServerRequestDispatch(t *testing.T) {
	ag, err := Spawn("fake", []string{writeFake(t)}, nil, "/tmp")
	if err != nil {
		t.Fatalf("spawn: %v", err)
	}
	defer ag.Close()
	got := make(chan string, 1)
	ag.OnServerRequest = func(method string, params json.RawMessage, respond func(any), respondErr func(int, string)) {
		if method != "session/request_permission" {
			respondErr(-32601, "未实现")
			return
		}
		respond(map[string]any{"outcome": map[string]any{"outcome": "selected", "optionId": "allow_once"}})
		got <- method
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := ag.Request(ctx, "pingreq", map[string]any{}); err != nil {
		t.Fatalf("pingreq: %v", err)
	}
	select {
	case m := <-got:
		if m != "session/request_permission" {
			t.Fatalf("method = %s", m)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("服务端请求未到达")
	}
}

func TestRequestTimeout(t *testing.T) {
	script := "#!/bin/sh\nsleep 30\n"
	p := filepath.Join(t.TempDir(), "slow.sh")
	if err := os.WriteFile(p, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	ag, err := Spawn("slow", []string{p}, nil, "/tmp")
	if err != nil {
		t.Fatal(err)
	}
	defer ag.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	if _, err := ag.Request(ctx, "initialize", nil); err == nil {
		t.Fatal("应超时")
	}
}

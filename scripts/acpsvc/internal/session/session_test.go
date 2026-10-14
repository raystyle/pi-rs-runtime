package session

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func newSlotForTest() *Slot {
	return &Slot{done: make(chan struct{}), outcome: make(chan json.RawMessage, 1)}
}

func TestSlotReply(t *testing.T) {
	s := newSlotForTest()
	go func() {
		if !s.Reply("allow_once") {
			t.Error("首次应答应成功")
		}
	}()
	out := s.Wait(context.Background())
	if !strings.Contains(string(out), `"selected"`) || !strings.Contains(string(out), "allow_once") {
		t.Fatalf("out = %s", out)
	}
	if s.Reply("reject_once") {
		t.Fatal("二次应答应失败")
	}
}

func TestSlotTimeout(t *testing.T) {
	old := PermissionWait
	PermissionWait = 50 * time.Millisecond
	defer func() { PermissionWait = old }()
	s := newSlotForTest()
	out := s.Wait(context.Background())
	if !strings.Contains(string(out), `"cancelled"`) {
		t.Fatalf("out = %s", out)
	}
	if s.Reply("allow_once") {
		t.Fatal("超时后应答应失败")
	}
}

func TestTryPromptExclusive(t *testing.T) {
	s := NewSession("s1", "claude", "/tmp", "k", nil)
	rel, ok := s.TryPrompt()
	if !ok {
		t.Fatal("首抢应成功")
	}
	if _, ok2 := s.TryPrompt(); ok2 {
		t.Fatal("并发第二 prompt 应被拒")
	}
	rel()
	if _, ok3 := s.TryPrompt(); !ok3 {
		t.Fatal("释放后应可再抢")
	}
}

func TestTableLimits(t *testing.T) {
	tbl := NewTable(2, 1)
	mk := func(id, key string) *Session { return NewSession(id, "claude", "/tmp", key, nil) }
	if err := tbl.Add(mk("a", "k1")); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Add(mk("b", "k1")); err != ErrLimited {
		t.Fatalf("每密钥上限应触发, got %v", err)
	}
	if err := tbl.Add(mk("c", "k2")); err != nil {
		t.Fatal(err)
	}
	if err := tbl.Add(mk("d", "k3")); err != ErrLimited {
		t.Fatalf("全局上限应触发, got %v", err)
	}
}

func TestBroadcastSubscribeCarriesID(t *testing.T) {
	s := NewSession("s1", "claude", "/tmp", "k", nil)
	ch, unsub := s.Subscribe()
	defer unsub()
	id1 := s.Broadcast(Envelope{Kind: "session/update", Update: json.RawMessage(`{}`)})
	id2 := s.Broadcast(Envelope{Kind: "session/update", Update: json.RawMessage(`{}`)})
	ev := <-ch
	if ev.ID != id1 {
		t.Fatalf("订阅面首事件 id = %d, want %d", ev.ID, id1)
	}
	if id2 != id1+1 {
		t.Fatalf("id 应单调: %d -> %d", id1, id2)
	}
}

// Home 目录随 Close 回收(codex 会话级 CODEX_HOME 不再泄漏)。
func TestHomeCleanupOnClose(t *testing.T) {
	home := t.TempDir()
	sess := NewSession("s1", "codex", "/tmp", "k", nil)
	sess.Home = home
	marker := filepath.Join(home, "config.toml")
	if err := os.WriteFile(marker, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	sess.Close()
	deadline := time.Now().Add(2 * time.Second)
	for {
		if _, err := os.Stat(home); os.IsNotExist(err) {
			return
		}
		if time.Now().After(deadline) {
			t.Fatalf("Home 未被回收: %s", home)
		}
		time.Sleep(20 * time.Millisecond)
	}
}

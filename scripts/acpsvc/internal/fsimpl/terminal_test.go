package fsimpl

import (
	"strings"
	"testing"
)

func TestTerminalLifecycle(t *testing.T) {
	terms := NewTerminals()
	id, err := terms.Create(CreateParams{Command: []string{"sh", "-c", "echo hi; sleep 0.1"}, Cwd: "/tmp"})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	code, err := terms.WaitForExit(id)
	if err != nil || code != 0 {
		t.Fatalf("wait: code=%d err=%v", code, err)
	}
	out, err := terms.Output(id)
	if err != nil || !strings.Contains(out, "hi") {
		t.Fatalf("output = %q err=%v", out, err)
	}
	if err := terms.Release(id); err != nil {
		t.Fatalf("release: %v", err)
	}
}

func TestTerminalKillReportsBoundary(t *testing.T) {
	terms := NewTerminals()
	id, _ := terms.Create(CreateParams{Command: []string{"sleep", "30"}})
	if err := terms.Kill(id); err == nil || !strings.Contains(err.Error(), "EACCES") {
		t.Fatalf("kill 应报信号策略边界, got %v", err)
	}
	_ = terms.Release(id)
}

func TestFsBounded(t *testing.T) {
	dir := t.TempDir()
	if err := WriteTextFileBounded(WriteParams{Path: dir + "/a.txt", Content: "x"}); err != nil {
		t.Fatal(err)
	}
	out, err := ReadTextFileBounded(ReadParams{Path: dir + "/a.txt"})
	if err != nil || out != "x" {
		t.Fatalf("read = %q err=%v", out, err)
	}
	if err := WriteTextFileBounded(WriteParams{Path: "rel.txt", Content: "x"}); err != ErrNotAbsolute {
		t.Fatalf("相对路径应拒, got %v", err)
	}
}

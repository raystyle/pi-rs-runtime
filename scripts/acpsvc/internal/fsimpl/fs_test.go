package fsimpl

import (
	"errors"
	"path/filepath"
	"testing"
)

func TestReadWriteRoundtrip(t *testing.T) {
	p := filepath.Join(t.TempDir(), "note.txt")
	if err := WriteTextFile(p, "hello"); err != nil {
		t.Fatalf("write: %v", err)
	}
	got, err := ReadTextFile(p)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if got != "hello" {
		t.Fatalf("content = %q", got)
	}
}

func TestRejectsRelativePath(t *testing.T) {
	if _, err := ReadTextFile("rel.txt"); !errors.Is(err, ErrNotAbsolute) {
		t.Fatalf("read err = %v", err)
	}
	if err := WriteTextFile("rel.txt", "x"); !errors.Is(err, ErrNotAbsolute) {
		t.Fatalf("write err = %v", err)
	}
}

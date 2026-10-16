package backend

import (
	"os"
	"path/filepath"
	"testing"
)

func writePkg(t *testing.T, binJSON string) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "package.json"), []byte(`{"name":"x","bin":`+binJSON+`}`), 0o644); err != nil {
		t.Fatal(err)
	}
	return dir
}

func TestBinFromString(t *testing.T) {
	dir := writePkg(t, `"./cli.js"`)
	got, err := BinFromPackageJSON(dir, "x")
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if got != filepath.Join(dir, "cli.js") {
		t.Fatalf("bin = %q", got)
	}
}

func TestBinFromMapPrefersPkgName(t *testing.T) {
	dir := writePkg(t, `{"other":"./o.js","x":"./x.js"}`)
	got, err := BinFromPackageJSON(dir, "x")
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if got != filepath.Join(dir, "x.js") {
		t.Fatalf("bin = %q", got)
	}
}

func TestBinMissing(t *testing.T) {
	dir := t.TempDir()
	if _, err := BinFromPackageJSON(dir, "x"); err == nil {
		t.Fatal("缺 package.json 应报错")
	}
}

func TestRegistryThreeRows(t *testing.T) {
	reg := Registry()
	if len(reg) != 3 {
		t.Fatalf("rows = %d, want 3", len(reg))
	}
	if reg[0].Name != "claude" || reg[1].Name != "codex" || reg[2].Name != "pi" {
		t.Fatalf("names = %v", reg)
	}
	if _, ok := Find("pi"); !ok {
		t.Fatal("pi 行应可查")
	}
	if _, ok := Find("nope"); ok {
		t.Fatal("未知名不应命中")
	}
}

func TestAllowedWhitelist(t *testing.T) {
	// 未设=仅 pi(2026-10-16 core 裁定:默认翻为 pi 单面)
	t.Setenv("ACPSUP_AGENTS", "")
	got, err := Allowed()
	if err != nil || len(got) != 1 || got[0].Name != "pi" {
		t.Fatalf("未设应 pi 单面: got=%d err=%v", len(got), err)
	}
	// 单面(一 agent 一容器):交集
	t.Setenv("ACPSUP_AGENTS", "pi")
	got, err = Allowed()
	if err != nil || len(got) != 1 || got[0].Name != "pi" {
		t.Fatalf("单面过滤错: got=%v err=%v", got, err)
	}
	// 多名分隔符(逗号/空格混排)
	t.Setenv("ACPSUP_AGENTS", "claude, codex")
	got, err = Allowed()
	if err != nil || len(got) != 2 {
		t.Fatalf("混排分隔符错: got=%d err=%v", len(got), err)
	}
	// 未注册名=硬错(打错字静默清空比失败更坏)
	t.Setenv("ACPSUP_AGENTS", "pi,typo")
	if _, err := Allowed(); err == nil {
		t.Fatal("未注册名应硬错")
	}
	// 零名单=硬错
	t.Setenv("ACPSUP_AGENTS", ", ,")
	if _, err := Allowed(); err == nil {
		t.Fatal("零名单应硬错")
	}
}

func TestPiReadyModes(t *testing.T) {
	// 就绪:假二进制 --help 列出 acp
	okBin := filepath.Join(t.TempDir(), "pi-fake")
	if err := os.WriteFile(okBin, []byte("#!/bin/sh\necho '--mode text --mode acp'\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := PiReady([]string{okBin, "--mode", "acp"}); err != nil {
		t.Fatalf("ready err: %v", err)
	}
	// 模式未列
	noBin := filepath.Join(t.TempDir(), "pi-fake2")
	if err := os.WriteFile(noBin, []byte("#!/bin/sh\necho '--mode text'\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := PiReady([]string{noBin}); err == nil {
		t.Fatal("未列 acp 应不就绪")
	}
	// 二进制缺席
	if err := PiReady([]string{"/nonexistent/pi-rs"}); err == nil {
		t.Fatal("缺席应不就绪")
	}
}

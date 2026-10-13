package logx

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestNewJSONShape(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, "")
	log.Info("http", "cat", "access", "status", 200)
	line := strings.TrimSpace(buf.String())
	var rec map[string]any
	if err := json.Unmarshal([]byte(line), &rec); err != nil {
		t.Fatalf("非 JSON 行: %v: %q", err, line)
	}
	for _, k := range []string{"time", "level", "msg", "cat"} {
		if _, ok := rec[k]; !ok {
			t.Fatalf("缺字段 %s: %q", k, line)
		}
	}
	if rec["level"] != "INFO" || rec["status"].(float64) != 200 {
		t.Fatalf("字段值不符: %q", line)
	}
}

func TestLevelGate(t *testing.T) {
	var buf bytes.Buffer
	t.Setenv("ACPSUP_LOG_TEST_LEVEL", "error")
	log := New(&buf, "ACPSUP_LOG_TEST_LEVEL")
	log.Info("不应出现")
	log.Error("应出现")
	out := buf.String()
	if strings.Contains(out, "不应出现") {
		t.Fatal("info 不该过 error 级")
	}
	if !strings.Contains(out, "应出现") {
		t.Fatal("error 级被丢")
	}
}

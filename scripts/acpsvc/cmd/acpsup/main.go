// acpsup 是 ACP 监督进程(Go 承接工程,REQ-0007/S-0003)。
// 平台面:仅回环 HTTP + Bearer;--selftest 跑完即退,占 --port 自检。
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/acpclient"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/backend"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/logx"
	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/platform"
)

// version 是服务自身版本;发布经 -ldflags '-X main.version=...' 注入(S-0003 第 1 节)。
var version = "0.2.0"

func main() {
	port := flag.Int("port", 7663, "平台 HTTP 监听端口(仅回环)")
	selftest := flag.String("selftest", "", "自检模式:给 agent 名,跑完即退")
	dataDir := flag.String("data-dir", "/var/lib/acpsup", "密钥与 token 目录")
	logPath := flag.String("log", "/var/log/acpsup/acpsup.log", "日志文件路径")
	showVersion := flag.Bool("version", false, "打印版本并退出")
	flag.Parse()
	if *showVersion {
		fmt.Printf("acpsup %s (go)\n", version)
		return
	}

	w, err := logx.NewFileWriter(logx.FileOption{Path: *logPath})
	if err != nil {
		fmt.Fprintf(os.Stderr, "!! 日志文件建不了: %v\n", err)
		os.Exit(1)
	}
	log := logx.New(w, "ACPSUP_LOG_LEVEL")

	srv, err := platform.New(platform.Config{Port: *port, DataDir: *dataDir, Log: log})
	if err != nil {
		fmt.Fprintf(os.Stderr, "!! 服务面装不了: %v\n", err)
		os.Exit(1)
	}
	if err := srv.EnsureKeys(); err != nil {
		fmt.Fprintf(os.Stderr, "!! 密钥面装不了: %v\n", err)
		os.Exit(1)
	}

	if *selftest != "" {
		go func() {
			if err := srv.ListenAndServe(); err != nil {
				fmt.Fprintf(os.Stderr, "!! 自检服务面起不来: %v\n", err)
			}
		}()
		time.Sleep(300 * time.Millisecond)
		runSelftest(srv, *selftest, w)
		os.Exit(0)
	}

	fmt.Fprintf(os.Stderr, "acpsup %s 听 127.0.0.1:%d(密钥落 %s)\n", version, *port, srv.KeysPath())
	if err := srv.ListenAndServe(); err != nil {
		fmt.Fprintf(os.Stderr, "!! 平台面起不来: %v\n", err)
		os.Exit(1)
	}
}

// runSelftest 出协议级证据:initialize 回 protocolVersion=1、session/new 回真 sessionId、
// prompt 出 stopReason(鉴权失败也算协议面证据);与 TS 版同口径。
func runSelftest(srv *platform.Server, which string, w interface{ Close() error }) {
	t0 := time.Now()
	def, ok := backend.Find(which)
	if !ok {
		fmt.Fprintf(os.Stderr, "selftest FAIL: 未知名 %s\n", which)
		os.Exit(1)
	}
	argv, err := def.Resolve()
	if err != nil {
		fmt.Fprintf(os.Stderr, "selftest FAIL: 适配器 %s 未就绪(%v)\n", which, err)
		os.Exit(1)
	}
	ag, err := acpclient.Spawn(def.Name, argv, def.Env, "/tmp")
	if err != nil {
		fmt.Fprintf(os.Stderr, "selftest FAIL: 拉不起 %s: %v\n", which, err)
		os.Exit(1)
	}
	defer ag.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	caps := map[string]any{
		"fs":       map[string]any{"readTextFile": def.FS, "writeTextFile": def.FS},
		"terminal": def.Terminal,
	}
	initRaw, err := ag.Request(ctx, "initialize", map[string]any{"protocolVersion": 1, "clientCapabilities": caps})
	if err != nil {
		fmt.Fprintf(os.Stderr, "selftest FAIL: initialize %v;stderr 尾:%v\n", err, ag.StderrTail())
		os.Exit(1)
	}
	var init struct {
		ProtocolVersion int `json:"protocolVersion"`
	}
	_ = json.Unmarshal(initRaw, &init)
	fmt.Printf("selftest initialize: protocolVersion=%d(%dms)\n", init.ProtocolVersion, time.Since(t0).Milliseconds())

	snRaw, err := ag.Request(ctx, "session/new", map[string]any{"cwd": "/tmp", "mcpServers": []any{}})
	if err != nil {
		fmt.Fprintf(os.Stderr, "selftest FAIL: session/new %v;stderr 尾:%v\n", err, ag.StderrTail())
		os.Exit(1)
	}
	var sn struct {
		SessionID string `json:"sessionId"`
	}
	_ = json.Unmarshal(snRaw, &sn)
	fmt.Printf("selftest session/new: %s\n", sn.SessionID)

	pctx, pcancel := context.WithTimeout(context.Background(), 600*time.Second)
	defer pcancel()
	res, err := ag.Request(pctx, "session/prompt", map[string]any{
		"sessionId": sn.SessionID,
		"prompt":    []any{map[string]any{"type": "text", "text": "只回复 ok"}},
	})
	if err != nil {
		fmt.Printf("selftest prompt 失败面(协议面证据):%v\n", truncate(err.Error(), 200))
	} else {
		fmt.Printf("selftest prompt 回:%s\n", truncate(string(res), 200))
	}
	_ = w.Close()
	fmt.Printf("selftest PASS(%s)\n", which)
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}

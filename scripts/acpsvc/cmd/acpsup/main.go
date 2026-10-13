// acpsup 是 ACP 监督进程的 Go 承接工程(REQ-0007,S-0003)。
// M0 建库面:只做参数面与版本输出,不启服务、不占端口;
// 平台 HTTP 与 stdio 监督按 M1 起进 internal 各包。
package main

import (
	"flag"
	"fmt"
	"os"
)

// version 是服务自身版本;发布经 -ldflags '-X main.version=...' 注入(S-0003 第 1 节)。
var version = "0.1.0"

func main() {
	port := flag.Int("port", 7663, "平台 HTTP 监听端口(仅回环;M1 起生效)")
	selftest := flag.String("selftest", "", "自检模式:给 agent 名,跑完即退(M1 起)")
	showVersion := flag.Bool("version", false, "打印版本并退出")
	flag.Parse()
	if *showVersion {
		fmt.Printf("acpsup %s (go)\n", version)
		return
	}
	if *selftest != "" {
		fmt.Fprintf(os.Stderr, "acpsup %s:selftest %q 在 M1 提供;M0 建库面不启服务\n", version, *selftest)
	} else {
		fmt.Fprintf(os.Stderr, "acpsup %s:平台面在 M1 起提供(port=%d 预留);M0 建库面\n", version, *port)
	}
	os.Exit(2)
}

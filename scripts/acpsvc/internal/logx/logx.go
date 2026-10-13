// Package logx 统一监督进程日志:slog JSON、cat 分类、恒不落敏感字段。
// M0 只建 handler 面;轮转 Writer(lumberjack)与审计字段族按 M1 接上(S-0003 第 3 节)。
package logx

import (
	"io"
	"log/slog"
	"os"
	"strings"
)

// New 建 JSON logger;级别只在进程启动时读一次环境变量,缺省 info。
// 容器内改级别走 /shutdown 后 systemd 拉起,不做运行中热改。
func New(w io.Writer, envName string) *slog.Logger {
	if envName == "" {
		envName = "ACPSUP_LOG_LEVEL"
	}
	lvl := slog.LevelInfo
	switch strings.ToLower(os.Getenv(envName)) {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	}
	return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{Level: lvl}))
}

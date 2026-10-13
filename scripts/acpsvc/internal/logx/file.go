// Package logx 的文件面:单文件 + 进程内轮转(不发信号,适配容器信号策略)。
package logx

import (
	"io"
	"os"
	"path/filepath"

	"gopkg.in/natefinch/lumberjack.v2"
)

// FileOption 是日志文件参数(S-0003 第 3 节默认值)。
type FileOption struct {
	Path       string // 日志文件路径
	MaxSizeMB  int
	MaxBackups int
	MaxAgeDays int
	DirPerm    os.FileMode
	FilePerm   os.FileMode
}

// NewFileWriter 建目录(0750)并返回轮转 Writer(0600 由 lumberjack 首写落)。
func NewFileWriter(opt FileOption) (io.WriteCloser, error) {
	if opt.MaxSizeMB == 0 {
		opt.MaxSizeMB = 50
	}
	if opt.MaxBackups == 0 {
		opt.MaxBackups = 5
	}
	if opt.MaxAgeDays == 0 {
		opt.MaxAgeDays = 14
	}
	if opt.DirPerm == 0 {
		opt.DirPerm = 0o750
	}
	if err := os.MkdirAll(filepath.Dir(opt.Path), opt.DirPerm); err != nil {
		return nil, err
	}
	return &lumberjack.Logger{
		Filename:   opt.Path,
		MaxSize:    opt.MaxSizeMB,
		MaxBackups: opt.MaxBackups,
		MaxAge:     opt.MaxAgeDays,
		Compress:   true,
		LocalTime:  true,
	}, nil
}

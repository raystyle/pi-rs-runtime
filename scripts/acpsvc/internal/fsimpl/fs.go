// Package fsimpl 实现 ACP Client 的 fs 回调面:绝对路径读写文本。
// terminal 族按 S-0003 第 2 节用 spawn;kill 面在本机回 EACCES 是宿主信号策略,Go 侧不重试。
package fsimpl

import (
	"errors"
	"os"
	"path/filepath"
)

// ErrNotAbsolute 拒绝相对路径;ACP fs 回调只接绝对路径。
var ErrNotAbsolute = errors.New("fsimpl: 路径必须是绝对路径")

// ReadTextFile 读绝对路径文本文件。
func ReadTextFile(p string) (string, error) {
	if !filepath.IsAbs(p) {
		return "", ErrNotAbsolute
	}
	b, err := os.ReadFile(p)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// WriteTextFile 写绝对路径文本文件;新文件 0644。
func WriteTextFile(p, content string) error {
	if !filepath.IsAbs(p) {
		return ErrNotAbsolute
	}
	return os.WriteFile(p, []byte(content), 0o644)
}

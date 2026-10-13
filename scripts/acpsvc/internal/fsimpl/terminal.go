// Package fsimpl 的 terminal 面:ACP Client 的 terminal 回调在实例内真实现。
// kill 在宿主信号策略下恒 EACCES,如实回报,不假装成功;长命命令靠自退或 /shutdown。
package fsimpl

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
)

const (
	maxRead  = 4 << 20 // fs/read_text_file 上限
	maxWrite = 8 << 20 // fs/write_text_file 上限
	termCap  = 1 << 20 // 终端输出尾窗
)

// ReadParams 是 fs/read_text_file 参数。
type ReadParams struct {
	Path string `json:"path"`
}

// WriteParams 是 fs/write_text_file 参数。
type WriteParams struct {
	Path    string `json:"path"`
	Content string `json:"content"`
}

// ReadTextFileBounded 带大小闸读文本(适配器回调面)。
func ReadTextFileBounded(p ReadParams) (string, error) {
	if !filepath.IsAbs(p.Path) {
		return "", ErrNotAbsolute
	}
	st, err := os.Stat(p.Path)
	if err != nil {
		return "", err
	}
	if st.Size() > maxRead {
		return "", fmt.Errorf("文件过大 %d", st.Size())
	}
	s, err := ReadTextFile(p.Path)
	return s, err
}

// WriteTextFileBounded 带大小闸写文本,自动建父目录。
func WriteTextFileBounded(p WriteParams) error {
	if !filepath.IsAbs(p.Path) {
		return ErrNotAbsolute
	}
	if len(p.Content) > maxWrite {
		return fmt.Errorf("写入过大")
	}
	if err := os.MkdirAll(filepath.Dir(p.Path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(p.Path, []byte(p.Content), 0o644)
}

type term struct {
	cmd      []string
	cwd      string
	mu       sync.Mutex
	output   strings.Builder
	exited   bool
	exitCode int
	waiters  []chan struct{}
}

// Terminals 是 terminal/create 族回调的实现表。
type Terminals struct {
	mu   sync.Mutex
	next int
	byID map[string]*term
}

// NewTerminals 建空表。
func NewTerminals() *Terminals { return &Terminals{byID: make(map[string]*term), next: 1} }

// CreateParams 是 terminal/create 参数。
type CreateParams struct {
	Command []string `json:"command"`
	Cwd     string   `json:"cwd,omitempty"`
}

// Create spawn 一条命令,stdin 关闭,stdout/stderr 进输出窗。
func (t *Terminals) Create(p CreateParams) (string, error) {
	if len(p.Command) == 0 {
		return "", fmt.Errorf("command 为空")
	}
	cwd := p.Cwd
	if cwd == "" {
		cwd = "/"
	}
	id := ""
	t.mu.Lock()
	id = fmt.Sprintf("t%d", t.next)
	t.next++
	tm := &term{cmd: p.Command, cwd: cwd}
	t.byID[id] = tm
	t.mu.Unlock()

	cmd := exec.Command(p.Command[0], p.Command[1:]...)
	cmd.Dir = cwd
	cmd.Stdin = nil
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return "", err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return "", err
	}
	if err := cmd.Start(); err != nil {
		return "", err
	}
	drain := func(r interface{ Read([]byte) (int, error) }) {
		buf := make([]byte, 8192)
		for {
			n, err := r.Read(buf)
			if n > 0 {
				tm.mu.Lock()
				tm.output.Write(buf[:n])
				if tm.output.Len() > termCap {
					s := tm.output.String()
					tm.output.Reset()
					tm.output.WriteString(s[len(s)-termCap:])
				}
				tm.mu.Unlock()
			}
			if err != nil {
				return
			}
		}
	}
	go drain(stdout)
	go drain(stderr)
	go func() {
		err := cmd.Wait()
		code := 0
		if ee, ok := err.(*exec.ExitError); ok {
			code = ee.ExitCode()
		} else if err != nil {
			code = -1
		}
		tm.mu.Lock()
		tm.exited = true
		tm.exitCode = code
		waiters := tm.waiters
		tm.waiters = nil
		tm.mu.Unlock()
		for _, ch := range waiters {
			close(ch)
		}
	}()
	return id, nil
}

func (t *Terminals) get(id string) (*term, error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	tm, ok := t.byID[id]
	if !ok {
		return nil, fmt.Errorf("无终端 %s", id)
	}
	return tm, nil
}

// Output 返回当前输出窗。
func (t *Terminals) Output(id string) (string, error) {
	tm, err := t.get(id)
	if err != nil {
		return "", err
	}
	tm.mu.Lock()
	defer tm.mu.Unlock()
	return tm.output.String(), nil
}

// WaitForExit 等命令退出,返回退出码。
func (t *Terminals) WaitForExit(id string) (int, error) {
	tm, err := t.get(id)
	if err != nil {
		return 0, err
	}
	tm.mu.Lock()
	if tm.exited {
		defer tm.mu.Unlock()
		return tm.exitCode, nil
	}
	ch := make(chan struct{})
	tm.waiters = append(tm.waiters, ch)
	tm.mu.Unlock()
	<-ch
	tm.mu.Lock()
	defer tm.mu.Unlock()
	return tm.exitCode, nil
}

// Kill 在本机恒失败:宿主信号策略下信号投递 EACCES,如实回报。
func (t *Terminals) Kill(id string) error {
	if _, err := t.get(id); err != nil {
		return err
	}
	return fmt.Errorf("kill 被宿主信号策略拦(EACCES,known-issues);命令将运行至自然退出")
}

// Release 弃一条终端记录。
func (t *Terminals) Release(id string) error {
	if _, err := t.get(id); err != nil {
		return err
	}
	t.mu.Lock()
	delete(t.byID, id)
	t.mu.Unlock()
	return nil
}

package acpclient

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// wireMsg 是线上一条消息的通用形状;id 原样回写(适配器的 id 可能是字符串)。
type wireMsg struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Params  json.RawMessage `json:"params,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *Error          `json:"error,omitempty"`
}

// Agent 是一个适配器子进程的 stdio 客户端;stdout 只有 ACP 帧,stderr 进尾环。
type Agent struct {
	Name string

	cmd    *exec.Cmd
	stdin  io.WriteCloser
	sendMu sync.Mutex

	nextID  uint64
	pendMu  sync.Mutex
	pending map[uint64]chan wireMsg

	// OnUpdate 收 session/update 通知(参数 {sessionId, update})。
	OnUpdate func(params json.RawMessage)
	// OnServerRequest 收适配器发起的请求;respond/respondErr 二选一必调一次。
	OnServerRequest func(method string, params json.RawMessage, respond func(any), respondErr func(int, string))

	stderrMu   sync.Mutex
	stderrTail []string
	StderrOut  io.Writer // 额外 stderr 转出口(可空);监督进程接调试日志

	exitOnce sync.Once
	exitCh   chan struct{}
	exitCode int
}

// Spawn 拉起子进程;env 是 KEY=VALUE 追加项,cwd 必须绝对路径。
func Spawn(name string, argv []string, env []string, cwd string) (*Agent, error) {
	if len(argv) == 0 {
		return nil, fmt.Errorf("acpclient: argv 为空")
	}
	a := &Agent{
		Name:    name,
		cmd:     exec.Command(argv[0], argv[1:]...),
		pending: make(map[uint64]chan wireMsg),
		exitCh:  make(chan struct{}),
	}
	a.cmd.Dir = cwd
	a.cmd.Env = append(os.Environ(), env...)
	stdin, err := a.cmd.StdinPipe()
	if err != nil {
		return nil, err
	}
	stdout, err := a.cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	stderr, err := a.cmd.StderrPipe()
	if err != nil {
		return nil, err
	}
	a.stdin = stdin
	if err := a.cmd.Start(); err != nil {
		return nil, err
	}
	go a.readLoop(stdout)
	go a.stderrLoop(stderr)
	go func() {
		err := a.cmd.Wait()
		a.exitOnce.Do(func() {
			if ee, ok := err.(*exec.ExitError); ok {
				a.exitCode = ee.ExitCode()
			} else if err != nil {
				a.exitCode = -1
			}
			a.failPending(fmt.Errorf("适配器退出 code=%d", a.exitCode))
			close(a.exitCh)
		})
	}()
	return a, nil
}

// Exited 在进程退出后返回退出码。
func (a *Agent) Exited() <-chan struct{} { return a.exitCh }

func (a *Agent) ExitCode() int { return a.exitCode }

func (a *Agent) log(format string, args ...any) {
	line := fmt.Sprintf(format, args...)
	a.stderrMu.Lock()
	a.stderrTail = append(a.stderrTail, line)
	if len(a.stderrTail) > 50 {
		a.stderrTail = a.stderrTail[len(a.stderrTail)-50:]
	}
	out := a.StderrOut
	a.stderrMu.Unlock()
	if out != nil {
		fmt.Fprintf(out, "[acp:%s] %s\n", a.Name, line)
	}
}

// StderrTail 返回尾环副本(错误响应里带给平台排查)。
func (a *Agent) StderrTail() []string {
	a.stderrMu.Lock()
	defer a.stderrMu.Unlock()
	return append([]string(nil), a.stderrTail...)
}

func (a *Agent) stderrLoop(r io.Reader) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64*1024), 1<<20)
	for sc.Scan() {
		if t := strings.TrimSpace(sc.Text()); t != "" {
			a.log("[adapter-stderr] %s", clip(t, 300))
		}
	}
}

func clip(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}

func (a *Agent) readLoop(r io.Reader) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 256*1024), 16<<20) // 长 prompt 单行
	for sc.Scan() {
		line := bytes.TrimSpace(sc.Bytes())
		if len(line) == 0 {
			continue
		}
		var msg wireMsg
		if err := json.Unmarshal(line, &msg); err != nil {
			a.log("!! 非 JSON 行:%s", clip(string(line), 120))
			continue
		}
		a.dispatch(msg)
	}
}

func (a *Agent) dispatch(msg wireMsg) {
	if msg.Method != "" {
		// 适配器 -> 平台:请求或通知
		if len(msg.ID) > 0 {
			if a.OnServerRequest != nil {
				id := msg.ID
				a.OnServerRequest(msg.Method, msg.Params,
					func(result any) { a.respond(id, result, nil) },
					func(code int, message string) { a.respond(id, nil, &Error{Code: code, Message: message}) })
			}
		} else if msg.Method == "session/update" && a.OnUpdate != nil {
			a.OnUpdate(msg.Params)
		}
		return
	}
	// 应答:按数字 id 匹配挂起
	var n uint64
	if err := json.Unmarshal(msg.ID, &n); err != nil {
		return
	}
	a.pendMu.Lock()
	ch, ok := a.pending[n]
	if ok {
		delete(a.pending, n)
	}
	a.pendMu.Unlock()
	if ok {
		ch <- msg
	}
}

func (a *Agent) respond(id json.RawMessage, result any, rpcErr *Error) {
	m := wireMsg{JSONRPC: "2.0", ID: id}
	if rpcErr != nil {
		m.Error = rpcErr
	} else {
		b, err := json.Marshal(result)
		if err != nil {
			m.Error = &Error{Code: -32000, Message: err.Error()}
		} else {
			m.Result = b
		}
	}
	a.send(m)
}

func (a *Agent) send(m wireMsg) {
	b, err := json.Marshal(m)
	if err != nil {
		return
	}
	b = bytes.ReplaceAll(b, []byte("\n"), []byte(" ")) // 单行纪律:换行进不了帧
	a.sendMu.Lock()
	defer a.sendMu.Unlock()
	if a.stdin != nil {
		_, _ = a.stdin.Write(append(b, '\n'))
	}
}

// Request 发一条请求并等结果;ctx 截止即超时返回。
func (a *Agent) Request(ctx context.Context, method string, params any) (json.RawMessage, error) {
	a.pendMu.Lock()
	a.nextID++
	id := a.nextID
	ch := make(chan wireMsg, 1)
	a.pending[id] = ch
	a.pendMu.Unlock()

	pb, err := json.Marshal(params)
	if err != nil {
		return nil, err
	}
	a.send(wireMsg{JSONRPC: "2.0", ID: json.RawMessage(fmt.Sprint(id)), Method: method, Params: pb})

	select {
	case <-ctx.Done():
		a.pendMu.Lock()
		delete(a.pending, id)
		a.pendMu.Unlock()
		return nil, fmt.Errorf("请求超时 %s", method)
	case msg := <-ch:
		if msg.Error != nil {
			return nil, msg.Error
		}
		return msg.Result, nil
	case <-a.exitCh:
		a.pendMu.Lock()
		delete(a.pending, id)
		a.pendMu.Unlock()
		return nil, fmt.Errorf("适配器已退出")
	}
}

// Notify 发一条通知,不等结果。
func (a *Agent) Notify(method string, params any) {
	pb, _ := json.Marshal(params)
	a.send(wireMsg{JSONRPC: "2.0", Method: method, Params: pb})
}

func (a *Agent) failPending(err error) {
	a.pendMu.Lock()
	defer a.pendMu.Unlock()
	for id, ch := range a.pending {
		delete(a.pending, id)
		_ = err
		ch <- wireMsg{Error: &Error{Code: -32000, Message: err.Error()}}
	}
}

// Close 关 stdin 并等退出(不投信号;适配器 stdin 关闭即自退)。
// 等退出有界:长命子进程不拖垮调用方;回收兜底交内核与等待 goroutine。
func (a *Agent) Close() {
	a.sendMu.Lock()
	if a.stdin != nil {
		_ = a.stdin.Close()
		a.stdin = nil
	}
	a.sendMu.Unlock()
	select {
	case <-a.exitCh:
	case <-time.After(3 * time.Second):
	}
}

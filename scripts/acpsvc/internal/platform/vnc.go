// Package platform 的 VNC 直显面:每会话 Xvfb + 有头 clean-chrome,每条 WS 一条
// x11vnc -inetd(stdio 即 RFB),WS↔RFB 二进制直通。设计照 grok 研究回执(2026-10-14):
// 回收全走自退道(容器内 kill 族 EACCES,systemd-run 收割失败已验)——x11vnc 关 stdin 自退、
// chrome 走 CDP Browser.close、Xvfb -terminate 在末个 X 客户端离开时自退;停不掉的槽标泄漏,
// 本进程生命周期内不复用,容器重启才清。
package platform

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/coder/websocket"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/session"
)

const (
	vncSlotCount   = 32
	vncDisplayBase = 100 // :100-:131;避开 :99/:1 桌面面与 9222/5900/6080/7663/9880/9900-9999
	vncCdpBase     = 19200
	vncScreen      = "1280x800x24"
	vncEnsureWait  = 15 * time.Second
	vncXWait       = 3 * time.Second
	vncPingEvery   = 30 * time.Second
)

// vncStack 是一个会话的显示栈(Xvfb+chrome;x11vnc 每条 WS 现起现退,不属栈)。
type vncStack struct {
	mgr      *vncManager
	id       string
	slot     int
	dir      string
	display  int
	cdpPort  int
	mu       sync.Mutex
	xvfb     *exec.Cmd
	chrome   *exec.Cmd
	xvfbDone chan struct{}
	chromeDn chan struct{}
	xvfbLog  *os.File // 子进程 stdout/stderr 的 fd 必须由栈持有:局部变量被 GC 关 fd 后子进程写日志即 SIGPIPE 死
	chromeLg *os.File
	holder   *exec.Cmd // 显示持有者(x11vnc -inetd,stdin 在本栈手里):-terminate 服务器在客户端数 1→0 即自退,探针这类瞬态客户端会带走服务器,须有常驻客户端撑到 chrome 接上
	holderIn io.WriteCloser
	leaky    bool
	prevEnd  func() // 前一条桥的收尾(关其 x11vnc stdin;第二条 WS 替换第一条)
}

// vncManager 管槽位与栈;进程内单例,随 acpsup 生命周期。
type vncManager struct {
	base string
	log  *slog.Logger

	xvfbBin    string
	xdpyinfo   string
	xauthBin   string
	chromeBin  string
	x11vncBin  string
	extraIPv4s func() []string // 暴露面探针(容器非回环 IPv4;测试可注假)

	mu    sync.Mutex
	slots [vncSlotCount]*vncStack

	hookEnsure func(*session.Session) (*vncStack, error) // 测试注入(绕真栈)
}

func newVNCManager(base string, logger *slog.Logger) *vncManager {
	return &vncManager{
		base:       base,
		log:        logger,
		xvfbBin:    "Xvfb",
		xdpyinfo:   "xdpyinfo",
		xauthBin:   "xauth",
		chromeBin:  "/usr/local/bin/clean-chrome",
		x11vncBin:  "x11vnc",
		extraIPv4s: containerIPv4s,
	}
}

// containerIPv4s 枚举非回环 IPv4(暴露面探针用)。
func containerIPv4s() []string {
	var out []string
	ifaces, err := net.Interfaces()
	if err != nil {
		return nil
	}
	for _, ifc := range ifaces {
		if ifc.Flags&net.FlagLoopback != 0 || ifc.Flags&net.FlagUp == 0 {
			continue
		}
		addrs, _ := ifc.Addrs()
		for _, a := range addrs {
			if ipn, ok := a.(*net.IPNet); ok {
				if ip4 := ipn.IP.To4(); ip4 != nil {
					out = append(out, ip4.String())
				}
			}
		}
	}
	return out
}

func xSocket(display int) string { return fmt.Sprintf("/tmp/.X11-unix/X%d", display) }

func cdpVersionURL(port int) string { return fmt.Sprintf("http://127.0.0.1:%d/json/version", port) }

// cdpVersion 拉 /json/version;返回 webSocketDebuggerUrl。
func cdpVersion(port int, timeout time.Duration) (string, error) {
	cli := &http.Client{Timeout: timeout}
	res, err := cli.Get(cdpVersionURL(port))
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		return "", fmt.Errorf("cdp /json/version = %d", res.StatusCode)
	}
	var v struct {
		Ws string `json:"webSocketDebuggerUrl"`
	}
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil || v.Ws == "" {
		return "", errors.New("cdp 未回 webSocketDebuggerUrl")
	}
	return v.Ws, nil
}

// bootSweep 重启旧账:acpsup 重启后孤儿 chrome 还在旧显示上;用确定性的口映射
// (:100+N ↔ 19200+N)走 CDP Browser.close 优雅收掉,Xvfb 随 -terminate 自退;
// 收不掉的槽标泄漏(不发信号)。之后清基目录。
func (m *vncManager) bootSweepAsync() {
	go func() {
		defer func() { _ = recover() }()
		m.bootSweep()
	}()
}

func (m *vncManager) bootSweep() {
	// 持锁整程:与 Ensure 的 alloc 串行,防止异步清扫在中途 RemoveAll 抽走活栈的目录
	m.mu.Lock()
	defer m.mu.Unlock()
	orphans := 0
	for i := 0; i < vncSlotCount; i++ {
		display := vncDisplayBase + i
		if _, err := os.Stat(xSocket(display)); err != nil {
			continue
		}
		orphans++
		m.closeOrphanChrome(vncCdpBase + i)
		dl := time.Now().Add(2 * time.Second)
		for time.Now().Before(dl) {
			if _, err := os.Stat(xSocket(display)); os.IsNotExist(err) {
				break
			}
			time.Sleep(100 * time.Millisecond)
		}
		if _, err := os.Stat(xSocket(display)); err == nil {
			m.slots[i] = &vncStack{mgr: m, slot: i, leaky: true, display: display, cdpPort: vncCdpBase + i}
			continue
		}
	}
	// 基目录只在零孤儿时整体清(有孤儿时目录里可能还有现场,不赌)
	if orphans == 0 {
		_ = os.RemoveAll(m.base)
		_ = os.MkdirAll(m.base, 0o700)
	} else {
		_ = os.MkdirAll(m.base, 0o700)
	}
	if m.log != nil {
		m.log.Info("vnc_boot_sweep", "cat", "audit", "orphans", orphans)
	}
}

// closeOrphanChrome 对孤儿 chrome 发 CDP Browser.close(自退道,不发信号)。
func (m *vncManager) closeOrphanChrome(port int) {
	wsURL, err := cdpVersion(port, 2*time.Second)
	if err != nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	c, _, err := websocket.Dial(ctx, wsURL, nil)
	if err != nil {
		return
	}
	defer c.CloseNow()
	_ = c.Write(ctx, websocket.MessageText, []byte(`{"id":1,"method":"Browser.close"}`))
}

func (m *vncManager) markLeak(slot int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.slots[slot] == nil {
		m.slots[slot] = &vncStack{mgr: m, slot: slot, leaky: true, display: vncDisplayBase + slot, cdpPort: vncCdpBase + slot}
	} else {
		m.slots[slot].leaky = true
	}
	if m.log != nil {
		m.log.Warn("vnc_slot_leak", "cat", "audit", "slot", slot, "display", vncDisplayBase+slot)
	}
}

func (m *vncManager) freeSlot(slot int) {
	m.mu.Lock()
	m.slots[slot] = nil
	m.mu.Unlock()
}

// Ensure 取会话的显示栈;无则起(Xvfb+chrome,含就绪等待与暴露面校验),已有则健检,
// chrome 死了自愈(拆旧栈,换新槽)。首次创建时向会话注册拆卸钩子。
func (m *vncManager) Ensure(sess *session.Session) (*vncStack, error) {
	if m.hookEnsure != nil {
		return m.hookEnsure(sess)
	}
	id := sess.ID
	m.mu.Lock()
	var stale *vncStack
	for _, st := range m.slots {
		if st != nil && !st.leaky && st.id == id {
			if st.healthy() {
				m.mu.Unlock()
				return st, nil
			}
			stale = st // 健检失败:锁外拆旧(teardown 内 freeSlot 抢锁,死锁面已排)
			break
		}
	}
	st, err := m.alloc(id) // 锁内挑槽(泄漏标记走锁内内联,不调 markLeak)
	m.mu.Unlock()
	if stale != nil {
		stale.teardown()
	}
	if err != nil {
		return nil, err
	}
	if err := st.start(); err != nil {
		st.teardown()
		return nil, err
	}
	sess.OnClose(func() { st.teardown() })
	return st, nil
}

// alloc 挑空槽(X 套接字与 CDP 口都空闲),锁内调用。
func (m *vncManager) alloc(id string) (*vncStack, error) {
	for i := 0; i < vncSlotCount; i++ {
		if m.slots[i] != nil {
			continue
		}
		display := vncDisplayBase + i
		port := vncCdpBase + i
		if _, err := os.Stat(xSocket(display)); err == nil {
			// 套接字在而槽空(非本进程起的):标泄漏跳过(锁内,内联不抢锁)
			m.slots[i] = &vncStack{mgr: m, slot: i, leaky: true, display: display, cdpPort: port}
			continue
		}
		if c, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", port), 200*time.Millisecond); err == nil {
			_ = c.Close()
			m.slots[i] = &vncStack{mgr: m, slot: i, leaky: true, display: display, cdpPort: port}
			continue
		}
		dir := filepath.Join(m.base, id)
		st := &vncStack{mgr: m, id: id, slot: i, dir: dir, display: display, cdpPort: port,
			xvfbDone: make(chan struct{}), chromeDn: make(chan struct{})}
		m.slots[i] = st // 锁内认领即入表(Ensure 的健检扫描按表找)
		return st, nil
	}
	return nil, errors.New("vnc 槽耗尽(32)")
}

// healthy 报 Xvfb 套接字与 chrome CDP 是否都还活着。
func (st *vncStack) healthy() bool {
	if _, err := os.Stat(xSocket(st.display)); err != nil {
		return false
	}
	if _, err := cdpVersion(st.cdpPort, 1*time.Second); err != nil {
		return false
	}
	return true
}

// start 起栈:xauth cookie → Xvfb(-terminate 自退道)→ 就绪等待 → 有头 chrome → CDP 就绪 →
// cdp.ws 落盘(0600)→ 暴露面校验(只许回环)。
func (st *vncStack) start() error {
	_ = os.MkdirAll(filepath.Dir(st.dir), 0o700)
	if err := os.MkdirAll(st.dir, 0o700); err != nil {
		return err
	}
	var err error
	// MIT-MAGIC-COOKIE-1(目录 0700、文件 0600;不 -ac)
	ck := make([]byte, 16)
	if _, err := rand.Read(ck); err != nil {
		return err
	}
	cookie := hex.EncodeToString(ck)
	xauthPath := filepath.Join(st.dir, "xauth")
	// 双条目:客户端(unix 套接字)按 "<hostname>/unix:N" 匹配,":N" 兜底(实测只写 ":N" 客户端不认)
	host, _ := os.Hostname()
	if out, err := exec.Command(st.mgr.xauthBin, "-f", xauthPath, "add",
		fmt.Sprintf("%s/unix:%d", host, st.display), ".", cookie).CombinedOutput(); err != nil {
		return fmt.Errorf("xauth add: %v: %s", err, out)
	}
	_ = exec.Command(st.mgr.xauthBin, "-f", xauthPath, "add", fmt.Sprintf(":%d", st.display), ".", cookie).Run()
	_ = os.Chmod(xauthPath, 0o600)

	st.xvfbLog, err = os.OpenFile(filepath.Join(st.dir, "xvfb.log"), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	st.xvfb = exec.Command(st.mgr.xvfbBin, fmt.Sprintf(":%d", st.display),
		"-screen", "0", vncScreen, "-nolisten", "tcp", "-auth", xauthPath,
		"+extension", "DAMAGE", "+extension", "RANDR", "-terminate")
	st.xvfb.Stdout, st.xvfb.Stderr = st.xvfbLog, st.xvfbLog
	if err := st.xvfb.Start(); err != nil {
		st.xvfbLog.Close()
		st.xvfbLog = nil
		return fmt.Errorf("Xvfb 起: %v", err)
	}
	go func() {
		werr := st.xvfb.Wait()
		if werr != nil && st.mgr.log != nil {
			st.mgr.log.Warn("xvfb_exit", "cat", "audit", "err", werr.Error())
		}
		close(st.xvfbDone)
	}()
	if err := waitXReady(st, vncXWait); err != nil {
		return err
	}
	if err := st.startHolder(); err != nil {
		return fmt.Errorf("显示持有者起: %v", err)
	}

	st.chromeLg, err = os.OpenFile(filepath.Join(st.dir, "chrome.log"), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	st.chrome = exec.Command(st.mgr.chromeBin,
		fmt.Sprintf("--user-data-dir=%s", filepath.Join(st.dir, "profile")),
		fmt.Sprintf("--remote-debugging-port=%d", st.cdpPort),
		"--auto-allow-devtools-connections",
		"--window-size=1280,800", "--window-position=0,0",
		"--no-first-run", "--no-default-browser-check",
		"--disable-sync", "--disable-background-networking",
		"--disable-gpu", "--disable-dev-shm-usage", "--disable-extensions",
		"about:blank")
	st.chrome.Env = append(os.Environ(), fmt.Sprintf("DISPLAY=:%d", st.display), "XAUTHORITY="+xauthPath)
	_ = os.WriteFile(filepath.Join(st.dir, "spawn-env.txt"), []byte(fmt.Sprintf("display=%d cdp=%d\n", st.display, st.cdpPort)+strings.Join(st.chrome.Env, "\n")), 0o600)
	st.chrome.Stdout, st.chrome.Stderr = st.chromeLg, st.chromeLg
	if err := st.chrome.Start(); err != nil {
		st.chromeLg.Close()
		st.chromeLg = nil
		return fmt.Errorf("chrome 起: %v", err)
	}
	go func() { _ = st.chrome.Wait(); close(st.chromeDn) }()

	dl := time.Now().Add(vncEnsureWait)
	var wsURL string
	for time.Now().Before(dl) {
		wsURL, err = cdpVersion(st.cdpPort, 1*time.Second)
		if err == nil {
			break
		}
		select {
		case <-st.chromeDn:
			return fmt.Errorf("chrome 启动即退: %s", clipFileHead(filepath.Join(st.dir, "chrome.log")))
		default:
		}
		time.Sleep(300 * time.Millisecond)
	}
	if err != nil {
		return fmt.Errorf("chrome CDP 15 秒未就绪: %v", err)
	}
	// 暴露面:CDP 只许回环;绑上非回环地址即拆(册:155 裸 --remote-debugging-port 默认回环)
	for _, ip := range st.mgr.extraIPv4s() {
		if c, derr := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", ip, st.cdpPort), 300*time.Millisecond); derr == nil {
			_ = c.Close()
			return fmt.Errorf("CDP 口暴露在非回环 %s", ip)
		}
	}
	if werr := os.WriteFile(filepath.Join(st.dir, "cdp.ws"), []byte(wsURL), 0o600); werr != nil {
		return werr
	}
	if st.mgr.log != nil {
		st.mgr.log.Info("vnc_stack_up", "cat", "audit", "session_id", st.id,
			"slot", st.slot, "display", st.display, "cdp_port", st.cdpPort)
	}
	return nil
}

func clipFileHead(p string) string {
	b, err := os.ReadFile(p)
	if err != nil {
		return "(日志不可读:" + err.Error() + ")"
	}
	if len(b) > 400 {
		b = b[:400]
	}
	return string(b)
}

func waitXReady(st *vncStack, wait time.Duration) error {
	// 就绪判定只用套接字文件,零客户端:-terminate 服务器在客户端 1→0 即自退,
	// 连了就走的探针会把刚起的服务器带走(实测病根)
	dl := time.Now().Add(wait)
	for time.Now().Before(dl) {
		if _, err := os.Stat(xSocket(st.display)); err == nil {
			return nil
		}
		select {
		case <-st.xvfbDone:
			return errors.New("Xvfb 启动即退(查 xvfb.log)")
		default:
		}
		time.Sleep(100 * time.Millisecond)
	}
	return errors.New("Xvfb 套接字 3 秒未就绪")
}

// startHolder 起显示持有者(x11vnc -inetd,stdin 由栈持有):作为常驻 X 客户端
// 撑住 -terminate 服务器;shell 包装做套接字文件轮询重试(同样零瞬态客户端)。
func (st *vncStack) startHolder() error {
	script := fmt.Sprintf("i=0; while [ ! -e %s ] && [ $i -lt 100 ]; do sleep 0.1; i=$((i+1)); done; exec %s -inetd -q -norc -nopw -display :%d -auth %s -nosel -noprimary -noncache -cursor arrow -wait 10 -defer 10 -speeds lan -threads -o %s",
		xSocket(st.display), st.mgr.x11vncBin, st.display, filepath.Join(st.dir, "xauth"), filepath.Join(st.dir, "holder.log"))
	cmd := exec.Command("/bin/sh", "-c", script)
	in, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	st.holder, st.holderIn = cmd, in
	go func() { _ = cmd.Wait() }()
	return nil
}

// teardown 自退链:chrome 走 CDP Browser.close(等 3 秒)→ Xvfb -terminate 随之自退
// (等 2 秒)→ 停不掉即标泄漏(不发信号,槽不复用);干净则清目录、释放槽。
func (st *vncStack) teardown() {
	st.mu.Lock()
	defer st.mu.Unlock()
	if st.prevEnd != nil {
		st.prevEnd()
		st.prevEnd = nil
	}
	// chrome:CDP Browser.close(自退道;失败即泄漏,不再发信号)
	select {
	case <-st.chromeDn:
	default:
		if wsURL, err := cdpVersion(st.cdpPort, 1*time.Second); err == nil {
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			if c, _, derr := websocket.Dial(ctx, wsURL, nil); derr == nil {
				_ = c.Write(ctx, websocket.MessageText, []byte(`{"id":1,"method":"Browser.close"}`))
				c.CloseNow()
			}
			cancel()
		}
		select {
		case <-st.chromeDn:
		case <-time.After(3 * time.Second):
			st.leaky = true
		}
	}
	// 关显示持有者:末个 X 客户端离开 → -terminate 服务器自退(回收链的收束点)
	if st.holderIn != nil {
		_ = st.holderIn.Close()
		st.holderIn = nil
	}
	select {
	case <-st.xvfbDone:
	case <-time.After(2 * time.Second):
		st.leaky = true
	}
	if st.xvfbLog != nil {
		_ = st.xvfbLog.Close()
		st.xvfbLog = nil
	}
	if st.chromeLg != nil {
		_ = st.chromeLg.Close()
		st.chromeLg = nil
	}
	if st.leaky {
		if st.mgr.log != nil {
			st.mgr.log.Warn("vnc_slot_leak", "cat", "audit", "session_id", st.id, "slot", st.slot)
		}
		return
	}
	_ = os.RemoveAll(st.dir)
	st.mgr.freeSlot(st.slot)
}

// Bridge 起 x11vnc -inetd(stdio 即 RFB)并接 WS↔RFB 双向直通;阻塞到任一侧结束。
// 第二条 WS 替换第一条(旧桥关 x11vnc stdin 自退),不并行输入。
func (st *vncStack) Bridge(sess *session.Session, w http.ResponseWriter, r *http.Request, logger *slog.Logger) error {
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		Subprotocols:       []string{"binary"},
		InsecureSkipVerify: true, // 鉴权是 Bearer;网关可能转发浏览器 Origin,默认校验会 403
	})
	if err != nil {
		return err
	}
	if conn.Subprotocol() != "binary" {
		_ = conn.Close(websocket.StatusPolicyViolation, "子协议须 binary")
		return nil
	}
	conn.SetReadLimit(4 << 20)

	xvfbLogPath := filepath.Join(st.dir, "x11vnc.log")
	lf, err := os.OpenFile(xvfbLogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		_ = conn.Close(websocket.StatusInternalError, "显示面日志不可写")
		return nil
	}
	cmd := exec.Command(st.mgr.x11vncBin, "-inetd", "-q", "-norc", "-nopw",
		"-display", fmt.Sprintf(":%d", st.display), "-auth", filepath.Join(st.dir, "xauth"),
		"-nosel", "-noprimary", "-noncache", "-cursor", "arrow",
		"-wait", "10", "-defer", "10", "-speeds", "lan", "-threads",
		"-o", xvfbLogPath)
	stdin, err1 := cmd.StdinPipe()
	stdout, err2 := cmd.StdoutPipe()
	cmd.Stderr = lf
	if err1 != nil || err2 != nil {
		_ = lf.Close()
		_ = conn.Close(websocket.StatusInternalError, "x11vnc 管道失败")
		return nil
	}
	if err := cmd.Start(); err != nil {
		_ = lf.Close()
		_ = conn.Close(websocket.StatusInternalError, "x11vnc 起失败")
		return nil
	}
	go func() { _ = cmd.Wait(); _ = lf.Close() }()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	wsNet := websocket.NetConn(ctx, conn, websocket.MessageBinary)

	st.mu.Lock()
	if st.prevEnd != nil {
		st.prevEnd() // 替换前一条桥:关其 x11vnc stdin,随旧 WS 自退
	}
	var once sync.Once
	end := func() {
		once.Do(func() {
			cancel()
			_ = stdin.Close() // -inetd 在 stdin EOF 自退
			_ = wsNet.Close()
			_ = conn.CloseNow()
		})
	}
	st.prevEnd = end
	st.mu.Unlock()
	defer end()

	go func() { defer end(); _, _ = io.Copy(stdin, wsNet) }()  // noVNC → x11vnc
	go func() { defer end(); _, _ = io.Copy(wsNet, stdout) }() // x11vnc → noVNC

	// 保活:ping 30s(中间盒空闲掐线);touch 隔拍(看画面不动键不逐出)
	go func() {
		t := time.NewTicker(vncPingEvery)
		defer t.Stop()
		i := 0
		for {
			select {
			case <-ctx.Done():
				return
			case <-t.C:
				if err := conn.Ping(ctx); err != nil {
					end()
					return
				}
				if i++; i%2 == 0 {
					sess.Touch()
				}
			}
		}
	}()
	<-ctx.Done()
	return nil
}

// handleVNC 是 GET /vnc?sessionId= 的 WS 升级面:鉴权同业务路由(caller 键),
// 且收紧到「caller 只能开自己建的会话」(VNC 能看能点;跨键与会话缺失同一 404 正文,
// 不暴露他人会话存在;admin 可开任一)。升级前先 Ensure 显示栈(失败 503 不升级)。
func (s *Server) handleVNC(w http.ResponseWriter, r *http.Request) {
	sess := s.table.Get(r.URL.Query().Get("sessionId"))
	if sess == nil {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	key, _ := r.Context().Value(keyCtx).(Key)
	if key.Role != RoleAdmin && sess.KeyID != key.ID {
		jsonWrite(w, 404, map[string]any{"error": "无此会话"})
		return
	}
	st, err := s.vnc.Ensure(sess)
	if err != nil {
		if s.log != nil {
			s.log.Warn("vnc_ensure_fail", "cat", "audit", "session_id", sess.ID, "err", err.Error())
		}
		jsonWrite(w, 503, map[string]any{"error": "display_unavailable"})
		return
	}
	if s.log != nil {
		s.log.Info("vnc_bridge", "cat", "audit", "action", "vnc/connect",
			"session_id", sess.ID, "key_id", key.ID, "slot", st.slot)
	}
	_ = st.Bridge(sess, w, r, s.log) // 阻塞到桥结束;帧内容永不落日志(里面是按键)
}

// Package backend 是三家 agent 的静态注册表:claude 与 codex 走 npm 适配器,pi 原生直连。
// 表不是插件目录;每行定 name/kind/argv/env 与 initialize 要广告的 clientCapabilities。
package backend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Kind 只有两值:adapter(npm 适配器拉 CLI)与 native(pi-rs 自带 ACP Agent 侧)。
type Kind string

const (
	KindAdapter Kind = "adapter"
	KindNative  Kind = "native"
)

// Def 是注册表一行。
type Def struct {
	Name     string
	Kind     Kind
	Pkg      string   // adapter:npm 包名(bin 从其 package.json 解析)
	Argv     []string // native:完整 argv;adapter:由 Resolve 拼出
	Env      []string // KEY=VALUE,逐条注入子进程
	FS       bool     // initialize 的 clientCapabilities.fs
	Terminal bool     // initialize 的 clientCapabilities.terminal
}

// Registry 返回三行,顺序即 /health 的 agents 顺序;pi 的就绪是运行期判定。
// pi 模型面默认走 overcast 网关(pi-rs-core 5b63ec3):PI_GATEWAY_BASE_URL 未设即网关,
// 凭证任意非空即过(关鉴权期 canon overcast);走官方 API 时 spawn env 覆盖 PI_GATEWAY_BASE_URL=off。
// --approve 统一信任项目本地件(2026-10-14 契约②:pi install 扩展或 .pi-rs/settings.json
// 出现后,无 UI 的 ACP 重启会静默不加载项目面;平台持久区 /srv/work 语义下信任合理)。
func Registry() []Def {
	return []Def{
		{Name: "claude", Kind: KindAdapter, Pkg: "claude-agent-acp", Env: []string{"DISABLE_UPDATES=1", "BROWSE_CHROME=/opt/clean-chrome/CURRENT/chrome"}, FS: true, Terminal: true},
		{Name: "codex", Kind: KindAdapter, Pkg: "codex-acp", Env: []string{"CODEX_PATH=/usr/local/bin/codex", "NO_BROWSER=1", "BROWSE_CHROME=/opt/clean-chrome/CURRENT/chrome"}, FS: true, Terminal: true},
		{Name: "pi", Kind: KindNative, Argv: []string{"/usr/local/bin/pi-rs", "--approve", "--mode", "acp"},
			Env: []string{
				"DEEPSEEK_API_KEY=overcast",
				"BROWSE_CHROME=/opt/clean-chrome/CURRENT/chrome",
				// 模型烤库指路(core 对抗 review F1):缺则 pi-rs 首用向 agent 目录重下 610M(离线坏)
				"ZVEC_GREP_MODEL_CACHE=/opt/zg-models",
				"PI_OCR_CACHE_DIR=/opt/pi-ocr-models",
				// 词表指路(F2 面的 runtime 侧注记:04836e8 后随包发行,外部预置仍赢)
				"ZVEC_JIEBA_DICT_DIR=/usr/local/share/zvec/jieba_dict",
				// 桌面过渡形(needface v2 §五):有 DISPLAY 则 agent chrome headed 上屏;正道=会师批 BROWSE_CDP_WS
				"DISPLAY=:99",
			}, FS: false, Terminal: false},
	}
}

// Resolve 拼出子进程 argv:adapter 是 node + 包 bin 入口,native 原样返回。
func (d Def) Resolve() ([]string, error) {
	if d.Kind == KindNative {
		return d.Argv, nil
	}
	bin, err := BinFromPackageJSON(AdapterRoot(d.Pkg), d.Pkg)
	if err != nil {
		return nil, err
	}
	return append([]string{"node"}, bin), nil
}

// Find 按对外名取一行。
func Find(name string) (Def, bool) {
	for _, d := range Registry() {
		if d.Name == name {
			return d, true
		}
	}
	return Def{}, false
}

// AdapterRoot 是适配器包根;入口从各包 package.json 的 bin 字段解析,不写死文件名。
func AdapterRoot(pkg string) string {
	return filepath.Join("/opt/node/lib/node_modules/@agentclientprotocol", pkg)
}

// BinFromPackageJSON 读 package.json 的 bin 字段,返回入口脚本绝对路径。
// bin 是字符串直接用;是名到路径的映射时,先取与包名同名者,无则第一项。
func BinFromPackageJSON(modRoot, pkg string) (string, error) {
	b, err := os.ReadFile(filepath.Join(modRoot, "package.json"))
	if err != nil {
		return "", err
	}
	var pkgJSON struct {
		Bin json.RawMessage `json:"bin"`
	}
	if err := json.Unmarshal(b, &pkgJSON); err != nil {
		return "", err
	}
	if len(pkgJSON.Bin) == 0 {
		return "", errors.New("bin 字段缺席")
	}
	var binStr string
	if err := json.Unmarshal(pkgJSON.Bin, &binStr); err == nil {
		return filepath.Join(modRoot, binStr), nil
	}
	var binMap map[string]string
	if err := json.Unmarshal(pkgJSON.Bin, &binMap); err != nil {
		return "", fmt.Errorf("bin 字段形不支持: %w", err)
	}
	if p, ok := binMap[pkg]; ok {
		return filepath.Join(modRoot, p), nil
	}
	for _, p := range binMap {
		return filepath.Join(modRoot, p), nil
	}
	return "", errors.New("bin 映射为空")
}

// PiReady 检查 pi 后端就绪:二进制可执行,且 --help 在 5 秒内结束并提到 acp 模式。
// 不拉会话;不就绪的 err 文案区分缺二进制、超时/失败、模式未列三种。
func PiReady(argv []string) error {
	if len(argv) == 0 {
		return errors.New("pi: argv 为空")
	}
	bin := argv[0]
	if filepath.IsAbs(bin) {
		if fi, err := os.Stat(bin); err != nil || fi.IsDir() || fi.Mode()&0o111 == 0 {
			return fmt.Errorf("pi: 二进制缺席或不可执行: %s", bin)
		}
	} else if _, err := exec.LookPath(bin); err != nil {
		return fmt.Errorf("pi: 二进制缺席: %s", bin)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var out []byte
	out, err := exec.CommandContext(ctx, bin, "--help").Output()
	if ctx.Err() == context.DeadlineExceeded {
		return errors.New("pi: --help 5 秒未结束")
	}
	if err != nil {
		return fmt.Errorf("pi: --help 失败: %w", err)
	}
	if !strings.Contains(string(out), "acp") {
		return errors.New("pi: --help 未列 acp 模式")
	}
	return nil
}

# Go 安全工具集:go-security 组

> 17 件 Go 安全 CLI(fuzz/爆破/爬虫/密钥扫描/隧道/云与 AD 采集)+ trufflehog(release) ｜ 状态:已装 ｜ 组:`install-tools.sh go-security`

## 版本

- 解析日 2026-10-10。
- 17 件逐件取 `GO_PIN[<模块>]`。
- 取值函数是 `go_pin_ver`。
- 缺少锁定版本时,`go_pin_ver` 向 stderr 打印错误并返回 1,循环跳过该件。
- 不允许回退到 `@latest`。
- 旧变量 `SECGO_VERSION` 已不再使用。`lib/common.sh` 仍保留它,避免空引用。
- trufflehog 使用 release 标量 `TRUFFLEHOG_VERSION`,当前值 v3.99.2。见 [trufflehog.md](trufflehog.md)。
- `have` 命中只表示锁定版本第一次安装到的那份文件还在。
- 升级:执行 `scripts/resolve-pins.sh` 更换锁定版本,删除二进制,再执行本组。

## 来源与安装

- 各件上游就是成员清单里的模块路径。
- 组织包括 ffuf、OJ、hahwul、owasp-amass、jpillora、zricethezav、tomnomnom、lc、jaeles-project、sensepost、bloodhoundad、praetorian-inc。
- 脚本:`scripts/install-tools.sh` 的 `install_go-security`。
- 经 `GOPROXY=goproxy.cn,direct` 与 `GOSUMDB=sum.golang.google.cn`。这两项由 common.sh 导出。
- 环境变量 `SECGO_TOOLS` 可以整表替换清单。
- 替换格式是 `<path>@<repo 前缀>`。

## 文件

- 本组不设置 `GOPATH`。
- golang 组写入的 root go env 文件含 `GOPATH=/opt/go`。
- 脚本先读 `go env GOBIN`。为空时改用 `go env GOPATH` 加上 `/bin`。
- Go 1.27 下,这个实效目录是 `/opt/go/bin`。
- 产物落在 `/opt/go/bin`,再逐件 `ln -sf` 到 `/usr/local/bin`。
- 带版本目录的模块,产物名是版本号。例如 `ffuf/v2` 的产物名是 `v2`。
- 脚本执行 `mv $gobin/<产物> $gobin/<工具>`,改回工具名后再链接。
- `gobin` 按 `go env GOPATH`/bin 计算,不用 `$HOME/go/bin`。
- `GOPATH=/opt/go` 时,`$HOME/go/bin` 是错的路径,链接会悬空。
- 幂等判据看 `$gobin/<bin>` 文件,不看 PATH 上的 `have`。
- 非登录 shell 的 PATH 不含 `/opt/go/bin`。用 `have` 会得到假阴性,造成漏链或重复编译。
- 组尾再补一次链接:本体在 `$gobin` 而 `/usr/local/bin` 没有链时补上。
- amass 与 azurehound 属于会漏链的两件,由这次兜底补上。

## 配置

- 无组级配置。
- go 模块缓存共用 `/opt/go/pkg/mod`。见 [offline.md](../../offline.md)。

## 离线行为

- 支持版本面与帮助面。这些是纯 Go 静态二进制。
- 渗透工具面的断网规定见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`gitleaks version` 退 0。
- 未验证:gitleaks 扫描本地仓,以及 chisel 在内网两端互连。两者都只走本地或内网流量。
- 判定:断网后 `gitleaks git /opt/c2dev-ref/sliver` 能跑完并给出输出。
- 历史库、云 API、被动源在断网时失败,这是设计边界。包括 waybackurls、gau、azurehound、云枚举,以及 trufflehog 的 verify。见 [offline.md](../../offline.md)。

## 限制

- gospider、httprobe、assetfinder、waybackurls 仍由本组安装。
- gowitness 截图依赖无头 Chrome。镜像里目前没有。见 [known-issues.md](../../known-issues.md)。
- 定制 Chrome 待合入。
- trufflehog 的 replace 拒装、`sort -V`、零命中退 1 见 [trufflehog.md](trufflehog.md)。
- 单独重跑时,链接看 `$gobin/<bin>` 是否存在,不看 PATH。
- 组尾对已有本体补 `/usr/local/bin` 软链。
- 因此「编译成功但未链出」不再是本组的边界。

## 参见

- [trufflehog.md](trufflehog.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [golang.md](../compilers/golang.md)

## 成员清单

- 表头里的 `@$SECGO_VERSION` 是旧变量名。现行锁定是 `GO_PIN`。

| 命令 | go install 模块(@$SECGO_VERSION) | 用途 |
|---|---|---|
| ffuf | github.com/ffuf/ffuf/v2 | Web fuzz(产物名 v2,改名) |
| gobuster | github.com/OJ/gobuster/v3 | 目录/DNS/vhost 爆破(产物名 v3,改名) |
| dalfox | github.com/hahwul/dalfox/v2 | XSS 参数分析与扫描(产物名 v2,改名) |
| amass | github.com/owasp-amass/amass/v4/... | 攻击面测绘与子域枚举(`/...` 多包,产物名 amass) |
| chisel | github.com/jpillora/chisel | HTTP/WebSocket 隧道 |
| gitleaks | github.com/zricethezav/gitleaks/v8 | git 仓密钥扫描(产物名 v8,改名;与 trufflehog 互补) |
| assetfinder | github.com/tomnomnom/assetfinder | 子域与相关域发现 |
| httprobe | github.com/tomnomnom/httprobe | HTTP/HTTPS 探活 |
| qsreplace | github.com/tomnomnom/qsreplace | URL 查询参数值批量替换 |
| waybackurls | github.com/tomnomnom/waybackurls | Wayback 历史 URL |
| gau | github.com/lc/gau/v2/cmd/gau | 已知 URL 聚合 |
| gospider | github.com/jaeles-project/gospider | Web 爬虫 |
| gowitness | github.com/sensepost/gowitness | 网页截图(需 Chrome) |
| azurehound | github.com/bloodhoundad/azurehound/v2 | Azure 采集(BloodHound;产物名 v2,改名) |
| nerva | github.com/praetorian-inc/nerva/cmd/nerva | 服务指纹识别 |
| brutus | github.com/praetorian-inc/brutus/cmd/brutus | 协议口令爆破 |
| aurelian | github.com/praetorian-inc/aurelian | 云环境侦察 |
| trufflehog | 不经 go install(release 预编译) | git 历史与云密钥扫描,单册 [trufflehog.md](trufflehog.md) |

# Go 安全工具集(secgo 组)

> 17 件 Go 安全 CLI(fuzz/爆破/爬虫/密钥扫描/隧道/云与 AD 采集)+ trufflehog(release) ｜ 状态:已装 ｜ 组:`install-tools.sh secgo`

- **版本钉**:pins.sh 钉版(解析日 2026-10-10):17 件逐件取 `GO_PIN[<模块>]`(`go_pin_ver`,缺钉即响跳过;旧 `SECGO_VERSION` 变量已弃用,lib/common.sh 仅保留防空引用);trufflehog 走 release 钉标量 `TRUFFLEHOG_VERSION`(当前钉值 v3.99.2),单册 [trufflehog.md](trufflehog.md);`have` 早退意味着「钉版首次装到的那份」,升级跑 scripts/resolve-pins.sh 换钉后删二进制重跑
- **来源与安装**:各件上游仓即成员表模块路径(ffuf/OJ/hahwul/owasp-amass/jpillora/zricethezav/tomnomnom/lc/jaeles-project/sensepost/bloodhoundad/praetorian-inc);安装面 `scripts/install-tools.sh` `install_secgo`;经 `GOPROXY=goproxy.cn,direct` + `GOSUMDB=sum.golang.google.cn`(common.sh export);清单可用 `SECGO_TOOLS` 环境变量整表替换(规格格式 `<path>@<repo 前缀>`)
- **落点**(批量机制):本组不显式设 GOPATH——golang 组写的 root go env 文件(`GOPATH=/opt/go`)使 `go env GOBIN` 实效为 `/opt/go/bin`(go 1.27 实证),产物落 /opt/go/bin 并逐件 `ln -sf` 到 `/usr/local/bin`;带版本目录的模块产物名是版本号(`ffuf/v2` → `v2`),脚本 `mv $gobin/<产物> $gobin/<工具>` 改名回工具名再链
- **配置与缓存**(批量机制):无组级配置;go 模块缓存共用 `/opt/go/pkg/mod`(见 [offline.md](../../offline.md) §1)
- **离线行为**:✅ 版本面/帮助面断网可用(纯 Go 静态二进制;渗透工具面断网冒烟口径见 [offline.md](../../offline.md) §验证)。验证:`ip link set eth0 down` 后 `gitleaks version` 退 0。☐ [推断:] gitleaks 扫本地仓、chisel 内网两端互连断网可用(纯本地/内网流量);验证:断网后 `gitleaks git /opt/c2dev-ref/sliver` 能跑完出输出。✅ 边界:历史库/云 API/被动源类动作(waybackurls、gau、azurehound、云枚举、trufflehog verify)断网失败属设计,同 [offline.md](../../offline.md) §边界实证口径
- **坑与留痕**:gospider/httprobe/assetfinder/waybackurls 曾被评审建议移除,用户裁定保留([ADR-0006](../../adr/ADR-0006-user-rulings-log.md));gowitness 截图依赖无头 Chrome,镜像暂无([known-issues](../../known-issues.md),定制 Chrome 待合入);trufflehog 的三只坑(replace 拒装/sort -V/零命中退 1)见 [trufflehog.md](trufflehog.md);[推断:] 本组 PATH 只加 `/usr/local/go/bin` 与 `/root/go/bin`,`/opt/go/bin` 靠同批先跑的 cli/pd 组导出(全量顺序 cli→pd→secgo)——单独重跑本组装新件时可能「编译成功但未链出」,补法 `ln -sf /opt/go/bin/<bin> /usr/local/bin/` 或与 cli/pd 同跑

## 成员表(18)

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

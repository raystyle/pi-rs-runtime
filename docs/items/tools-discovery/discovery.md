# ProjectDiscovery 全家桶:discovery 组

> 攻击面测绘与侦察 20 件 Go CLI 集(子域/DNS/端口/HTTP/模板扫描/爬虫/云资产) ｜ 状态:已装 ｜ 组:`install-tools.sh discovery`

## 版本

- 解析日 2026-10-10;20 件逐件取 `GO_PIN[github.com/projectdiscovery/<模块>]`;取值函数是 `go_pin_ver`;缺少锁定版本时,`go_pin_ver` 向 stderr 打印错误并返回 1,循环跳过该件;不允许回退到 `@latest`;旧变量 `PD_VERSION` 已不再使用。`lib/common.sh` 仍保留它,避免空引用;`have` 命中只表示锁定版本第一次安装到的那份文件还在;升级:执行 `scripts/resolve-pins.sh` 更换锁定版本,删除二进制,再执行本组。

## 来源与安装

- 上游站:[projectdiscovery.io](https://projectdiscovery.io)。
- 各件仓库在 `github.com/projectdiscovery` 组织下。模块路径见成员清单;脚本:`scripts/install-tools.sh` 的 `install_discovery`。
- 经 `GOPROXY=goproxy.cn,direct` 与 `GOSUMDB=sum.golang.google.cn`。这两项由 common.sh 导出。
- 环境变量 `PD_TOOLS` 可以整表替换清单;未设置时使用 `PD_TOOLS_DEFAULT`,共 20 件;单件编译失败不中断本批。脚本打印 `!! <bin> 编译失败(留待排查)`;对账以组尾「已装 PD 工具」清单为准。

## 文件

- 本组显式 `export GOPATH=/opt/go`。
- 产物在 `/opt/go/bin/<bin>`,再逐件 `ln -sf` 到 `/usr/local/bin/<bin>`。
- 二进制名取模块路径的最后一段;`chaos-client/cmd/chaos` 的二进制名是 `chaos`。
- `interactsh/cmd/interactsh-client` 的二进制名是 `interactsh-client`。
- naabu 另外安装 `libpcap-dev`。
- naabu 执行 `setcap cap_net_raw,cap_net_admin+eip`,SYN 扫描不必 sudo。
- ubuntu 用户因此可以跑 naabu 的 SYN 扫描;幂等判据看 `$GOPATH/bin/<bin>` 文件,不看 PATH 上的 `have`;跳过安装的分支也会补上链接;直装产物不经过组循环时,这个补链避免漏链。cvemap 属于这种情况。

## 配置

- 无组级配置文件;go 模块缓存共用 `/opt/go/pkg/mod`。
- 运行期 `GOPROXY=off` 的默认见 [offline.md](../../offline.md)。
- nuclei 的模板缓存与 wrapper 不在本组。那是 pentest 组的离线接线。见 [nuclei.md](nuclei.md)。

## 离线行为

- 支持版本面与帮助面。这些是纯 Go 静态二进制,没有自更新;渗透工具面的断网规定见 [offline.md](../../offline.md);关闭 eth0 后,`httpx -version` 退 0。
- 外网型动作在断网时失败,这是设计边界:subfinder 的被动源,以及 uncover、cloudlist、chaos、cvemap 的云端 API。见 [offline.md](../../offline.md)。
- 未验证:对本地或内网目标的扫描,包括 naabu、httpx、katana、dnsx。
- 判定:断网后 `python3 -m http.server 8000` 起本地服务,再执行 `httpx -u http://127.0.0.1:8000 -silent`,有输出即可。

## 限制

- 名称 `httpx` 与 Python 包相撞。redteam 组 venv 里的依赖 CLI 会盖住本组的 Go httpx。
- 当前用白名单链接,并清理残留,把 `/opt/go/bin/httpx` 链回 `/usr/local/bin`。
- 这段逻辑在 `install-tools.sh` 的 redteam 段;nuclei 的模板放在 `/opt`,`-duc` wrapper 属于 pentest 组的安装顺序;只重跑 discovery 组不会重建该 wrapper。

## 参见

- [nuclei.md](nuclei.md)
- [offline.md](../../offline.md)
- [tools.md](../../install-surfaces/tools.md)

## 成员清单

- 表头里的 `@$PD_VERSION` 是旧变量名。现行锁定是 `GO_PIN`。

| 命令 | go install 模块(前缀 `github.com/projectdiscovery/`,@$PD_VERSION) | 用途 |
|---|---|---|
| subfinder | subfinder/v2/cmd/subfinder | 子域名被动发现 |
| dnsx | dnsx/cmd/dnsx | DNS 探测/解析工具包 |
| naabu | naabu/v2/cmd/naabu | 端口扫描(SYN;libpcap + setcap) |
| httpx | httpx/cmd/httpx | HTTP 探活与指纹 |
| nuclei | nuclei/v3/cmd/nuclei | 模板化漏洞扫描,单册 [nuclei.md](nuclei.md) |
| katana | katana/cmd/katana | Web 爬虫 |
| uncover | uncover/cmd/uncover | 暴露资产聚合(Shodan/Censys 等 API) |
| cloudlist | cloudlist/cmd/cloudlist | 多云资产枚举 |
| notify | notify/cmd/notify | 扫描结果通知推送 |
| interactsh-client | interactsh/cmd/interactsh-client | OOB 外带交互客户端 |
| chaos | chaos-client/cmd/chaos | Chaos DNS 数据集客户端(二进制名 chaos) |
| mapcidr | mapcidr/cmd/mapcidr | CIDR 切分/聚合 |
| asnmap | asnmap/cmd/asnmap | ASN 与 CIDR 互查映射 |
| tlsx | tlsx/cmd/tlsx | TLS 配置分析 |
| proxify | proxify/cmd/proxify | 抓包代理 |
| simplehttpserver | simplehttpserver/cmd/simplehttpserver | 简易 HTTP(S) 文件服务 |
| shuffledns | shuffledns/cmd/shuffledns | 子域名爆破(massdns 包装) |
| pdtm | pdtm/cmd/pdtm | PD 工具包管理器 |
| urlfinder | urlfinder/cmd/urlfinder | 被动 URL 发现 |
| cvemap | cvemap/cmd/cvemap | CVE 数据库导航 |

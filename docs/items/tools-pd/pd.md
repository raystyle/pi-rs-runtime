# ProjectDiscovery 全家桶(pd 组)

> 攻击面测绘与侦察 20 件 Go CLI 集(子域/DNS/端口/HTTP/模板扫描/爬虫/云资产) ｜ 状态:已装 ｜ 组:`install-tools.sh pd`

- **版本钉**:全部 `go install github.com/projectdiscovery/<模块>@${PD_VERSION}`,`PD_VERSION` 默认 `latest`(lib/common.sh);`have` 早退意味着「首次装到的那份」,升级要删二进制重跑([known-issues](../../known-issues.md) 未钉登记)
- **来源与安装**:[projectdiscovery.io](https://projectdiscovery.io)(各件仓在 github.com/projectdiscovery 组织下,成员表列模块路径);安装面 `scripts/install-tools.sh` `install_pd`;经 `GOPROXY=goproxy.cn,direct` + `GOSUMDB=sum.golang.google.cn`(common.sh export);清单可用 `PD_TOOLS` 环境变量整表替换(默认 `PD_TOOLS_DEFAULT` 20 件)
- **落点**(批量机制):组内显式 `export GOPATH=/opt/go`,产物落 `/opt/go/bin/<bin>` 并逐件 `ln -sf` 到 `/usr/local/bin/<bin>`;二进制名取模块路径末段(`chaos-client/cmd/chaos` → `chaos`,`interactsh/cmd/interactsh-client` → `interactsh-client`);naabu 另装 `libpcap-dev` 并 `setcap cap_net_raw,cap_net_admin+eip`(SYN 扫描免 sudo,ubuntu 视角可跑)
- **配置与缓存**(批量机制):无组级配置文件;go 模块缓存共用 `/opt/go/pkg/mod`,运行期 `GOPROXY=off` 默认见 [offline.md](../../offline.md) §1/§4;nuclei 模板缓存与 wrapper 不在本组——是 pentest 组的离线接线,见 [nuclei.md](nuclei.md)
- **离线行为**:✅ 版本面/帮助面断网可用(纯 Go 静态二进制、无自更新;渗透工具面断网冒烟口径见 [offline.md](../../offline.md) §验证)。验证:`ip link set eth0 down` 后 `httpx -version` 退 0。✅ 外网型动作(subfinder 被动源、uncover/cloudlist/chaos/cvemap 云端 API)断网失败属设计边界([offline.md](../../offline.md) §边界实证口径)。☐ [推断:] 对本地/内网目标的扫描(naabu/httpx/katana/dnsx)断网可用;验证:断网后 `python3 -m http.server 8000` 起本地服务,`httpx -u http://127.0.0.1:8000 -silent` 有输出
- **坑与留痕**:python httpx 撞名案——red 组 venv 依赖 CLI 曾盖掉本组 Go httpx,已改白名单链接+残留清理并把 `/opt/go/bin/httpx` 还回(install-tools.sh red 段;[ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md));单件编译失败不阻断批(`echo "!! <bin> 编译失败(留待排查)"`),对账以组尾「已装 PD 工具」清单为准;nuclei 的模板钉 /opt 与 `-duc` wrapper 属 pentest 组装机序,单独重跑 pd 组不会重建 wrapper

## 成员表(20)

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
| asnmap | asnmap/cmd/asnmap | ASN↔CIDR 映射 |
| tlsx | tlsx/cmd/tlsx | TLS 配置分析 |
| proxify | proxify/cmd/proxify | 抓包代理 |
| simplehttpserver | simplehttpserver/cmd/simplehttpserver | 简易 HTTP(S) 文件服务 |
| shuffledns | shuffledns/cmd/shuffledns | 子域名爆破(massdns 包装) |
| pdtm | pdtm/cmd/pdtm | PD 工具包管理器 |
| urlfinder | urlfinder/cmd/urlfinder | 被动 URL 发现 |
| cvemap | cvemap/cmd/cvemap | CVE 数据库导航 |

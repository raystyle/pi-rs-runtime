# dataref:数据信息资产

> PoC、规则与指纹库的克隆。kind=data。构建日快照,离线直读;LOLBAS/webappanalyzer/gtfobins/hacktricks 按 2026-10-14 瘦身批 不烤镜像(后续走 MCP),只余 exploitdb(poc-search --deep 与 searchsploit 的在役依赖) ｜ 状态:已装 ｜ 组:`install-tools.sh data`

## 版本

- pins.sh 的 `GIT_PIN` 锁定 LOLBAS、webappanalyzer、exploit-db。
- 解析日 2026-10-11;升级:执行 `scripts/resolve-pins.sh`,审阅差异,再执行本组;快照在构建日冻结;与 trivy-db 同一规定。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_data`。
- LOLBAS 与 enthec/webappanalyzer 经 GitHub,使用 `clone_pin`。
- exploit-db 经 GitLab 直连。
- 地址是 `https://gitlab.com/exploit-database/exploitdb.git`。
- `GITHUB_MIRROR` 不代理 GitLab;直连可以到达;GTFOBins 使用 `.github.io` 网页源仓;主仓经代理返回 403;`_gtfobins/` 共 478 条,是全量。

## 文件

- `/opt/data-ref/LOLBAS`:Windows 滥用基线。
- `/opt/data-ref/webappanalyzer`:Web 指纹库,Wappalyzer 社区维护版。
- `/opt/data-ref/exploitdb`:Exploit-DB 全文,以及 `files_exploits.csv` 索引。
- `/opt/data-ref/hacktricks`:HackTricks 文本面。浅克隆。去掉 `.git` 与配图,只留 md。
- `/opt/data-ref/gtfobins`:Unix 二进制滥用基线。

## 配置

- 无配置文件;纯数据,直接读取。
- 与 poc-search 互补。见 [poc-search.md](../tools-recon/poc-search.md)。
- poc-search 是 PoC-in-GitHub 索引;本目录的 exploitdb 是 Exploit-DB 全文。

## 离线行为

- 支持。本地直读,不访问网络;新鲜度等于构建日快照;要新数据时,在有网环境重跑本组。

## 限制

- exploit-db 不含 bin-sploits;那是 1GB 级二进制包;2022 之后没有更新;判定不装;searchsploit 的入口以仓库直读为准;`rctl search` 可以搜到这份数据;perl 包装没有接上;NVD 与 cvelist 的全量约 2.9GiB;这两份判定不装;HackTricks 以 18M 文本进入;图片与 `.git` 不进入。

## 参见

- [poc-search.md](../tools-recon/poc-search.md)
- [offline.md](../../offline.md)
- [params.md](../../params.md)

## rctl 收录行

- rctl: LOLBAS kind=data path=/opt/data-ref/LOLBAS note=Windows 滥用基线库
- rctl: webappanalyzer kind=data path=/opt/data-ref/webappanalyzer note=Web 指纹库
- rctl: exploitdb kind=data path=/opt/data-ref/exploitdb note=Exploit-DB 快照(PoC 全文+csv 索引)
- rctl: hacktricks kind=data path=/opt/data-ref/hacktricks note=HackTricks 文本面(1095 篇 md 约 18M,剔 .git 与配图,2026-10-11 )
- rctl: gtfobins kind=data path=/opt/data-ref/gtfobins note=Unix 二进制滥用基线(478 条,走 .github.io 源仓道)

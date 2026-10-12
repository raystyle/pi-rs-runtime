# dataref:数据信息资产

> PoC/规则/指纹库的克隆面(kind=data,构建日快照,离线直读)｜ 状态:已装 ｜ 组:`install-tools.sh data`

- **版本钉**:pins.sh `GIT_PIN`(LOLBAS、webappanalyzer、exploit-db;解析日 2026-10-11);升级跑 resolve-pins.sh 审 diff 重跑本组;快照随构建日冻结(trivy-db 同规定)
- **来源与安装**:LOLBAS 与 enthec/webappanalyzer 走 GitHub(clone_pin);exploit-db 走 **GitLab 直连**(https://gitlab.com/exploit-database/exploitdb.git,GITHUB_MIRROR 不代理 GitLab,直连可达);GTFOBins 走 .github.io 网页源仓(主仓被代理 403,2026-10-11 用户给出源仓道;_gtfobins/ 478 条全量);装面 `scripts/install-tools.sh install_data`
- **落点**:`/opt/data-ref/LOLBAS`(Windows 滥用基线)、`/opt/data-ref/webappanalyzer`(Web 指纹库,Wappalyzer 社区维护版)、`/opt/data-ref/exploitdb`(Exploit-DB 全文 + files_exploits.csv 索引)、`/opt/data-ref/hacktricks`(HackTricks 文本面,浅克隆剔 .git/配图只留 md)
- **配置与缓存**:纯数据直读,无配置;与 poc-search(PoC-in-GitHub 索引)互补:一面 GitHub PoC 索引,一面 Exploit-DB 全文
- **离线行为**:过,本地直读零网络;新鲜度=构建日快照,要新数据回有网重跑本组
- **限制**:exploit-db 不含 bin-sploits(1GB 级二进制包,2022 后无更新,判定不装);searchsploit 入口以仓直读+rctl 可搜为准(perl 包装面未接);NVD/cvelist 全量(约 2.9GiB)判不装;HackTricks 以 18M 文本面进(2026-10-11,图与 .git 不进)

- rctl: LOLBAS kind=data path=/opt/data-ref/LOLBAS note=Windows 滥用基线库
- rctl: webappanalyzer kind=data path=/opt/data-ref/webappanalyzer note=Web 指纹库
- rctl: exploitdb kind=data path=/opt/data-ref/exploitdb note=Exploit-DB 快照(PoC 全文+csv 索引)
- rctl: hacktricks kind=data path=/opt/data-ref/hacktricks note=HackTricks 文本面(1095 篇 md 约 18M,剔 .git 与配图,2026-10-11 )
- rctl: gtfobins kind=data path=/opt/data-ref/gtfobins note=Unix 二进制滥用基线(478 条,走 .github.io 源仓道)


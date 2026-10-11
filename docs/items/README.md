# 逐件索引(docs/items/)

每件一册,模板见 [TEMPLATE.md](TEMPLATE.md)。目录按脚本分组。件级事实(版本/来源/落点/离线行为/坑)的唯一真相在这里;`install-surfaces/` 只留组机制导览,`software-inventory.md` 只留计数对账。

粒度规则:有独立版本钉/wrapper/缓存/离线行为/坑的件单独成册;同质批量件(apt 批、pd/secgo CLI 集、参考克隆批)由组册承载批量机制与成员表,成员不单独立册。

## compilers(install-compilers.sh,6 册)

[c-toolchain](compilers/c-toolchain.md)(含 build-essential 21 包+FASM)· [golang](compilers/golang.md) · [rust](compilers/rust.md) · [zig](compilers/zig.md) · [nim](compilers/nim.md) · [vcpkg](compilers/vcpkg.md)

## runtimes(install-runtimes.sh,16 册)

[node](runtimes/node.md) · [fnm](runtimes/fnm.md) · [bun](runtimes/bun.md) · [uv](runtimes/uv.md) · [python](runtimes/python.md) · [python2](runtimes/python2.md) · [duckdb](runtimes/duckdb.md) · [clickhouse](runtimes/clickhouse.md) · [php](runtimes/php.md) · [mono](runtimes/mono.md) · [dotnet](runtimes/dotnet.md) · [pwsh](runtimes/pwsh.md) · [sdkman](runtimes/sdkman.md) · [java-jdks](runtimes/java-jdks.md) · [maven](runtimes/maven.md) · [gradle](runtimes/gradle.md)

## libcache(install-libcache.sh,8 册)

[go](libcache/go.md) · [rust](libcache/rust.md) · [python](libcache/python.md) · [node](libcache/node.md) · [java](libcache/java.md) · [pwsh](libcache/pwsh.md) · [dotnet](libcache/dotnet.md) · [zig](libcache/zig.md)

## 归档域视图(七域定稿,grok prt-09;目录=安装组,域=归档架子,两面并存)

| 域 | 判据(这只 id 被拿来干什么) | 例 |
|---|---|---|
| 工具环境 | 对目标或实例本身下命令的入口,不属下列专域 | nmap、herdr、aliyun、rctl、agents、vnc、vol、poc-search |
| 运行时环境 | 跑通用代码的宿主 | python、node、JVM、dotnet |
| 编程环境 | 为写和编译而固化的工具链与库字节 | rustc、go 模块缓存、capstone 库 |
| 逆向环境 | 拆、调、模拟、反编译二进制的入口 | ghidra、rizin、rea、jadx、frida、floss、ilspycmd |
| 数据信息搜索 | 被查的语料:词表、模板、规则、PoC/漏洞索引 | SecLists、nuclei-templates、exploitdb、LOLBAS |
| 数据分析 | 对表或列做计算的引擎与其专用 venv | duckdb、clickhouse、nu、analytics-venv |
| 代码样板参考 | 只克隆供读和改,不作已安装入口 | c2/maldev/pz 参考克隆、ysoserial 源码 |

映射规则:`gen-rctl-catalog.sh` env_of(id 名单 + 组默认 + kind=data 到数据信息搜索/ref 到代码样板参考 + 机器行 env= 覆盖);活视图 `rctl --env <域>`、面板七域计数。kind 与域是两个面(clickhouse:kind=runtime,域=数据分析,非双归)。

## tools(install-tools.sh,48 册)

| 组 | 册 |
|---|---|
| fd | [fd](tools-fd/fd.md) |
| astgrep | [astgrep](tools-astgrep/astgrep.md) |
| cli | [cli](tools-cli/cli.md)(组册 15 件) |
| herdr | [herdr](tools-herdr/herdr.md) |
| ghidra | [ghidra](tools-ghidra/ghidra.md) |
| rea | [rea](tools-rea/rea.md)(morluto/rea,MCP+CLI,Ghidra 无头 provider) |
| re | [re](tools-re/re.md)(组册:系统库 22 项+rizin/rz-ghidra/sigdb+re-venv) |
| pd | [pd](tools-pd/pd.md)(组册 20 CLI)· [nuclei](tools-pd/nuclei.md) |
| secgo | [secgo](tools-secgo/secgo.md)(组册 18 CLI)· [trufflehog](tools-secgo/trufflehog.md) |
| secrust | [secrust](tools-secrust/secrust.md)(组册 3 件) |
| pivot | [pivot](tools-pivot/pivot.md)(组册 6 件) |
| p0 | [p0](tools-p0/p0.md)(组册 apt 20 包) · [nasm](tools-p0/nasm.md) · [impacket](tools-p0/impacket.md) · [apktool](tools-p0/apktool.md) · [capa](tools-p0/capa.md) · [pwndbg](tools-p0/pwndbg.md) · [jadx](tools-p0/jadx.md) |
| c2 | [c2](tools-c2/c2.md)(组册 7 仓参考) |
| bof | [bof](tools-bof/bof.md)(组册) · [wine](tools-bof/wine.md) · [bof-launcher](tools-bof/bof-launcher.md) · [coffee-ldr](tools-bof/coffee-ldr.md) |
| pz | [pz](tools-pz/pz.md)(组册 4 仓) |
| maldev | [maldev](tools-maldev/maldev.md)(组册 41 仓+2 官网 tgz) |
| recon | [recon](tools-recon/recon.md)(组册 4 仓) · [poc-search](tools-recon/poc-search.md) |
| nu | [nu](tools-nu/nu.md) |
| pentest | [pentest](tools-pentest/pentest.md)(组册 36 apt 包+接线) · [hashcat](tools-pentest/hashcat.md) · [responder](tools-pentest/responder.md) · [donut](tools-pentest/donut.md) · [frida](tools-pentest/frida.md) |
| red | [red](tools-red/red.md)(组册 24 件) · [bloodhound-ce](tools-red/bloodhound-ce.md) · [enum4linux-ng](tools-red/enum4linux-ng.md) · [evil-winrm](tools-red/evil-winrm.md) · [cyberchef](tools-red/cyberchef.md) · [trivy](tools-red/trivy.md) |
| msf | [msf](tools-msf/msf.md) |
| vnc | [vnc](tools-vnc/vnc.md)(XFCE+TigerVNC+noVNC 桌面与 Web 面) |
| ctl | [rctl](tools-ctl/rctl.md)(核心 CLI:实例总控,渐进索引与全资源可搜) |
| agents | [claude-code](tools-agents/claude-code.md) · [codex](tools-agents/codex.md)(agent CLIs,凭证经挂载不进镜像) |
| cloud | [cloud](tools-cloud/cloud.md)(云 CLI:aliyun+tccli,凭证使用期注入) |
| data | [dataref](tools-data/dataref.md)(数据信息资产:LOLBAS/webappanalyzer/exploit-db 快照) |
| acp | [acp](tools-acp/acp.md)(ACP v1+stdio 通道:适配器+监督进程 acpsup,REQ-0002) |
| chrome | [clean-chrome](tools-chrome/clean-chrome.md)(定制 Chromium 155,云端道+sha256 锚) |

计数对账:compilers 6 / runtimes 16 / libcache 8 / tools 50 = 80 册;组册承载的批量件数见各组册成员表(组册成员数 = 脚本实装件数)。

返回 [docs 文档地图](../README.md)。

# 逐件索引(docs/items/)

每件一册,模板见 [TEMPLATE.md](TEMPLATE.md)。目录按脚本分组。件级事实(版本/来源/落点/离线行为/坑)的唯一真相在这里;`install-surfaces/` 只留组机制导览,`software-inventory.md` 只留计数对账。

粒度规则:有独立版本钉/wrapper/缓存/离线行为/坑的件单独成册;同质批量件(apt 批、pd/secgo CLI 集、参考克隆批)由组册承载批量机制与成员表,成员不单独立册。

## compilers(install-compilers.sh,6 册)

[c-toolchain](compilers/c-toolchain.md)(含 build-essential 21 包+FASM)· [golang](compilers/golang.md) · [rust](compilers/rust.md) · [zig](compilers/zig.md) · [nim](compilers/nim.md) · [vcpkg](compilers/vcpkg.md)

## runtimes(install-runtimes.sh,16 册)

[node](runtimes/node.md) · [fnm](runtimes/fnm.md) · [bun](runtimes/bun.md) · [uv](runtimes/uv.md) · [python](runtimes/python.md) · [python2](runtimes/python2.md) · [duckdb](runtimes/duckdb.md) · [clickhouse](runtimes/clickhouse.md) · [php](runtimes/php.md) · [mono](runtimes/mono.md) · [dotnet](runtimes/dotnet.md) · [pwsh](runtimes/pwsh.md) · [sdkman](runtimes/sdkman.md) · [java-jdks](runtimes/java-jdks.md) · [maven](runtimes/maven.md) · [gradle](runtimes/gradle.md)

## libcache(install-libcache.sh,8 册)

[go](libcache/go.md) · [rust](libcache/rust.md) · [python](libcache/python.md) · [node](libcache/node.md) · [java](libcache/java.md) · [pwsh](libcache/pwsh.md) · [dotnet](libcache/dotnet.md) · [zig](libcache/zig.md)

## tools(install-tools.sh,41 册)

| 组 | 册 |
|---|---|
| fd | [fd](tools-fd/fd.md) |
| astgrep | [astgrep](tools-astgrep/astgrep.md) |
| cli | [cli](tools-cli/cli.md)(组册 15 件) |
| herdr | [herdr](tools-herdr/herdr.md) |
| ghidra | [ghidra](tools-ghidra/ghidra.md) |
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

计数对账:compilers 6 / runtimes 16 / libcache 8 / tools 42 = 72 册;组册承载的批量件数见各组册成员表(组册成员数 = 脚本实装件数)。

返回 [docs 文档地图](../README.md)。

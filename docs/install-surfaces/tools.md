# 安装面清单 · 工具（`install-tools.sh`）

组列中文名与脚本键对照：文件与内容搜索=`fd`、结构化代码搜索=`astgrep`、基础命令行工具=`cli`、终端工作区管理器=`herdr`、逆向分析套件=`ghidra`、逆向分析稳定链=`re`、攻击面测绘工具集=`pd`、Go 安全工具集=`secgo`、Rust 安全工具集=`secrust`、代理与隧道工具集=`pivot`、安全分析工具集=`p0`、命令与控制框架参考=`c2`、信标对象文件工具链=`bof`、Project Zero 工具参考=`pz`、恶意开发模板库=`maldev`、侦察指纹参考=`recon`、结构化 Shell=`nu`、渗透测试运行时底线=`pentest`、渗透测试工具增补=`red`。返回 [安装面清单索引](index.md)。

## 组目录

- [文件与内容搜索（fd）](#文件与内容搜索fd)
- [结构化代码搜索（astgrep）](#结构化代码搜索astgrep)
- [基础命令行工具（cli）](#基础命令行工具cli)
- [终端工作区管理器（herdr）](#终端工作区管理器herdr)
- [逆向分析套件（ghidra）](#逆向分析套件ghidra)
- [逆向分析稳定链（re）](#逆向分析稳定链re)
- [攻击面测绘工具集（pd）](#攻击面测绘工具集pd)
- [Go 安全工具集（secgo）](#go-安全工具集secgo)
- [Rust 安全工具集（secrust）](#rust-安全工具集secrust)
- [代理与隧道工具集（pivot）](#代理与隧道工具集pivot)
- [安全分析工具集（p0）](#安全分析工具集p0)
- [命令与控制框架参考（c2）](#命令与控制框架参考c2)
- [信标对象文件工具链（bof）](#信标对象文件工具链bof)
- [Project Zero 工具参考（pz）](#project-zero-工具参考pz)
- [恶意开发模板库（maldev）](#恶意开发模板库maldev)
- [侦察指纹参考（recon）](#侦察指纹参考recon)
- [结构化 Shell（nu）](#结构化-shellnu)
- [渗透测试运行时底线（pentest）](#渗透测试运行时底线pentest)
- [渗透测试工具增补（red）](#渗透测试工具增补red)

## 文件与内容搜索（`fd`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| fd、ripgrep | noble 随源 | [sharkdp/fd](https://github.com/sharkdp/fd)、[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)（Ubuntu 打包，tuna） |

```bash
# fd、ripgrep
apt-get install -y --no-install-recommends fd-find ripgrep
ln -sf /usr/bin/fdfind /usr/local/bin/fd
```

## 结构化代码搜索（`astgrep`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| ast-grep（`sg`） | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（crates 经 tuna） |

```bash
# ast-grep(sg)
cargo install ast-grep --locked
ln -sf /root/.cargo/bin/sg /usr/local/bin/sg
```

## 基础命令行工具（`cli`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| git、jq、shellcheck、just、tmux、rclone、aria2 | noble 随源 | git-scm.com、jqlang.github.io、shellcheck.net、just.systems、tmux、rclone.org、aria2.github.io（Ubuntu 打包，tuna） |
| yq | `go install` 未钉 | [mikefarah/yq](https://github.com/mikefarah/yq)（goproxy.cn） |
| gh（GitHub CLI） | `go install` 未钉 | [cli/cli](https://github.com/cli/cli)（goproxy.cn；官方 apt 源国内无镜像） |

```bash
# git、jq、shellcheck、just、tmux、rclone、aria2
apt-get install -y --no-install-recommends git jq shellcheck just tmux rclone aria2
# just 无 apt 包时兜底
cargo install just --locked
# yq
go install github.com/mikefarah/yq/v4@latest
ln -sf /opt/go/bin/yq /usr/local/bin/yq
# gh(GitHub CLI)
go install github.com/cli/cli/v2/cmd/gh@latest
ln -sf /opt/go/bin/gh /usr/local/bin/gh
```

## 终端工作区管理器（`herdr`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| herdr | 0.9.3（`HERDR_VERSION`），sha256 校验 | [herdr.dev](https://herdr.dev)（[herdrdev/herdr](https://github.com/herdrdev/herdr) release） |

```bash
# herdr:sha256 校验值取 HERDR_SHA256;aarch64 跳过校验
curl -fSL ${GITHUB_MIRROR}https://github.com/herdrdev/herdr/releases/download/v0.9.3/herdr-linux-x86_64
sha256sum -c
install -m755 /usr/local/bin/herdr
```

## 逆向分析套件（`ghidra`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| ghidra | 12.1.3（`GHIDRA_VERSION`/`GHIDRA_DATE`），sha256 校验 | [ghidra-sre.org](https://ghidra-sre.org)（[NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) release） |

```bash
# ghidra:launch.properties 写 JAVA_HOME_OVERRIDE=<temurin 21>;ghidraRun、analyzeHeadless 链到 /usr/local/bin
curl -fSL …/download/Ghidra_12.1.3_build/ghidra_12.1.3_PUBLIC_20260817.zip
sha256sum -c
unzip -d /opt/ghidra
```

## 逆向分析稳定链（`re`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| 系统库 22 项（binutils、elfutils、file、bsdmainutils、binwalk、yara、libyara-dev、libzip-dev、libpugixml-dev、libcapstone-dev、capstone-tool、meson、ninja-build、cmake、pkg-config、git、gcc、g++、python3、python3-pip、python3-venv、zlib1g-dev） | noble 随源 | 各项目官方站（Ubuntu 打包，tuna） |
| rizin | `--depth 1` 未钉 | [rizin.re](https://rizin.re)（[rizinorg/rizin](https://github.com/rizinorg/rizin)） |
| rz-ghidra | `--depth 1` 未钉（子模块钉 ghidra ref） | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra) |
| sigdb | `--depth 1` 未钉 | [rizinorg/sigdb](https://github.com/rizinorg/sigdb) |
| /opt/re-venv 五库（capstone、keystone-engine、unicorn、lief、yara-python） | 未钉 | PyPI（tuna） |

```bash
# 系统库 22 项
apt-get install -y --no-install-recommends binutils elfutils file bsdmainutils binwalk yara libyara-dev libzip-dev libpugixml-dev libcapstone-dev capstone-tool meson ninja-build cmake pkg-config git gcc g++ python3 python3-pip python3-venv zlib1g-dev
# rizin
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/rizinorg/rizin /tmp/rizin
meson setup build --buildtype=release
meson compile -C build && meson install -C build
# rz-ghidra
git clone --depth 1 --recurse-submodules --shallow-submodules …/rizinorg/rz-ghidra /tmp/rz-ghidra
cmake -DCMAKE_BUILD_TYPE=Release -DUSE_SYSTEM_PUGIXML=ON -DRIZIN_INSTALL_PLUGINDIR=$(rizin -qc 'e dir.plugins')
cmake --build && cmake --install
# sigdb
git clone --depth 1 …/rizinorg/sigdb /tmp/sigdb
meson setup build --prefix=/usr/local
meson install -C build
# /opt/re-venv 五库(capstone、keystone-engine、unicorn、lief、yara-python)
uv venv /opt/re-venv
VIRTUAL_ENV=/opt/re-venv uv pip install capstone keystone-engine unicorn lief yara-python
```

## 攻击面测绘工具集（`pd`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| subfinder | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/subfinder](https://github.com/projectdiscovery/subfinder)，goproxy.cn） |
| dnsx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/dnsx](https://github.com/projectdiscovery/dnsx)，goproxy.cn） |
| naabu | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/naabu](https://github.com/projectdiscovery/naabu)，goproxy.cn） |
| httpx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/httpx](https://github.com/projectdiscovery/httpx)，goproxy.cn） |
| nuclei | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei)，goproxy.cn） |
| katana | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/katana](https://github.com/projectdiscovery/katana)，goproxy.cn） |
| uncover | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/uncover](https://github.com/projectdiscovery/uncover)，goproxy.cn） |
| cloudlist | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/cloudlist](https://github.com/projectdiscovery/cloudlist)，goproxy.cn） |
| notify | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/notify](https://github.com/projectdiscovery/notify)，goproxy.cn） |
| interactsh-client | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/interactsh](https://github.com/projectdiscovery/interactsh)，goproxy.cn） |
| chaos | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/chaos-client](https://github.com/projectdiscovery/chaos-client)，goproxy.cn） |
| mapcidr | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/mapcidr](https://github.com/projectdiscovery/mapcidr)，goproxy.cn） |
| asnmap | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/asnmap](https://github.com/projectdiscovery/asnmap)，goproxy.cn） |
| tlsx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/tlsx](https://github.com/projectdiscovery/tlsx)，goproxy.cn） |
| proxify | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/proxify](https://github.com/projectdiscovery/proxify)，goproxy.cn） |
| simplehttpserver | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/simplehttpserver](https://github.com/projectdiscovery/simplehttpserver)，goproxy.cn） |
| shuffledns | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/shuffledns](https://github.com/projectdiscovery/shuffledns)，goproxy.cn） |
| pdtm | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/pdtm](https://github.com/projectdiscovery/pdtm)，goproxy.cn） |
| urlfinder | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/urlfinder](https://github.com/projectdiscovery/urlfinder)，goproxy.cn） |
| cvemap | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/cvemap](https://github.com/projectdiscovery/cvemap)，goproxy.cn） |

```bash
# subfinder
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@${PD_VERSION}
# dnsx
go install github.com/projectdiscovery/dnsx/cmd/dnsx@${PD_VERSION}
# naabu
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@${PD_VERSION}
apt-get install libpcap-dev
setcap cap_net_raw,cap_net_admin+eip $(which naabu)
# httpx
go install github.com/projectdiscovery/httpx/cmd/httpx@${PD_VERSION}
# nuclei
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@${PD_VERSION}
nuclei -update-templates
# katana
go install github.com/projectdiscovery/katana/cmd/katana@${PD_VERSION}
# uncover
go install github.com/projectdiscovery/uncover/cmd/uncover@${PD_VERSION}
# cloudlist
go install github.com/projectdiscovery/cloudlist/cmd/cloudlist@${PD_VERSION}
# notify
go install github.com/projectdiscovery/notify/cmd/notify@${PD_VERSION}
# interactsh-client
go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@${PD_VERSION}
# chaos
go install github.com/projectdiscovery/chaos-client/cmd/chaos@${PD_VERSION}
# mapcidr
go install github.com/projectdiscovery/mapcidr/cmd/mapcidr@${PD_VERSION}
# asnmap
go install github.com/projectdiscovery/asnmap/cmd/asnmap@${PD_VERSION}
# tlsx
go install github.com/projectdiscovery/tlsx/cmd/tlsx@${PD_VERSION}
# proxify
go install github.com/projectdiscovery/proxify/cmd/proxify@${PD_VERSION}
# simplehttpserver
go install github.com/projectdiscovery/simplehttpserver/cmd/simplehttpserver@${PD_VERSION}
# shuffledns
go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@${PD_VERSION}
# pdtm
go install github.com/projectdiscovery/pdtm/cmd/pdtm@${PD_VERSION}
# urlfinder
go install github.com/projectdiscovery/urlfinder/cmd/urlfinder@${PD_VERSION}
# cvemap
go install github.com/projectdiscovery/cvemap/cmd/cvemap@${PD_VERSION}
```

## Go 安全工具集（`secgo`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| ffuf | `@${SECGO_VERSION}`（默认 latest） | [ffuf/ffuf](https://github.com/ffuf/ffuf)（goproxy.cn） |
| gobuster | `@${SECGO_VERSION}`（默认 latest） | [OJ/gobuster](https://github.com/OJ/gobuster)（goproxy.cn） |
| dalfox | `@${SECGO_VERSION}`（默认 latest） | [hahwul/dalfox](https://github.com/hahwul/dalfox)（goproxy.cn） |
| amass | `@${SECGO_VERSION}`（默认 latest） | [owasp-amass/amass](https://github.com/owasp-amass/amass)（goproxy.cn） |
| chisel | `@${SECGO_VERSION}`（默认 latest） | [jpillora/chisel](https://github.com/jpillora/chisel)（goproxy.cn） |
| gitleaks | `@${SECGO_VERSION}`（默认 latest） | [zricethezav/gitleaks](https://github.com/zricethezav/gitleaks)（goproxy.cn） |
| assetfinder | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/assetfinder](https://github.com/tomnomnom/assetfinder)（goproxy.cn） |
| httprobe | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/httprobe](https://github.com/tomnomnom/httprobe)（goproxy.cn） |
| qsreplace | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/qsreplace](https://github.com/tomnomnom/qsreplace)（goproxy.cn） |
| waybackurls | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/waybackurls](https://github.com/tomnomnom/waybackurls)（goproxy.cn） |
| gau | `@${SECGO_VERSION}`（默认 latest） | [lc/gau](https://github.com/lc/gau)（goproxy.cn） |
| gospider | `@${SECGO_VERSION}`（默认 latest） | [jaeles-project/gospider](https://github.com/jaeles-project/gospider)（goproxy.cn） |
| gowitness | `@${SECGO_VERSION}`（默认 latest） | [sensepost/gowitness](https://github.com/sensepost/gowitness)（goproxy.cn） |
| azurehound | `@${SECGO_VERSION}`（默认 latest） | [BloodHoundAD/AzureHound](https://github.com/BloodHoundAD/AzureHound)（goproxy.cn） |
| nerva | `@${SECGO_VERSION}`（默认 latest） | [praetorian-inc/nerva](https://github.com/praetorian-inc/nerva)（goproxy.cn） |
| brutus | `@${SECGO_VERSION}`（默认 latest） | [praetorian-inc/brutus](https://github.com/praetorian-inc/brutus)（goproxy.cn） |
| aurelian | `@${SECGO_VERSION}`（默认 latest） | [praetorian-inc/aurelian](https://github.com/praetorian-inc/aurelian)（goproxy.cn） |

```bash
# ffuf
go install github.com/ffuf/ffuf/ffuf/v2/cmd/ffuf@${SECGO_VERSION:-latest}
# gobuster
go install github.com/OJ/gobuster/gobuster/v3/cmd/gobuster@${SECGO_VERSION:-latest}
# dalfox
go install github.com/hahwul/dalfox/dalfox/v2/cmd/dalfox@${SECGO_VERSION:-latest}
# amass
go install github.com/owasp-amass/amass/amass/v4/...@${SECGO_VERSION:-latest}
# chisel
go install github.com/jpillora/chisel/chisel@${SECGO_VERSION:-latest}
# gitleaks
go install github.com/zricethezav/gitleaks/gitleaks/v8@${SECGO_VERSION:-latest}
# assetfinder
go install github.com/tomnomnom/assetfinder/assetfinder@${SECGO_VERSION:-latest}
# httprobe
go install github.com/tomnomnom/httprobe/httprobe@${SECGO_VERSION:-latest}
# qsreplace
go install github.com/tomnomnom/qsreplace/qsreplace@${SECGO_VERSION:-latest}
# waybackurls
go install github.com/tomnomnom/waybackurls/waybackurls@${SECGO_VERSION:-latest}
# gau
go install github.com/lc/gau/gau/v2/cmd/gau@${SECGO_VERSION:-latest}
# gospider
go install github.com/jaeles-project/gospider/gospider@${SECGO_VERSION:-latest}
# gowitness
go install github.com/sensepost/gowitness/gowitness@${SECGO_VERSION:-latest}
# azurehound
go install github.com/BloodHoundAD/AzureHound/azurehound/v2@${SECGO_VERSION:-latest}
# nerva
go install github.com/praetorian-inc/nerva/cmd/nerva@${SECGO_VERSION:-latest}
# brutus
go install github.com/praetorian-inc/brutus/cmd/brutus@${SECGO_VERSION:-latest}
# aurelian
go install github.com/praetorian-inc/aurelian@${SECGO_VERSION:-latest}
```

## Rust 安全工具集（`secrust`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（crates 经 tuna） |
| feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（crates 经 tuna） |
| RustHound-CE | `--depth 1` 未钉，`cargo build --release --locked` | [g0h4n/RustHound-CE](https://github.com/g0h4n/RustHound-CE)（crates.io 无包；源码归档 /opt/tradecraft-ref/ad/RustHound-CE，二进制装 /usr/local/bin/rusthound-ce） |

```bash
# rustscan
cargo install rustscan --locked
# feroxbuster
cargo install feroxbuster --locked
# RustHound-CE:BloodHound CE 采集器(Linux 直跑);源码归档 tradecraft-ref/ad,构建后二进制装 /usr/local/bin
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/g0h4n/RustHound-CE /opt/tradecraft-ref/ad/RustHound-CE
cargo build --release --locked
install -m755 target/release/rusthound-ce /usr/local/bin/rusthound-ce
```

## 代理与隧道工具集（`pivot`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| gost | `@latest` 未钉 | [go-gost/gost](https://github.com/go-gost/gost)（退回 [ginuerzh/gost](https://github.com/ginuerzh/gost)） |
| frps、frpc | release latest | [fatedier/frp](https://github.com/fatedier/frp) releases |
| wstunnel | cargo 未钉 | [erebe/wstunnel](https://github.com/erebe/wstunnel) |
| rathole | cargo 未钉 | [rathole-org/rathole](https://github.com/rathole-org/rathole) |
| bore | cargo 未钉 | [ekzhang/bore](https://github.com/ekzhang/bore)（bore-cli crate） |

```bash
# gost
go install github.com/go-gost/gost/cmd/gost@latest
# frps、frpc:latest tag 经 api.github.com 取
curl …/download/<tag>/frp_<ver>_linux_amd64.tar.gz
install -m755 frps frpc /usr/local/bin
# wstunnel
cargo install --git ${GITHUB_MIRROR}https://github.com/erebe/wstunnel --locked
# rathole:失败退回 git 源
cargo install rathole
cargo install --git …/rathole-org/rathole
# bore
cargo install bore-cli --locked
```

## 安全分析工具集（`p0`）

apt 批在脚本里是整批一条命令执行（批失败不退出，pip 批与 GitHub 批与 apt 包相互独立），下表逐项拆解；impacket 与 nasm 不在 apt 批内：impacket 走 uv 上游版（用户裁定，不用 noble apt 冻结版），nasm 走官网源码钉版。

| 项目 | 版本 | 官方来源 | 用途 |
|------|------|----------|------|
| gdb-multiarch | noble 随源 | [sourceware.org/gdb](https://www.sourceware.org/gdb/)（Ubuntu 打包，tuna） | 多架构程序调试 |
| qemu-user-static | noble 随源 | [qemu.org](https://www.qemu.org)（Ubuntu 打包，tuna） | 用户态异架构 ELF 模拟执行（配 binfmt） |
| python3-pwntools | noble 随源 | [pwntools.com](https://pwntools.com)（Ubuntu 打包，tuna；只走 apt 不装 pip 版） | CTF/pwn 漏洞利用开发框架 |
| python3-ropgadget | noble 随源 | [JonathanSalwan/ROPgadget](https://github.com/JonathanSalwan/ROPgadget)（Ubuntu 打包，tuna） | ROP gadget 搜索 |
| checksec | noble 随源 | [slimm609/checksec.sh](https://github.com/slimm609/checksec.sh)（Ubuntu 打包，tuna） | 二进制保护属性检查（NX/PIE/Canary/RELRO） |
| patchelf | noble 随源 | [NixOS/patchelf](https://github.com/NixOS/patchelf)（Ubuntu 打包，tuna） | 改写 ELF 解释器与 RPATH |
| xxd | noble 随源 | [vim.org](https://www.vim.org)（Ubuntu 打包，tuna） | 十六进制转储与回写 |
| squashfs-tools | noble 随源 | [plougher/squashfs-tools](https://github.com/plougher/squashfs-tools)（Ubuntu 打包，tuna） | SquashFS 固件镜像解包与重打包 |
| nmap | noble 随源 | [nmap.org](https://nmap.org)（Ubuntu 打包，tuna） | 端口扫描与服务识别 |
| sqlmap | noble 随源 | [sqlmap.org](https://sqlmap.org)（Ubuntu 打包，tuna） | SQL 注入自动检测与利用 |
| tcpdump | noble 随源 | [tcpdump.org](https://www.tcpdump.org)（Ubuntu 打包，tuna） | 命令行抓包 |
| tshark | noble 随源 | [wireshark.org](https://www.wireshark.org)（Ubuntu 打包，tuna） | Wireshark 命令行抓包与协议解析 |
| mitmproxy | noble 随源 | [mitmproxy.org](https://mitmproxy.org)（Ubuntu 打包，tuna） | HTTP/HTTPS 中间人代理 |
| python3-scapy | noble 随源 | [scapy.net](https://scapy.net)（Ubuntu 打包，tuna） | 数据包构造与嗅探库 |
| upx-ucl | noble 随源 | [upx.github.io](https://upx.github.io)（Ubuntu 打包，tuna） | 可执行文件加壳与脱壳 |
| 7zip | noble 随源 | [7-zip.org](https://7-zip.org)（Ubuntu 打包，tuna） | 多格式压缩解压 |
| libimage-exiftool-perl | noble 随源 | [exiftool.org](https://exiftool.org)（Ubuntu 打包，tuna） | ExifTool 文件元数据读取 |
| ssdeep | noble 随源 | [ssdeep-project/ssdeep](https://github.com/ssdeep-project/ssdeep)（Ubuntu 打包，tuna） | 模糊哈希与相似度比对 |
| john | noble 随源 | [openwall.com/john](https://www.openwall.com/john/)（Ubuntu 打包，tuna） | John the Ripper 口令破解 |
| hashid | noble 随源 | [psypanda/hashID](https://github.com/psypanda/hashID)（Ubuntu 打包，tuna） | 哈希类型识别 |
| impacket（secretsdump.py 等整套脚本） | uv tool 上游最新，未钉 | [fortra/impacket](https://github.com/fortra/impacket)（PyPI 经 tuna，缺包退回官方索引；用户裁定不用 noble apt 冻结版，老镜像 apt 版增量迁移自动卸） | Windows 网络协议（SMB/Kerberos/MSRPC）工具库 |
| nasm（含 ndisasm） | 3.02（`NASM_VERSION`），官网源码编译 | [nasm.us](https://www.nasm.us/)（无国内镜像，包小直连；apt 版停 2.16.01） | x86/x64 汇编器与反汇编器 |
| flare-floss | 未钉 | [mandiant/flare-floss](https://github.com/mandiant/flare-floss)（PyPI 经 tuna） | 恶意软件混淆字符串提取 |
| oletools | 未钉 | [decalage2/oletools](https://github.com/decalage2/oletools)（PyPI 经 tuna） | Office 文档宏分析（olevba/oleid） |
| netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec)（PyPI 经 tuna，缺包退回 git 源） | 内网横向执行框架（CrackMapExec 后继） |
| pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg)（uv tool） | GDB 调试增强插件（pwn/逆向） |
| jadx | 1.5.3（`JADX_VERSION`） | [skylot/jadx](https://github.com/skylot/jadx) releases | Java/Android 反编译 |
| apktool | 2.12.0（`APKTOOL_VERSION`） | [apktool.org](https://apktool.org)（[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)） | APK 反编译与重打包 |
| capa | 9.4.0（`CAPA_VERSION`） | [mandiant/capa](https://github.com/mandiant/capa) releases | 恶意软件能力识别 |
| capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) | capa 规则库 |
| SecLists 词表 | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) | 渗透测试词表（口令/路径/枚举字典） |
| yara 规则（Yara-Rules/rules） | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) | YARA 检测规则集 |
| pdfid | `--depth 1` 未钉 | [DidierStevens 工具集](https://blog.didierstevens.com)（[DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite)） | PDF 风险结构扫描 |
| pdf-parser | `--depth 1` 未钉 | DidierStevens 工具集 | PDF 对象解析 |

```bash
# apt 20 包:整批一条命令,表内逐项拆解
apt-get install -y --no-install-recommends gdb-multiarch qemu-user-static python3-pwntools python3-ropgadget checksec patchelf xxd squashfs-tools nmap sqlmap tcpdump tshark mitmproxy python3-scapy upx-ucl 7zip libimage-exiftool-perl ssdeep john hashid
# impacket:uv tool 装上游版(不用 noble apt 冻结版,用户裁定);老镜像有 apt 版则卸(增量迁移)
apt-get remove -y python3-impacket
UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install impacket
# nasm:源码钉版,装到 /usr/local(幂等:版本一致才跳过)
curl -fSL https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz
cd nasm-${NASM_VERSION} && ./configure --prefix=/usr/local && make -j$(nproc) && make install
# flare-floss、oletools
VIRTUAL_ENV=/opt/re-venv uv pip install flare-floss oletools
# netexec:缺包退回 git 源
VIRTUAL_ENV=/opt/re-venv uv pip install netexec
uv pip install git+https://github.com/Pennyw0rth/NetExec
# pwndbg
UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install git+${GITHUB_MIRROR}https://github.com/pwndbg/pwndbg
# jadx
curl -fSL …/skylot/jadx/releases/download/v1.5.3/jadx-1.5.3.zip
unzip -d /opt/jadx
ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
# apktool:写 /usr/local/bin/apktool 包装脚本 exec java -jar /opt/apktool/apktool.jar
curl -fSL …/iBotPeaches/Apktool/releases/download/v2.12.0/apktool_2.12.0.jar -o /opt/apktool/apktool.jar
# capa:capa 链到 /usr/local/bin
curl -fSL …/mandiant/capa/releases/download/v9.4.0/capa-v9.4.0-linux.zip
unzip -d /opt/capa
# capa-rules
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/mandiant/capa-rules /opt/capa-rules
# SecLists 词表
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/danielmiessler/SecLists /opt/SecLists
# yara 规则(Yara-Rules/rules)
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/Yara-Rules/rules /opt/yara-rules
# pdfid、pdf-parser:shebang 改 #!/usr/bin/env python3
git clone --depth 1 …/DidierStevens/DidierStevensSuite /tmp/dss
cp pdfid.py pdf-parser.py /usr/local/bin/
```

## 命令与控制框架参考（`c2`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| sliver | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver) |
| merlin | `--depth 1` 未钉 | [Ne0nd0g/merlin](https://github.com/Ne0nd0g/merlin) |
| Empire | `--depth 1` 未钉 | [BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) |
| Covenant | `--depth 1` 未钉 | [cobbr/Covenant](https://github.com/cobbr/Covenant) |
| mythic | `--depth 1` 未钉 | [its-a-feature/mythic](https://github.com/its-a-feature/mythic) |
| SILENTTRINITY | `--depth 1` 未钉 | [byt3bl33d3r/SILENTTRINITY](https://github.com/byt3bl33d3r/SILENTTRINITY) |
| AdaptixC2 | `--depth 1` 未钉 | [Adaptix-Framework/AdaptixC2](https://github.com/Adaptix-Framework/AdaptixC2) |

```bash
# sliver:只克隆,不安装不运行
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/bishopfox/sliver /opt/c2dev-ref/sliver
# merlin:只克隆
git clone --depth 1 …/Ne0nd0g/merlin /opt/c2dev-ref/merlin
# Empire:只克隆
git clone --depth 1 …/BC-SECURITY/Empire /opt/c2dev-ref/Empire
# Covenant:只克隆
git clone --depth 1 …/cobbr/Covenant /opt/c2dev-ref/Covenant
# mythic:只克隆
git clone --depth 1 …/its-a-feature/mythic /opt/c2dev-ref/mythic
# SILENTTRINITY:只克隆;C# 系 C2,产物是会话(grok 裁定归 C2,非 Nim/C# 教材)
git clone --depth 1 …/byt3bl33d3r/SILENTTRINITY /opt/c2dev-ref/SILENTTRINITY
# AdaptixC2:只克隆
git clone --depth 1 …/Adaptix-Framework/AdaptixC2 /opt/c2dev-ref/AdaptixC2
# ysoserial 系是反序列化生成器,不是 C2:已移 maldev 组,归档 payload-ref/generators/deserialization
```

## 信标对象文件工具链（`bof`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| mingw-w64 | noble 随源 | Ubuntu 打包（tuna） |
| COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader) |
| atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) |
| CS-Situational-Awareness-BOF | `--depth 1` 未钉 | [trustedsec/CS-Situational-Awareness-BOF](https://github.com/trustedsec/CS-Situational-Awareness-BOF) |
| CS-Remote-OPs-BOF | `--depth 1` 未钉 | [trustedsec/CS-Remote-OPs-BOF](https://github.com/trustedsec/CS-Remote-OPs-BOF) |
| coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee)（crate 名 coffee-ldr） |
| bof-launcher | `--depth 1` 未钉；上游是库（C/Zig API）非 CLI，装示例执行器 bof_lin_<arch> | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher) |
| BOF-CATALOG.md | main raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) |

```bash
# mingw-w64
apt-get install -y --no-install-recommends mingw-w64
# COFFLoader:make bof 交叉编 Windows 版;源码归档 payload-ref/loaders/inproc
git clone --depth 1 …/trustedsec/COFFLoader /opt/payload-ref/loaders/inproc/COFFLoader
make bof
# atomic-bofs:归档 tradecraft-ref/bof
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/rasta-mouse/atomic-bofs /opt/tradecraft-ref/bof/atomic-bofs
# TrustedSec 现役 BOF 源码两套:归档 tradecraft-ref/bof
git clone --depth 1 …/trustedsec/CS-Situational-Awareness-BOF /opt/tradecraft-ref/bof/CS-Situational-Awareness-BOF
git clone --depth 1 …/trustedsec/CS-Remote-OPs-BOF /opt/tradecraft-ref/bof/CS-Remote-OPs-BOF
# coffee-ldr:失败退回 --git …/hakaioffsec/coffee;链到 /usr/local/bin
rustup toolchain install nightly
cargo +nightly install coffee-ldr --locked
# bof-launcher:先下 zig 0.15.2 专用副本 /opt/zig-0.15.2;源码归档 payload-ref/loaders/inproc;上游是库(C/Zig API)非 CLI,装示例执行器 bof_lin_<arch>
git clone --depth 1 …/The-Z-Labs/bof-launcher /opt/payload-ref/loaders/inproc/bof-launcher
/opt/zig-0.15.2/zig build -Doptimize=ReleaseSafe
install -m755 zig-out/bin/bof_lin_x64 /usr/local/bin/bof-launcher
# BOF-CATALOG.md:归档 tradecraft-ref/bof
curl -fsSL ${GITHUB_MIRROR}https://github.com/chryzsh/awesome-bof/raw/main/BOF-CATALOG.md -o /opt/tradecraft-ref/bof/BOF-CATALOG.md
```

## Project Zero 工具参考（`pz`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| sandbox-attacksurface-analysis-tools | `--depth 1` 未钉 | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools)（[Project Zero](https://googleprojectzero.blogspot.com)） |
| DotNetToJScript | `--depth 1` 未钉 | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) |
| windows-logical-eop-workshop | `--depth 1` 未钉 | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) |
| oleviewdotnet | 全克隆含子模块 | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) |

```bash
# sandbox-attacksurface-analysis-tools:只克隆,dotnet 构建尽力
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools /opt/pz-sandbox-tools
# DotNetToJScript:只克隆
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/tyranid/DotNetToJScript /opt/DotNetToJScript
# windows-logical-eop-workshop:只克隆
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/tyranid/windows-logical-eop-workshop /opt/windows-logical-eop-workshop
# oleviewdotnet:只克隆;NtApiDotNet 是嵌套子模块
git clone --recurse-submodules ${GITHUB_MIRROR}https://github.com/tyranid/oleviewdotnet /opt/oleviewdotnet
```

## 恶意开发模板库（`maldev`）

只克隆不编译不运行，按 grok 评审裁定的工件角色轴归档三根：`/opt/c2dev-ref`（产物是会话的框架，SILENTTRINITY 走 c2 组）、`/opt/payload-ref`（generators 产物是字节或变形二进制 / loaders 产物是执行字节的进程 / evasion 是往 loader 贴的原语 / curricula 教材架按语言分叶 / analysis 防御向）、`/opt/tradecraft-ref`（产物是上线后的操作员动作，ad/bof/opsec/skills 分叶）。有编译产物的仓（COFFLoader、bof-launcher、atomic-bofs、RustHound-CE）由 bof/secrust 组各自克隆构建，落点同轴，见对应组。Crystal Palace（PIC 链接器）与 Tradecraft Garden（能力加载器集）无 Git 仓，官网 tgz 归档源码。

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| Black-Hat-Zig | `--depth 1` 未钉 | [CX330Blake/Black-Hat-Zig](https://github.com/CX330Blake/Black-Hat-Zig) → /opt/payload-ref/curricula/zig/Black-Hat-Zig |
| OffensiveZig | `--depth 1` 未钉 | [darkr4y/OffensiveZig](https://github.com/darkr4y/OffensiveZig) → /opt/payload-ref/curricula/zig/OffensiveZig |
| OffensiveRust | `--depth 1` 未钉 | [trickster0/OffensiveRust](https://github.com/trickster0/OffensiveRust) → /opt/payload-ref/curricula/rust/OffensiveRust |
| black-hat-rust | `--depth 1` 未钉 | [skerkour/black-hat-rust](https://github.com/skerkour/black-hat-rust) → /opt/payload-ref/curricula/rust/black-hat-rust |
| OffensiveNim | `--depth 1` 未钉 | [byt3bl33d3r/OffensiveNim](https://github.com/byt3bl33d3r/OffensiveNim) → /opt/payload-ref/curricula/nim/OffensiveNim |
| OffensiveGo | `--depth 1` 未钉 | [Enelg52/OffensiveGo](https://github.com/Enelg52/OffensiveGo) → /opt/payload-ref/curricula/go/OffensiveGo |
| IsWebClientRunning-rs | `--depth 1` 未钉 | [g0h4n/IsWebClientRunning-rs](https://github.com/g0h4n/IsWebClientRunning-rs) → /opt/tradecraft-ref/ad/IsWebClientRunning-rs |
| HasSession-rs | `--depth 1` 未钉 | [g0h4n/HasSession-rs](https://github.com/g0h4n/HasSession-rs) → /opt/tradecraft-ref/ad/HasSession-rs |
| LocalGroups-rs | `--depth 1` 未钉 | [g0h4n/LocalGroups-rs](https://github.com/g0h4n/LocalGroups-rs) → /opt/tradecraft-ref/ad/LocalGroups-rs |
| PassTheCert-rs | `--depth 1` 未钉 | [g0h4n/PassTheCert-rs](https://github.com/g0h4n/PassTheCert-rs) → /opt/tradecraft-ref/ad/PassTheCert-rs |
| dcerpc | `--depth 1` 未钉 | [icedracon/dcerpc](https://github.com/icedracon/dcerpc) → /opt/tradecraft-ref/ad/dcerpc |
| adhammer | `--depth 1` 未钉 | [icedracon/adhammer](https://github.com/icedracon/adhammer) → /opt/tradecraft-ref/ad/adhammer |
| Rubeus | `--depth 1` 未钉 | [GhostPack/Rubeus](https://github.com/GhostPack/Rubeus) → /opt/tradecraft-ref/ad/Rubeus |
| skills | `--depth 1` 未钉 | [SpecterOps/skills](https://github.com/SpecterOps/skills) → /opt/tradecraft-ref/skills/skills |
| goffloader | `--depth 1` 未钉 | [praetorian-inc/goffloader](https://github.com/praetorian-inc/goffloader) → /opt/payload-ref/loaders/inproc/goffloader |
| dende-rs | `--depth 1` 未钉 | [g0h4n/dende-rs](https://github.com/g0h4n/dende-rs) → /opt/tradecraft-ref/opsec/dende-rs |
| gonut | `--depth 1` 未钉 | [wabzsy/gonut](https://github.com/wabzsy/gonut) → /opt/payload-ref/generators/pe-to-shellcode/gonut |
| Donut-CustomHost | `--depth 1` 未钉 | [Zuigetzu/Donut-CustomHost](https://github.com/Zuigetzu/Donut-CustomHost) → /opt/payload-ref/generators/pe-to-shellcode/Donut-CustomHost |
| donutCS | `--depth 1` 未钉 | [n1xbyte/donutCS](https://github.com/n1xbyte/donutCS) → /opt/payload-ref/generators/pe-to-shellcode/donutCS |
| go-donut | `--depth 1` 未钉 | [Binject/go-donut](https://github.com/Binject/go-donut) → /opt/payload-ref/generators/pe-to-shellcode/go-donut |
| sRDI | `--depth 1` 未钉 | [monoxgas/sRDI](https://github.com/monoxgas/sRDI) → /opt/payload-ref/generators/pe-to-shellcode/sRDI |
| pe_to_shellcode | `--depth 1` 未钉 | [hasherezade/pe_to_shellcode](https://github.com/hasherezade/pe_to_shellcode) → /opt/payload-ref/generators/pe-to-shellcode/pe_to_shellcode |
| PEzor | `--depth 1` 未钉 | [phra/PEzor](https://github.com/phra/PEzor) → /opt/payload-ref/generators/pe-to-shellcode/PEzor |
| ysoserial | `--depth 1` 未钉 | [frohoff/ysoserial](https://github.com/frohoff/ysoserial) → /opt/payload-ref/generators/deserialization/ysoserial |
| ysoserial.net | `--depth 1` 未钉 | [pwntester/ysoserial.net](https://github.com/pwntester/ysoserial.net) → /opt/payload-ref/generators/deserialization/ysoserial.net |
| donloader | `--depth 1` 未钉 | [blinkenl1ghts/donloader](https://github.com/blinkenl1ghts/donloader) → /opt/payload-ref/loaders/droppers/donloader |
| ScareCrow | `--depth 1` 未钉 | [optiv/ScareCrow](https://github.com/optiv/ScareCrow) → /opt/payload-ref/loaders/droppers/ScareCrow |
| BokuLoader | `--depth 1` 未钉 | [boku7/BokuLoader](https://github.com/boku7/BokuLoader) → /opt/payload-ref/loaders/droppers/BokuLoader |
| TitanLdr | `--depth 1` 未钉 | [benheise/TitanLdr](https://github.com/benheise/TitanLdr) → /opt/payload-ref/loaders/droppers/TitanLdr |
| DripLoader | `--depth 1` 未钉 | [xuanxuan0/DripLoader](https://github.com/xuanxuan0/DripLoader) → /opt/payload-ref/loaders/droppers/DripLoader |
| Shhhloader | `--depth 1` 未钉 | [icyguider/Shhhloader](https://github.com/icyguider/Shhhloader) → /opt/payload-ref/loaders/droppers/Shhhloader |
| No-Consolation | `--depth 1` 未钉 | [fortra/No-Consolation](https://github.com/fortra/No-Consolation) → /opt/payload-ref/loaders/inproc/No-Consolation |
| MemoryModule | `--depth 1` 未钉 | [fancycode/MemoryModule](https://github.com/fancycode/MemoryModule) → /opt/payload-ref/loaders/inproc/MemoryModule |
| Blackbone | `--depth 1` 未钉 | [DarthTon/Blackbone](https://github.com/DarthTon/Blackbone) → /opt/payload-ref/loaders/inproc/Blackbone |
| ShellcodeFluctuation | `--depth 1` 未钉 | [mgeeky/ShellcodeFluctuation](https://github.com/mgeeky/ShellcodeFluctuation) → /opt/payload-ref/evasion/ShellcodeFluctuation |
| Stardust | `--depth 1` 未钉 | [Cracked5pider/Stardust](https://github.com/Cracked5pider/Stardust) → /opt/payload-ref/evasion/Stardust |
| ApiHashing | `--depth 1` 未钉 | [Maldev-Academy/ApiHashing](https://github.com/Maldev-Academy/ApiHashing) → /opt/payload-ref/curricula/cpp/ApiHashing |
| HellHall | `--depth 1` 未钉 | [Maldev-Academy/HellHall](https://github.com/Maldev-Academy/HellHall) → /opt/payload-ref/curricula/cpp/HellHall |
| donut-decryptor | `--depth 1` 未钉 | [volexity/donut-decryptor](https://github.com/volexity/donut-decryptor) → /opt/payload-ref/analysis/donut-decryptor |
| Crystal Palace（cpsrc+cpdist） | latest tgz 未钉 | [tradecraftgarden.org](https://tradecraftgarden.org) 官网 tgz → /opt/payload-ref/evasion/crystal-palace |
| Tradecraft Garden（tcg） | latest tgz 未钉 | [tradecraftgarden.org](https://tradecraftgarden.org) 官网 tgz（资产内含 tcg/ 顶层目录） → /opt/payload-ref/loaders/tradecraft-garden |

```bash
# 39 仓按叶克隆,--depth 1 未钉;失败重试一次,仍败下轮补
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/<org>/<repo> /opt/<leaf>/<repo>
# Crystal Palace 与 Tradecraft Garden:官网 tgz 归档源码
curl -fSL https://tradecraftgarden.org/download/cpsrc-latest.tgz
tar -xzf -C /opt/payload-ref/evasion/crystal-palace
curl -fSL https://tradecraftgarden.org/download/cpdist-latest.tgz
tar -xzf -C /opt/payload-ref/evasion/crystal-palace
curl -fSL https://tradecraftgarden.org/download/tcg-latest.tgz
tar -xzf -C /opt/payload-ref/loaders/tradecraft-garden
```

## 侦察指纹参考（`recon`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| mac-tracker | `--depth 1` 未钉 | [runZeroInc/mac-tracker](https://github.com/runZeroInc/mac-tracker) |
| recog | `--depth 1` 未钉 | [rapid7/recog](https://github.com/rapid7/recog) |
| hickory-dns | `--depth 1` 未钉 | [hickory-dns/hickory-dns](https://github.com/hickory-dns/hickory-dns) |
| PoC-in-GitHub | `--depth 1` 未钉（只克隆索引，不递归） | [nomi-sec/PoC-in-GitHub](https://github.com/nomi-sec/PoC-in-GitHub) |

```bash
# mac-tracker:MAC 地址厂商指纹库;只克隆
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/runZeroInc/mac-tracker /opt/recon-ref/mac-tracker
# recog:服务/产品指纹规则库;只克隆
git clone --depth 1 …/rapid7/recog /opt/recon-ref/recog
# hickory-dns:DNS 协议栈源码参考;只克隆
git clone --depth 1 …/hickory-dns/hickory-dns /opt/recon-ref/hickory-dns
# PoC-in-GitHub:CVE PoC 索引仓;只克隆索引不递归,README 含恶意样本警示
git clone --depth 1 …/nomi-sec/PoC-in-GitHub /opt/recon-ref/PoC-in-GitHub
```

## 结构化 Shell（`nu`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| nu | release latest | [nushell.sh](https://www.nushell.sh)（[nushell/nushell](https://github.com/nushell/nushell)） |

```bash
# nu:latest tag 经 git ls-remote 取
curl …/download/<tag>/nu-<tag>-x86_64-unknown-linux-gnu.tar.gz
install -m755 nu /usr/local/bin/nu
```

## 渗透测试运行时底线（`pentest`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| lab apt 批 33 包（dnsutils、whois、socat、netcat-openbsd、telnet、ftp、snmp、proxychains4、ldap-utils、smbclient、default-mysql-client、postgresql-client、redis-tools、sqlite3、freerdp2-x11、sshuttle、hashcat、pocl-opencl-icd、ocl-icd-libopencl1、hydra、android-tools-adb、android-tools-fastboot、sleuthkit、testdisk、poppler-utils、unar、cabextract、qpdf、zbar-tools、hcxtools、aircrack-ng、steghide、osslsigncode） | noble 随源 | Ubuntu apt（tuna）；sasquatch 为源码构建（[onekey-sec/sasquatch](https://github.com/onekey-sec/sasquatch) `./build.sh`） |
| Responder | `--depth 1` 未钉 | [lgandx/Responder](https://github.com/lgandx/Responder) |
| donut（PE/.NET/VBS/JS 转 shellcode，含 libdonut 与头文件） | 1.1（`DONUT_VERSION`），release 预编译 | [TheWover/donut](https://github.com/TheWover/donut) releases |
| frida 全链（客户端与全架构 frida-server 版本对齐） | 客户端构建日最新；server 与客户端同版本 | [frida/frida](https://github.com/frida/frida) releases（GitHub 直下，无 tuna） |
| 离线固化接线（nuclei 模板、capa 规则、词表、pwndbg gdbinit、时区 locale、offline 函数） | 模板与规则 `--depth 1` 未钉 | [projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates)；规则见安全分析工具集 |

```bash
# lab apt 批 33 包:hashcat CPU 走 pocl
apt-get install -y --no-install-recommends …
# Responder:运行 python3 /opt/Responder/Responder.py -I eth0
git clone --depth 1 … /opt/Responder
# donut:解到 /opt/donut(含 lib/ 静态动态库与 donut.h),.version 标记幂等
curl -fSL …/TheWover/donut/releases/download/v${DONUT_VERSION}/donut_v${DONUT_VERSION}.tar.gz
ln -sf /opt/donut/donut /usr/local/bin/donut
# frida 全链:frida --version 取版本号;server 包解到 /opt/frida-server/<ver>/
uv tool install frida-tools
frida --version
curl …/download/<ver>/frida-server-<ver>-{windows,android,linux}-<arch>.xz
```

末行「离线固化接线」无单条命令，脚本动作如下：

- nuclei 模板克隆 `/opt/nuclei-templates` 并软链各用户 `~/nuclei-templates`
- `/usr/local/bin/nuclei` 改 wrapper 加 `-duc`
- capa 改 wrapper 加 `-r /opt/capa-rules`
- `/usr/share/wordlists` 软链 SecLists 并解包 rockyou
- `/etc/gdb/gdbinit` 接 pwndbg 并冒烟
- 时区 `Asia/Shanghai`、生成 `zh_CN.UTF-8`（默认 LANG 不动）
- `/etc/profile.d/offline.sh` 提供 `offline()` 快失败函数

## 渗透测试工具增补（`red`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| AD 横向/Web/密码/移动/云工具（kerbrute、wafw00f、arjun、ghauri、bloodhound-python、Coercer、mitm6、objection、apkleaks、bloodhound-ce、certipy-ad、bloodyAD、bofhound、jwt-tool、LinkFinder、krbrelayx、enum4linux-ng、cewl、CyberChef、kubectl、trivy、awscli） | 混合 | uv tool 走 tuna；git 克隆钉 `/opt`；gem 走 [gems.ruby-china.com](https://gems.ruby-china.com)；Release 钉版 |

```bash
# AD 横向/Web/密码/移动/云工具:trivy 构建期 --download-db-only 烘到 /opt/trivy-db
uv tool install <名>
# AD 现役批(grok 红队评审补充,与 Legacy bloodhound-python 并存):bloodhound-ce 在 tuna 缺失显式走 pypi.org;
# 入口命令 bloodhound-ce-python,venv 内含 dirkjanm impacket 叉整套脚本(secretsdump.py 解析到 /opt/uv-tools/bloodhound-ce/);
# certipy-ad 入口命令是 certipy
uv tool install --index-url https://pypi.org/simple bloodhound-ce
uv tool install certipy-ad bloodyAD bofhound
git clone --depth 1
gem install
```

# 软件清单归档

逐项列出镜像内全部软件、库与隔离环境，apt 包逐个一行（含构建依赖）；预缓存库只入缓存非安装；参考克隆不安装不运行。版本与来源口径同[安装面清单](install-surfaces.md)。攻击面测绘工具集 18 个 CLI 与 Go 安全工具集 14 个 CLI 在安装面清单中已逐行并带安装命令，此处不重复。

## 构建与编译

| 软件 | 版本 | 来源 |
|------|------|------|
| build-essential | noble 随源 | Ubuntu noble 源（tuna） |
| clang | noble 随源 | Ubuntu noble 源（tuna） |
| lldb | noble 随源 | Ubuntu noble 源（tuna） |
| gdb | noble 随源 | Ubuntu noble 源（tuna） |
| cmake | noble 随源 | Ubuntu noble 源（tuna） |
| ninja-build | noble 随源 | Ubuntu noble 源（tuna） |
| pkg-config | noble 随源 | Ubuntu noble 源（tuna） |
| autoconf | noble 随源 | Ubuntu noble 源（tuna） |
| automake | noble 随源 | Ubuntu noble 源（tuna） |
| libtool | noble 随源 | Ubuntu noble 源（tuna） |
| m4 | noble 随源 | Ubuntu noble 源（tuna） |
| clang-format | noble 随源 | Ubuntu noble 源（tuna） |
| clang-tidy | noble 随源 | Ubuntu noble 源（tuna） |
| valgrind | noble 随源 | Ubuntu noble 源（tuna） |
| strace | noble 随源 | Ubuntu noble 源（tuna） |
| ltrace | noble 随源 | Ubuntu noble 源（tuna） |
| ccache | noble 随源 | Ubuntu noble 源（tuna） |
| musl-tools | noble 随源 | Ubuntu noble 源（tuna） |
| gcc | noble 随源 | Ubuntu noble 源（tuna） |
| g++ | noble 随源 | Ubuntu noble 源（tuna） |
| nasm（含 ndisasm） | 3.02（`NASM_VERSION`），源码编译 | [nasm.us](https://www.nasm.us/) 直下 |
| flex | noble 随源（vcpkg 源码构建依赖） | Ubuntu noble 源（tuna） |
| bison | noble 随源（vcpkg 源码构建依赖） | Ubuntu noble 源（tuna） |
| mingw-w64 | noble 随源（Windows 交叉编译） | Ubuntu noble 源（tuna） |
| libssl-dev | noble 随源 | Ubuntu noble 源（tuna） |
| zlib1g-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libffi-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libbz2-dev | noble 随源（python2 构建依赖） | Ubuntu noble 源（tuna） |
| libreadline-dev | noble 随源（python2 构建依赖） | Ubuntu noble 源（tuna） |
| libsqlite3-dev | noble 随源（python2 构建依赖） | Ubuntu noble 源（tuna） |
| libncursesw5-dev | noble 随源（python2 构建依赖） | Ubuntu noble 源（tuna） |
| FASM | 1.73.32 | [flatassembler.net](https://flatassembler.net) 直下 |
| Go | 1.27.1 | [go.dev/dl](https://go.dev/dl/)（南大镜像，sha256 校验） |
| dlv | `@latest` 未钉 | [go-delve/delve](https://github.com/go-delve/delve)（goproxy.cn） |
| gopls | `@latest` 未钉 | golang.org/x/tools（goproxy.cn） |
| golangci-lint | `@latest` 未钉 | [golangci/golangci-lint](https://github.com/golangci/golangci-lint)（goproxy.cn） |
| rustup（安装器） | 随源最新 | [rustup.rs](https://rustup.rs)（tuna rustup） |
| stable toolchain | 随源最新 | rust-lang.org（tuna） |
| nightly toolchain | 随源最新 | rust-lang.org（tuna），供 coffee-ldr 构建 |
| llvm-tools | 随工具链 | rust-lang.org（tuna） |
| rustfmt | 随工具链 | rust-lang.org（tuna） |
| clippy | 随工具链 | rust-lang.org（tuna） |
| rust-analyzer | 随工具链 | rust-lang.org（tuna） |
| rust-script | cargo 未钉 | [rust-lang/rust-script](https://github.com/rust-lang/rust-script)（tuna crates） |
| cargo-zigbuild | cargo 未钉 | [rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)（tuna crates） |
| cargo-audit | cargo 未钉 | [rustsec/rustsec](https://github.com/rustsec/rustsec)（tuna crates） |
| zig | 0.16.0 | [ziglang.org](https://ziglang.org/download/) 直下 |
| zig（0.15.2 副本） | 0.15.2 | ziglang.org 直下，供 bof-launcher 构建 |
| vcpkg | `--depth 1` 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) GitHub 直下 |
| vcpkg：openssl | `VCPKG_PKGS` 集，源码编译 | vcpkg（GitHub 直下） |
| vcpkg：zlib | 同上 | vcpkg |
| vcpkg：curl | 同上 | vcpkg |
| vcpkg：sqlite3 | 同上 | vcpkg |
| vcpkg：libpcap | 同上 | vcpkg |
| vcpkg：fmt | 同上 | vcpkg |
| vcpkg：spdlog | 同上 | vcpkg |
| vcpkg：nlohmann-json | 同上 | vcpkg |
| vcpkg：rapidjson | 同上 | vcpkg |
| vcpkg：cpp-httplib | 同上 | vcpkg |
| vcpkg：mbedtls | 同上 | vcpkg |
| vcpkg：yara | 同上 | vcpkg |
| maven | 3.9.16 | [maven.apache.org](https://maven.apache.org)（tuna apache 镜像） |
| gradle | 8.14.3 | [gradle.org](https://gradle.org)（阿里云 distributions 镜像） |

## 预缓存库（只入缓存，非安装）

| 软件 | 版本 | 来源 |
|------|------|------|
| Go 模块：elazarl/goproxy | `go mod tidy` 取最新 | GOPROXY 缓存 |
| Go 模块：xtaci/smux | 同上 | GOPROXY 缓存 |
| Go 模块：hashicorp/yamux | 同上 | GOPROXY 缓存 |
| Go 模块：quic-go/quic-go | 同上 | GOPROXY 缓存 |
| Go 模块：golang.org/x/net/proxy | 同上 | GOPROXY 缓存 |
| Go 模块：armon/go-socks5 | 同上 | GOPROXY 缓存 |
| crate：ureq | `*` 取最新 | cargo registry 缓存（tuna sparse） |
| crate：url | 同上 | cargo registry 缓存 |
| crate：rustls | 同上 | cargo registry 缓存 |
| crate：webpki-roots | 同上 | cargo registry 缓存 |
| crate：tokio | 同上 | cargo registry 缓存 |
| crate：tokio-rustls | 同上 | cargo registry 缓存 |
| crate：reqwest | 同上 | cargo registry 缓存 |
| crate：tungstenite | 同上 | cargo registry 缓存 |
| crate：libc | 同上 | cargo registry 缓存 |
| crate：hpack | 同上 | cargo registry 缓存 |
| crate：sha1 | 同上 | cargo registry 缓存 |
| crate：sha2 | 同上 | cargo registry 缓存 |
| crate：hmac | 同上 | cargo registry 缓存 |
| crate：base64 | 同上 | cargo registry 缓存 |
| crate：num-bigint | 同上 | cargo registry 缓存 |
| crate：regex | 同上 | cargo registry 缓存 |
| crate：ignore | 同上 | cargo registry 缓存 |
| crate：grep-matcher | 同上 | cargo registry 缓存 |
| crate：grep-regex | 同上 | cargo registry 缓存 |
| crate：grep-searcher | 同上 | cargo registry 缓存 |
| crate：anyhow | 同上 | cargo registry 缓存 |
| crate：chrono | 同上 | cargo registry 缓存 |
| crate：serde_json | 同上 | cargo registry 缓存 |
| crate：duct | 同上 | cargo registry 缓存 |
| crate：bytes | 同上 | cargo registry 缓存 |
| crate：jaq-std | 同上 | cargo registry 缓存 |
| crate：jaq-json | 同上 | cargo registry 缓存 |
| crate：tokio-socks | 同上 | cargo registry 缓存 |
| crate：async-socks5 | 同上 | cargo registry 缓存 |

## 运行时与语言

| 软件 | 版本 | 来源 |
|------|------|------|
| python3 | noble 随源 | Ubuntu noble 源（tuna） |
| python3-pip | noble 随源 | Ubuntu noble 源（tuna） |
| python3-venv | noble 随源 | Ubuntu noble 源（tuna） |
| python3-dev | noble 随源 | Ubuntu noble 源（tuna） |
| python 2.7 | 2.7.18，`--enable-shared` | [python.org](https://www.python.org/downloads/release/python-2718/)（华为云镜像） |
| node | 24.21.0 | [nodejs.org](https://nodejs.org) 二进制（npmmirror，SHASUMS256 校验） |
| node（fnm） | 18，大版本内最新 | nodejs.org 二进制（npmmirror） |
| node（fnm） | 20，大版本内最新 | nodejs.org 二进制（npmmirror） |
| node（fnm） | 22，大版本内最新 | nodejs.org 二进制（npmmirror） |
| node（fnm） | 24，大版本内最新 | nodejs.org 二进制（npmmirror） |
| typescript | npm 全局未钉 | [npmjs.com](https://www.npmjs.com)（npmmirror） |
| prettier | npm 全局未钉 | npmjs.com（npmmirror） |
| eslint | npm 全局未钉 | npmjs.com（npmmirror） |
| corepack（pnpm、yarn） | 随 node | nodejs.org 自带（`COREPACK_NPM_REGISTRY` 指 npmmirror） |
| dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)（npmmirror） |
| fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)（tuna crates） |
| bun（含 bunx 链接） | npm 全局未钉 | [bun.sh](https://bun.sh)（npmmirror） |
| uv | 官方安装器最新 | [astral.sh/uv](https://docs.astral.sh/uv/) |
| ruff | uv tool 未钉 | [astral-sh/ruff](https://github.com/astral-sh/ruff)（tuna PyPI） |
| polars（python 库） | 未钉 | PyPI（tuna），`/opt/analytics` |
| pyarrow（python 库） | 未钉 | PyPI（tuna），`/opt/analytics` |
| chdb（python 库） | 未钉 | PyPI（tuna），`/opt/analytics` |
| duckdb（python 库） | 未钉 | [duckdb/duckdb](https://github.com/duckdb/duckdb)（PyPI 经 tuna），`/opt/analytics` |
| duckdb（CLI） | release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb) releases |
| php7.4-cli | sury 随源 | sury 源（南大镜像） |
| php7.4-dev | sury 随源 | sury 源（南大镜像） |
| php8.1-cli | sury 随源 | sury 源（南大镜像） |
| php8.1-dev | sury 随源 | sury 源（南大镜像） |
| php8.3-cli | sury 随源 | sury 源（南大镜像） |
| php8.3-dev | sury 随源 | sury 源（南大镜像） |
| php-pear | noble 随源 | Ubuntu noble 源（tuna） |
| VLD（vld-beta） | pecl 逐版本尽力 | pecl（sury 多版本 `php_suffix`） |
| mono-devel | noble 随源 | Ubuntu noble 源（tuna） |
| mono-xbuild | noble 随源 | Ubuntu noble 源（tuna） |
| nuget.exe | latest | [nuget.org](https://www.nuget.org/downloads) |
| .NET SDK | dotnet-sdk-10.0 | [dot.net](https://dot.net)（Ubuntu noble 源即 tuna） |
| powershell-lts | MS 仓随源 | packages.microsoft.com（国内无镜像） |
| sdkman 本体 | 安装器最新 | [sdkman.io](https://sdkman.io) |
| temurin JDK 8 | 小版本随 tuna 目录取最新 | [adoptium.net](https://adoptium.net)（tuna Adoptium） |
| temurin JDK 11 | 同上 | adoptium.net（tuna） |
| temurin JDK 17 | 同上 | adoptium.net（tuna） |
| temurin JDK 21 | 同上 | adoptium.net（tuna） |
| temurin JDK 25 | 同上 | adoptium.net（tuna） |

## 隔离环境与目录

| 软件 | 版本 | 来源 |
|------|------|------|
| /opt/analytics | uv venv | polars、pyarrow、chdb、duckdb；系统 python3 保持干净 |
| /opt/re-venv | uv venv | capstone、keystone-engine、unicorn、lief、yara-python、FLOSS、oletools、netexec |
| /opt/uv-tools | uv tool 根 | ruff、pwndbg 的 shim 与本体，ubuntu 可读 |
| /usr/local/sdkman | SDKMAN 目录 | temurin 注册、maven、gradle |
| fnm 数据目录 | `~/.local/share/fnm` | node 18、20、22、24 多版本 |
| NuGet 配置 | 各用户 `NuGet.Config` | `<clear/>` 后只留华为 v3 源 |
| /opt/wheelhouse、/opt/js-lab、/opt/maven-prewarm、/opt/dotnet-prewarm、/opt/zig-prewarm、/opt/go-prewarm | 库缓存固化产物 | 八生态预热工程与锁文件；wheelhouse 是 pip 轮子离线重装源 |

## 基础命令行与系统

| 软件 | 版本 | 来源 |
|------|------|------|
| ca-certificates | noble 随源 | Ubuntu noble 源（tuna）（install-all 隐式依赖） |
| curl | noble 随源 | Ubuntu noble 源（tuna） |
| wget | noble 随源 | Ubuntu noble 源（tuna） |
| gpg | noble 随源 | Ubuntu noble 源（tuna） |
| unzip | noble 随源 | Ubuntu noble 源（tuna） |
| zip | noble 随源 | Ubuntu noble 源（tuna） |
| xz-utils | noble 随源 | Ubuntu noble 源（tuna） |
| file | noble 随源 | Ubuntu noble 源（tuna） |
| git | noble 随源 | Ubuntu noble 源（tuna） |
| jq | noble 随源 | Ubuntu noble 源（tuna） |
| shellcheck | noble 随源 | Ubuntu noble 源（tuna） |
| just | noble 随源（无包时 cargo 兜底） | Ubuntu noble 源（tuna） |
| tmux | noble 随源 | Ubuntu noble 源（tuna） |
| rclone | noble 随源 | Ubuntu noble 源（tuna） |
| aria2 | noble 随源 | Ubuntu noble 源（tuna） |
| yq | `go install` 未钉 | [mikefarah/yq](https://github.com/mikefarah/yq)（goproxy.cn） |
| gh | `go install` 未钉 | [cli/cli](https://github.com/cli/cli)（goproxy.cn） |
| herdr | 0.9.3，sha256 校验 | [herdr.dev](https://herdr.dev)（[herdrdev/herdr](https://github.com/herdrdev/herdr) release） |
| nushell | release latest | [nushell.sh](https://www.nushell.sh)（[nushell/nushell](https://github.com/nushell/nushell)） |

## 搜索与文本

| 软件 | 版本 | 来源 |
|------|------|------|
| fd | noble 随源（`fd-find` 链 `fd`） | Ubuntu noble 源（tuna） |
| ripgrep | noble 随源 | Ubuntu noble 源（tuna） |
| ast-grep | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（tuna crates） |

## 图形与远程屏幕

| 软件 | 版本 | 来源 |
|------|------|------|
| xvfb | noble 随源 | Ubuntu noble 源（tuna） |
| x11vnc | noble 随源 | Ubuntu noble 源（tuna） |
| x11-utils | noble 随源 | Ubuntu noble 源（tuna） |
| xterm | noble 随源 | Ubuntu noble 源（tuna） |

## 逆向分析

| 软件 | 版本 | 来源 |
|------|------|------|
| binutils | noble 随源 | Ubuntu noble 源（tuna） |
| elfutils | noble 随源 | Ubuntu noble 源（tuna） |
| bsdmainutils | noble 随源 | Ubuntu noble 源（tuna） |
| binwalk | noble 随源 | Ubuntu noble 源（tuna） |
| yara（扫描器） | noble 随源 | Ubuntu noble 源（tuna） |
| libyara-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libzip-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libpugixml-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libcapstone-dev | noble 随源 | Ubuntu noble 源（tuna） |
| capstone-tool | noble 随源 | Ubuntu noble 源（tuna） |
| gdb-multiarch | noble 随源 | Ubuntu noble 源（tuna） |
| qemu-user-static | noble 随源 | Ubuntu noble 源（tuna） |
| upx-ucl | noble 随源 | Ubuntu noble 源（tuna） |
| libimage-exiftool-perl | noble 随源 | Ubuntu noble 源（tuna） |
| ssdeep | noble 随源 | Ubuntu noble 源（tuna） |
| squashfs-tools | noble 随源 | Ubuntu noble 源（tuna） |
| ghidra | 12.1.3，sha256 校验 | [ghidra-sre.org](https://ghidra-sre.org)（[NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra)） |
| rizin | `--depth 1` 未钉 | [rizin.re](https://rizin.re)（[rizinorg/rizin](https://github.com/rizinorg/rizin)，源码编译） |
| rz-ghidra | `--depth 1` 未钉 | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra)（源码编译） |
| sigdb | `--depth 1` 未钉 | [rizinorg/sigdb](https://github.com/rizinorg/sigdb) |
| capstone（python 绑定） | 未钉 | PyPI（tuna），`/opt/re-venv` |
| keystone-engine（python 绑定） | 未钉 | PyPI（tuna），`/opt/re-venv` |
| unicorn（python 绑定） | 未钉 | PyPI（tuna），`/opt/re-venv` |
| lief（python 绑定） | 未钉 | PyPI（tuna），`/opt/re-venv` |
| yara-python | 未钉 | PyPI（tuna），`/opt/re-venv` |
| pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg)（uv tool） |
| jadx | 1.5.3 | [skylot/jadx](https://github.com/skylot/jadx) releases |
| apktool | 2.12.0 | [apktool.org](https://apktool.org)（[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)） |
| capa | 9.4.0 | [mandiant/capa](https://github.com/mandiant/capa) releases |
| flare-floss | 未钉 | [mandiant/flare-floss](https://github.com/mandiant/flare-floss)（PyPI 经 tuna） |
| oletools | 未钉 | [decalage2/oletools](https://github.com/decalage2/oletools)（PyPI 经 tuna） |
| pdfid | `--depth 1` 未钉 | [DidierStevens 工具集](https://blog.didierstevens.com)（[DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite)） |
| pdf-parser | `--depth 1` 未钉 | DidierStevens 工具集 |
| COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader)（mingw 交叉编译） |
| atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) |
| coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee) |
| bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher)（zig 0.15.2 构建） |

## 安全测试

| 软件 | 版本 | 来源 |
|------|------|------|
| libpcap-dev | noble 随源（naabu 依赖） | Ubuntu noble 源（tuna） |
| python3-pwntools | noble 随源（只走 apt） | Ubuntu noble 源（tuna） |
| python3-ropgadget | noble 随源 | Ubuntu noble 源（tuna） |
| checksec | noble 随源 | Ubuntu noble 源（tuna） |
| patchelf | noble 随源 | Ubuntu noble 源（tuna） |
| xxd | noble 随源 | Ubuntu noble 源（tuna） |
| nmap | noble 随源 | Ubuntu noble 源（tuna） |
| sqlmap | noble 随源 | Ubuntu noble 源（tuna） |
| 7zip | noble 随源 | Ubuntu noble 源（tuna） |
| python3-impacket | noble 随源 | Ubuntu noble 源（tuna） |
| john | noble 随源 | Ubuntu noble 源（tuna） |
| hashid | noble 随源 | Ubuntu noble 源（tuna） |
| netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec)（PyPI 经 tuna，缺包退回 git） |
| rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（tuna crates） |
| feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（tuna crates） |
| SecLists 词表 | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |
| capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) |
| yara 规则（Yara-Rules/rules） | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) |

## 网络分析

| 软件 | 版本 | 来源 |
|------|------|------|
| tcpdump | noble 随源 | Ubuntu noble 源（tuna） |
| tshark | noble 随源 | Ubuntu noble 源（tuna） |
| mitmproxy | noble 随源 | Ubuntu noble 源（tuna） |
| python3-scapy | noble 随源 | Ubuntu noble 源（tuna） |

## 代理与隧道

| 软件 | 版本 | 来源 |
|------|------|------|
| gost | `@latest` 未钉 | [go-gost/gost](https://github.com/go-gost/gost)（goproxy.cn） |
| frps | release latest | [fatedier/frp](https://github.com/fatedier/frp) releases |
| frpc | release latest | [fatedier/frp](https://github.com/fatedier/frp) releases |
| wstunnel | cargo 未钉 | [erebe/wstunnel](https://github.com/erebe/wstunnel) |
| rathole | cargo 未钉 | [rathole-org/rathole](https://github.com/rathole-org/rathole) |
| bore | cargo 未钉 | [ekzhang/bore](https://github.com/ekzhang/bore)（bore-cli crate） |

## 渗透测试运行时底线

| 软件 | 版本 | 来源 |
|------|------|------|
| dnsutils（dig） | noble 随源 | Ubuntu noble 源（tuna） |
| whois | noble 随源 | Ubuntu noble 源（tuna） |
| socat | noble 随源 | Ubuntu noble 源（tuna） |
| netcat-openbsd | noble 随源 | Ubuntu noble 源（tuna） |
| telnet | noble 随源 | Ubuntu noble 源（tuna） |
| ftp | noble 随源 | Ubuntu noble 源（tuna） |
| snmp | noble 随源 | Ubuntu noble 源（tuna） |
| proxychains4 | noble 随源 | Ubuntu noble 源（tuna） |
| ldap-utils | noble 随源 | Ubuntu noble 源（tuna） |
| smbclient | noble 随源 | Ubuntu noble 源（tuna） |
| default-mysql-client | noble 随源 | Ubuntu noble 源（tuna） |
| postgresql-client | noble 随源 | Ubuntu noble 源（tuna） |
| redis-tools | noble 随源 | Ubuntu noble 源（tuna） |
| sqlite3 | noble 随源 | Ubuntu noble 源（tuna） |
| freerdp2-x11 | noble 随源 | Ubuntu noble 源（tuna） |
| sshuttle | noble 随源 | Ubuntu noble 源（tuna） |
| hashcat | noble 随源（6.2.6） | Ubuntu noble 源（tuna） |
| pocl-opencl-icd | noble 随源（CPU OpenCL） | Ubuntu noble 源（tuna） |
| ocl-icd-libopencl1 | noble 随源 | Ubuntu noble 源（tuna） |
| hydra | noble 随源（9.5） | Ubuntu noble 源（tuna） |
| android-tools-adb | noble 随源 | Ubuntu noble 源（tuna） |
| android-tools-fastboot | noble 随源 | Ubuntu noble 源（tuna） |
| sleuthkit | noble 随源 | Ubuntu noble 源（tuna） |
| testdisk | noble 随源 | Ubuntu noble 源（tuna） |
| poppler-utils | noble 随源 | Ubuntu noble 源（tuna） |
| unar | noble 随源 | Ubuntu noble 源（tuna） |
| cabextract | noble 随源 | Ubuntu noble 源（tuna） |
| qpdf | noble 随源 | Ubuntu noble 源（tuna） |
| zbar-tools | noble 随源 | Ubuntu noble 源（tuna） |
| hcxtools | noble 随源 | Ubuntu noble 源（tuna） |
| aircrack-ng | noble 随源（1.7） | Ubuntu noble 源（tuna） |
| steghide | noble 随源 | Ubuntu noble 源（tuna） |
| osslsigncode | noble 随源（2.8-2，PE 签名替代） | Ubuntu noble 源（tuna） |
| sasquatch | `--depth 1` 未钉 | [onekey-sec/sasquatch](https://github.com/onekey-sec/sasquatch) 源码构建 |
| Responder | `--depth 1` 未钉 | [lgandx/Responder](https://github.com/lgandx/Responder) → /opt/Responder |
| donut（含 libdonut 与头文件） | 1.1（`DONUT_VERSION`），release 预编译 | [TheWover/donut](https://github.com/TheWover/donut) releases → /opt/donut |
| frida-tools | uv tool 构建日最新 | [frida/frida](https://github.com/frida/frida)（tuna PyPI） |
| frida-server 全架构 | 与客户端严格同版本 | [frida/frida](https://github.com/frida/frida) releases → /opt/frida-server/<ver>/ |
| nuclei-templates | `--depth 1` 未钉 | [projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates) → /opt/nuclei-templates |

## 参考克隆（只克隆，不安装不运行）

| 软件 | 版本 | 来源 |
|------|------|------|
| sliver | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver) → /opt/c2-ref/sliver |
| merlin | `--depth 1` 未钉 | [Ne0nd0g/merlin](https://github.com/Ne0nd0g/merlin) → /opt/c2-ref/merlin |
| Empire | `--depth 1` 未钉 | [BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) → /opt/c2-ref/Empire |
| Covenant | `--depth 1` 未钉 | [cobbr/Covenant](https://github.com/cobbr/Covenant) → /opt/c2-ref/Covenant |
| ysoserial | `--depth 1` 未钉 | [frohoff/ysoserial](https://github.com/frohoff/ysoserial) → /opt/c2-ref/ysoserial |
| ysoserial.net | `--depth 1` 未钉 | [pwntester/ysoserial.net](https://github.com/pwntester/ysoserial.net) → /opt/c2-ref/ysoserial.net |
| sandbox-attacksurface-analysis-tools | `--depth 1` 未钉 | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools) → /opt/pz-sandbox-tools |
| DotNetToJScript | `--depth 1` 未钉 | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) → /opt/DotNetToJScript |
| windows-logical-eop-workshop | `--depth 1` 未钉 | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) → /opt/windows-logical-eop-workshop |
| oleviewdotnet | 全克隆含子模块 | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) → /opt/oleviewdotnet |
| BOF-CATALOG.md | main raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) → /opt/bofs/BOF-CATALOG.md |


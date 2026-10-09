# 软件清单归档

逐项列出镜像内全部软件、库与隔离环境，apt 包逐个一行（含构建依赖）；预缓存库只入缓存非安装；参考克隆不安装不运行。版本与来源口径同[安装面清单](install-surfaces/)。攻击面测绘工具集 20 个 CLI（含 urlfinder、cvemap）与 Go 安全工具集 18 个 CLI 在安装面清单中已逐行并带安装命令，此处不重复。

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
| libkrb5-dev | noble 随源（RustHound-CE 构建依赖，libgssapi-sys 要 gssapi.h） | Ubuntu noble 源（tuna） |
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
| nim（choosenim 与 stable 工具链） | 安装器最新；stable 随安装日 | [nim-lang.org](https://nim-lang.org) choosenim 官方安装器 → /opt/nim |
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
| crate：fff-search | 同上 | cargo registry 缓存（libcache rust 预热批，fff-mcp 不装二进制、只入库） |
| crate：windows-sys | 同上 | cargo registry 缓存（libcache rust 预热批，grok 库评审唯一入库） |

libcache rust 预热批（`scripts/install-libcache.sh`）另有加密/解析向 crate 30 个（aes-gcm、chacha20poly1305、rsa、x509-parser、goblin、iced-x86、tokio-tungstenite、clap、serde 等，`cargo add` 钉版后 fetch），全清单以脚本为准，此处只登记评审新增两件。

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
| clickhouse | 官方安装脚本最新（单二进制，用法 `clickhouse local`） | [clickhouse.com](https://clickhouse.com) 官方 `curl \| sh` 安装器（`CLICKHOUSE_ONLY=1`） → /usr/local/bin/clickhouse |
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
| /opt/uv-tools | uv tool 根 | ruff、pwndbg、impacket、bloodhound-ce、certipy-ad、bloodyAD、bofhound 等的 shim 与本体，ubuntu 可读 |
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
| bat（链 `bat`，二进制 batcat） | noble 随源 | Ubuntu noble 源（tuna） |
| htop | noble 随源 | Ubuntu noble 源（tuna） |
| ncdu | noble 随源 | Ubuntu noble 源（tuna） |
| moreutils | noble 随源 | Ubuntu noble 源（tuna） |
| vim | noble 随源 | Ubuntu noble 源（tuna） |
| yq | `go install` 未钉 | [mikefarah/yq](https://github.com/mikefarah/yq)（goproxy.cn） |
| gh | `go install` 未钉 | [cli/cli](https://github.com/cli/cli)（goproxy.cn） |
| herdr | 0.9.3，sha256 校验 | [herdr.dev](https://herdr.dev)（[herdrdev/herdr](https://github.com/herdrdev/herdr) release） |
| nushell | release latest | [nushell.sh](https://www.nushell.sh)（[nushell/nushell](https://github.com/nushell/nushell)） |

## 搜索与文本

| 软件 | 版本 | 来源 |
|------|------|------|
| fd | noble 随源（`fd-find` 链 `fd`） | Ubuntu noble 源（tuna） |
| ripgrep | noble 随源 | Ubuntu noble 源（tuna） |
| fzf | noble 随源 | Ubuntu noble 源（tuna） |
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
| COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader)（mingw 交叉编译） → /opt/payload-ref/loaders/inproc/COFFLoader |
| atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) → /opt/tradecraft-ref/bof/atomic-bofs |
| coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee) |
| bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher)（上游是库非 CLI；zig 0.15.2 构建，示例执行器 bof_lin_<arch> 装 /usr/local/bin） → /opt/payload-ref/loaders/inproc/bof-launcher |
| wine64（只 64 位件） | noble 随源 | Ubuntu noble 源（tuna）；跑交叉编出的 Windows PE（COFFLoader64.exe 等），不开 i386 |
| volatility3（vol、volshell 链 /usr/local/bin） | 未钉 | [volatilityfoundation/volatility3](https://github.com/volatilityfoundation/volatility3)（PyPI 经 tuna），`/opt/re-venv`（libcache python 组） |

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
| john | noble 随源 | Ubuntu noble 源（tuna） |
| hashid | noble 随源 | Ubuntu noble 源（tuna） |
| impacket（secretsdump.py 等整套脚本） | uv tool 上游最新，未钉 | [fortra/impacket](https://github.com/fortra/impacket)（PyPI 经 tuna；用户裁定不用 noble apt 冻结版） |
| netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec)（PyPI 经 tuna，缺包退回 git） |
| rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（tuna crates） |
| feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（tuna crates） |
| RustHound-CE | `--depth 1` 未钉，cargo build --release --locked | [g0h4n/RustHound-CE](https://github.com/g0h4n/RustHound-CE)（crates.io 无包，源码构建；libkrb5-dev 供 gssapi.h） → /opt/tradecraft-ref/ad/RustHound-CE，二进制 /usr/local/bin/rusthound-ce |
| bloodhound-ce（入口命令 bloodhound-ce-python） | uv tool 未钉 | [dirkjanm/BloodHound.py](https://github.com/dirkjanm/BloodHound.py)（tuna 缺包走 pypi.org；venv 内含 dirkjanm impacket 叉整套脚本，secretsdump.py 解析到 /opt/uv-tools/bloodhound-ce/） |
| certipy-ad（命令 certipy） | uv tool 未钉（实测 v5.1.0） | [ly4k/Certipy](https://github.com/ly4k/Certipy)（PyPI 经 tuna） |
| bloodyAD | uv tool 未钉 | [CravateRouge/bloodyAD](https://github.com/CravateRouge/bloodyAD)（PyPI 经 tuna） |
| bofhound | uv tool 未钉 | [coffeegist/bofhound](https://github.com/coffeegist/bofhound)（PyPI 经 tuna） |
| trufflehog | release latest | [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog) releases（上游 go.mod 带 replace 不可 go install；git 历史与云密钥扫描，与 gitleaks 互补） |
| semgrep | uv tool 未钉 | [semgrep/semgrep](https://github.com/semgrep/semgrep)（PyPI 经 tuna，SAST 代码审计） |
| evil-winrm | gem 未钉 | [Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm)（ruby-china gems；交互式 WinRM shell） |
| metasploit-framework（msfconsole 等） | omnibus 随源 | [rapid7/metasploit-framework](https://github.com/rapid7/metasploit-framework)（[msfinstall 官方安装器](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html) 加 apt.metasploit.com 仓，直连无国内镜像） → /opt/metasploit-framework |
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
| openvpn | noble 随源 | Ubuntu noble 源（tuna） |
| wireguard-tools（wg、wg-quick） | noble 随源 | Ubuntu noble 源（tuna） |
| masscan | noble 随源（setcap cap_net_raw 免 sudo） | Ubuntu noble 源（tuna） |
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
| sliver | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver) → /opt/c2dev-ref/sliver |
| merlin | `--depth 1` 未钉 | [Ne0nd0g/merlin](https://github.com/Ne0nd0g/merlin) → /opt/c2dev-ref/merlin |
| Empire | `--depth 1` 未钉 | [BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) → /opt/c2dev-ref/Empire |
| Covenant | `--depth 1` 未钉 | [cobbr/Covenant](https://github.com/cobbr/Covenant) → /opt/c2dev-ref/Covenant |
| mythic | `--depth 1` 未钉 | [its-a-feature/mythic](https://github.com/its-a-feature/mythic) → /opt/c2dev-ref/mythic |
| SILENTTRINITY | `--depth 1` 未钉 | [byt3bl33d3r/SILENTTRINITY](https://github.com/byt3bl33d3r/SILENTTRINITY) → /opt/c2dev-ref/SILENTTRINITY |
| AdaptixC2 | `--depth 1` 未钉 | [Adaptix-Framework/AdaptixC2](https://github.com/Adaptix-Framework/AdaptixC2) → /opt/c2dev-ref/AdaptixC2 |
| sandbox-attacksurface-analysis-tools | `--depth 1` 未钉 | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools) → /opt/pz-sandbox-tools |
| DotNetToJScript | `--depth 1` 未钉 | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) → /opt/DotNetToJScript |
| windows-logical-eop-workshop | `--depth 1` 未钉 | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) → /opt/windows-logical-eop-workshop |
| oleviewdotnet | 全克隆含子模块 | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) → /opt/oleviewdotnet |
| BOF-CATALOG.md | main raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) → /opt/tradecraft-ref/bof/BOF-CATALOG.md |
| CS-Situational-Awareness-BOF | `--depth 1` 未钉 | [trustedsec/CS-Situational-Awareness-BOF](https://github.com/trustedsec/CS-Situational-Awareness-BOF) → /opt/tradecraft-ref/bof/CS-Situational-Awareness-BOF |
| CS-Remote-OPs-BOF | `--depth 1` 未钉 | [trustedsec/CS-Remote-OPs-BOF](https://github.com/trustedsec/CS-Remote-OPs-BOF) → /opt/tradecraft-ref/bof/CS-Remote-OPs-BOF |
| mac-tracker | `--depth 1` 未钉 | [runZeroInc/mac-tracker](https://github.com/runZeroInc/mac-tracker) → /opt/recon-ref/mac-tracker |
| recog | `--depth 1` 未钉 | [rapid7/recog](https://github.com/rapid7/recog) → /opt/recon-ref/recog |
| hickory-dns | `--depth 1` 未钉 | [hickory-dns/hickory-dns](https://github.com/hickory-dns/hickory-dns) → /opt/recon-ref/hickory-dns |
| PoC-in-GitHub | `--depth 1` 未钉（只克隆索引，不递归） | [nomi-sec/PoC-in-GitHub](https://github.com/nomi-sec/PoC-in-GitHub) → /opt/recon-ref/PoC-in-GitHub（README 含恶意样本警示） |
| poc-search（wrapper） | 随脚本 | install-tools.sh recon 组生成 → /usr/local/bin/poc-search（CVE 精确查 / -k 关键词 / --ch SQL / --reindex） |
| poc-index.parquet | 构建期生成 | clickhouse local 灌 PoC-in-GitHub 各年 JSON → /opt/recon-ref/poc-index.parquet（离线毫秒查） |

## 载荷与开发模板参考（maldev 组，只克隆不编译）

按 grok 评审裁定的工件角色轴归档：`/opt/payload-ref`（generators 产物是字节或变形二进制 / loaders 产物是执行字节的进程 / evasion 是往 loader 贴的原语 / curricula 教材架按语言分叶 / analysis 防御向）与 `/opt/tradecraft-ref`（产物是上线后的操作员动作，ad/bof/opsec/privesc/skills 分叶）。有编译产物的仓由对应组装：COFFLoader、bof-launcher 源码在 payload-ref/loaders/inproc/（bof 组，见逆向分析），RustHound-CE 源码在 tradecraft-ref/ad（secrust 组，见安全测试），atomic-bofs 与 BOF-CATALOG.md 在 tradecraft-ref/bof（bof 组，见逆向分析与参考克隆）。

| 软件 | 版本 | 来源 |
|------|------|------|
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
| PEASS-ng（linpeas/winpeas） | `--depth 1` 未钉 | [carlospolop/PEASS-ng](https://github.com/carlospolop/PEASS-ng) → /opt/tradecraft-ref/privesc/PEASS-ng |
| linux-exploit-suggester | `--depth 1` 未钉 | [mzet-/linux-exploit-suggester](https://github.com/mzet-/linux-exploit-suggester) → /opt/tradecraft-ref/privesc/linux-exploit-suggester |
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
| Crystal Palace（cpsrc+cpdist，PIC 链接器） | latest tgz 未钉 | [tradecraftgarden.org](https://tradecraftgarden.org) 官网 tgz（无 Git 仓） → /opt/payload-ref/evasion/crystal-palace |
| Tradecraft Garden（tcg，能力加载器集） | latest tgz 未钉 | [tradecraftgarden.org](https://tradecraftgarden.org) 官网 tgz（无 Git 仓，资产内含 tcg/ 顶层目录） → /opt/payload-ref/loaders/tradecraft-garden |


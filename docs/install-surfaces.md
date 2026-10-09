# 安装面清单

本册按「脚本 → 组」分节列出三个分类脚本（外加库缓存脚本）的全部安装面：每组一张「项目|版本|官方来源」小表，表后代码块是脚本实际执行命令。运行步骤见 [README](../README.md)；参数取值见 [参数表](params.md)；装完后的全景归档见 [软件清单](software-inventory.md)。

## 分类与清单入口

三个分类脚本末尾各有 `*_ALL` 名单，`run_category` 校验入参；不传参数装全部，传入选项只装对应函数，未知项直接退出：

- `install-compilers.sh`:`COMPILERS_ALL=(c golang rust zig vcpkg)`
- `install-runtimes.sh`:`RUNTIMES_ALL=(node fnm bun uv python python2 duckdb php mono dotnet pwsh sdkman)`
- `install-tools.sh`:`TOOLS_ALL=(fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz nu pentest red)`
- `install-libcache.sh`:`LIBCACHE_ALL=(go rust python node java pwsh dotnet zig)`(八生态库缓存固化,独立分类)


安装面事实（按代码）。下文按「脚本 → 组」分节，每组一张三列小表（项目、版本、官方来源），表后 bash 代码块是脚本实际执行命令的摘录，省略 `have && skip` 幂等判断；`${变量}` 均为 `lib/common.sh` 的镜像源或版本钉，可用环境变量覆盖。

## 编译器（`install-compilers.sh`）

组列中文名与脚本键对照：C 工具链=`c`、Go 语言工具链=`golang`、Rust 工具链=`rust`、Zig 编译器=`zig`、C/C++ 包管理器=`vcpkg`。

### C 工具链（`c`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| build-essential、clang、lldb、gdb、cmake、ninja-build、pkg-config、autoconf、automake、libtool、m4、clang-format、clang-tidy、valgrind、strace、ltrace、ccache、musl-tools、zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | Ubuntu noble 源（tuna 镜像） |
| FASM | 1.73.32（`FASM_VERSION`） | [flatassembler.net](https://flatassembler.net) |

```bash
# build-essential 等 21 包
apt-get install -y --no-install-recommends build-essential clang lldb gdb cmake ninja-build pkg-config autoconf automake libtool m4 clang-format clang-tidy valgrind strace ltrace ccache musl-tools zlib1g-dev libssl-dev libffi-dev
# FASM:解到 /opt/fasm 并链接
curl -fSL https://flatassembler.net/fasm-${FASM_VERSION}.tgz
ln -sf /opt/fasm/fasm/fasm.x64 /usr/local/bin/fasm
```

### Go 语言工具链（`golang`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| Go 工具链 | 1.27.1（`GOLANG_VERSION`） | [go.dev/dl](https://go.dev/dl/)（发行包经南大镜像 `GO_DOWNLOAD`） |
| dlv、gopls、golangci-lint | `@latest` 未钉 | [go-delve/delve](https://github.com/go-delve/delve)、golang.org/x-tools、[golangci/golangci-lint](https://github.com/golangci/golangci-lint) |
| 跳板/代理库预热（goproxy、smux、yamux、quic-go、net/proxy、go-socks5 等 6 库） | `go mod tidy` 取最新 | 各库官方仓（经 `GOPROXY`） |

```bash
# Go 工具链:sha256 取 https://golang.google.cn/dl/?mode=json 校验
curl -fSL ${GO_DOWNLOAD}/go1.27.1.linux-amd64.tar.gz
tar -C /usr/local -xzf
go env -w GOPROXY=${GOPROXY} GOSUMDB=${GOSUMDB}
# dlv、gopls、golangci-lint:装完链到 /usr/local/bin
go install github.com/go-delve/delve/cmd/dlv@latest
go install golang.org/x/tools/gopls@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
# 跳板/代理库预热:临时 module 写依赖后执行,进模块缓存
GOFLAGS=-mod=mod go mod tidy && go build ./...
```

### Rust 工具链（`rust`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| rustup、stable toolchain | 随源最新 | [rustup.rs](https://rustup.rs)（经 tuna `RUSTUP_UPDATE_ROOT`） |
| llvm-tools、rustfmt、clippy、rust-analyzer | 随工具链 | [rust-lang.org](https://www.rust-lang.org)（经 tuna） |
| nightly toolchain | 随源最新 | rust-lang.org（经 tuna） |
| rust-script、cargo-zigbuild、cargo-audit | cargo 未钉 | [rust-lang/rust-script](https://github.com/rust-lang/rust-script)、[rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)、[rustsec/rustsec](https://github.com/rustsec/rustsec)（cargo-audit） |
| 件 crate 生态预热（ureq、tokio、rustls、regex 等 29 个） | `cargo fetch` 取最新 | crates.io（经 tuna sparse） |

```bash
# rustup、stable toolchain:RUSTUP_HOME=/opt/rustup、CARGO_HOME=/opt/cargo
curl -fSL ${RUSTUP_UPDATE_ROOT}/dist/x86_64-unknown-linux-gnu/rustup-init
./rustup-init -y --default-toolchain stable --profile minimal
# llvm-tools、rustfmt、clippy、rust-analyzer:rust-lld 链到 /usr/local/bin
rustup component add llvm-tools rustfmt clippy rust-analyzer
# nightly toolchain:BOF 组 coffee-ldr 构建用
rustup toolchain install nightly --profile minimal
# rust-script、cargo-zigbuild、cargo-audit:crates 索引指 tuna sparse
cargo install rust-script --locked
cargo install cargo-zigbuild --locked
cargo install cargo-audit --locked
# 件 crate 生态预热:临时 crate 写 Cargo.toml 依赖后执行,进 registry 缓存
cargo fetch --quiet
```

### Zig 编译器（`zig`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| zig | 0.16.0（`ZIG_VERSION`）；0.15.2 副本供 BOF 工具链 | [ziglang.org/download](https://ziglang.org/download/) |

```bash
# zig
curl -fSL https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz
tar -C /opt/zig -xJf --strip-components=1
ln -sf /opt/zig/zig /usr/local/bin/zig
```

### C/C++ 包管理器（`vcpkg`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| vcpkg 本体与 12 库（`VCPKG_PKGS`） | `--depth 1` 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) |

```bash
# vcpkg 本体与 12 库
apt-get install flex bison
git clone --depth 1 https://github.com/microsoft/vcpkg /opt/vcpkg
./bootstrap-vcpkg.sh -disableMetrics
vcpkg install openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara
```

## 运行时（`install-runtimes.sh`）

组列中文名与脚本键对照：Node.js 运行时=`node`、Node 版本管理器=`fnm`、Bun 运行时=`bun`、Python 包管理器=`uv`、Python 3 运行时=`python`、Python 2 运行时=`python2`、DuckDB 分析引擎=`duckdb`、PHP 运行时=`php`、Mono 运行时=`mono`、.NET 运行时=`dotnet`、PowerShell=`pwsh`、Java 工具链管理器=`sdkman`。

### Node.js 运行时（`node`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| node、npm、npx | 24.21.0（`NODE_VERSION`） | [nodejs.org](https://nodejs.org) 二进制（npmmirror `NODE_MIRROR`，`SHASUMS256.txt` 校验） |
| 全局 npmrc（registry、disturl、electron_mirror） | — | npmmirror |
| typescript、prettier、eslint | npm 全局未钉 | [npmjs.com](https://www.npmjs.com)（npmmirror） |
| corepack（pnpm、yarn） | 随 node | [nodejs.org](https://nodejs.org) 自带 |
| dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)（npmmirror） |

```bash
# node、npm、npx:node、npm、npx 链到 /usr/local/bin
curl -fSL ${NODE_MIRROR}/v24.21.0/node-v24.21.0-linux-x64.tar.xz
sha256sum -c
tar -C /opt/node -xJf --strip-components=1
# 全局 npmrc:直写 /opt/node/etc/npmrc 的 disturl=https://npmmirror.com/mirrors/node、electron_mirror=https://npmmirror.com/mirrors/electron/
npm config set --location=global registry ${NPM_REGISTRY}
# typescript、prettier、eslint:tsc、tsserver、prettier、eslint 链到 /usr/local/bin
npm install -g typescript
npm install -g prettier eslint
# corepack(pnpm、yarn)
COREPACK_NPM_REGISTRY=${NPM_REGISTRY} corepack enable
# dotnetjs
npm install -g dotnetjs
```

### Node 版本管理器（`fnm`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)（crates 经 tuna） |
| node 18、20、22、24 | 大版本内最新（`FNM_NODE_VERSIONS`） | nodejs.org 二进制（npmmirror） |

```bash
# fnm
cargo install fnm --locked
# node 18、20、22、24:20、22、24 与 18 同;profile.d 写 fnm env
fnm install --node-dist-mirror ${NODE_MIRROR} 18
fnm default <最新>
```

### Bun 运行时（`bun`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| bun、bunx | npm 全局未钉 | [bun.sh](https://bun.sh)（npmmirror） |

```bash
# bun、bunx:链到 /usr/local/bin;root 与 ubuntu 各写 .bunfig.toml 的 [install] registry = ${NPM_REGISTRY}
npm install -g bun
```

### Python 包管理器（`uv`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| uv | 官方安装器最新 | [astral.sh/uv](https://docs.astral.sh/uv/)（[astral-sh/uv](https://github.com/astral-sh/uv)） |

```bash
# uv:写 /etc/uv/uv.toml 的 [[index]] url = ${PIP_INDEX}、default = true
curl -LsSf https://astral.sh/uv/install.sh | sh
ln -sf ~/.local/bin/uv /usr/local/bin/uv
```

### Python 3 运行时（`python`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| python3 及 pip、venv、dev | noble 随源 | [python.org](https://www.python.org)（Ubuntu 打包，tuna） |
| ruff | uv tool 未钉 | [astral-sh/ruff](https://github.com/astral-sh/ruff) |
| /opt/analytics venv：polars、pyarrow、chdb | 未钉 | PyPI（tuna） |

```bash
# python3 及 pip、venv、dev:写 /etc/pip.conf 的 index-url = ${PIP_INDEX};不装任何第三方包
apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
# ruff
UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install ruff
# /opt/analytics venv(polars、pyarrow、chdb)
uv venv /opt/analytics
VIRTUAL_ENV=/opt/analytics uv pip install polars pyarrow chdb
```

### Python 2 运行时（`python2`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| python 2.7 | 2.7.18（`PY2_VERSION`），`--enable-shared` | [python.org](https://www.python.org/downloads/release/python-2718/)（源码包经华为云 `PY2_MIRROR`） |

```bash
# python 2.7
apt-get install libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils libffi-dev
curl -fSL ${PY2_MIRROR}/2.7.18/Python-2.7.18.tgz
./configure --prefix=/usr/local --enable-shared && make -j$(nproc) && make altinstall
```

### DuckDB 分析引擎（`duckdb`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| duckdb python 绑定 | 未钉 | [duckdb/duckdb](https://github.com/duckdb/duckdb)（PyPI 经 tuna） |
| duckdb CLI | release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb) releases |

```bash
# duckdb python 绑定
VIRTUAL_ENV=/opt/analytics uv pip install -U duckdb
# duckdb CLI:latest tag 经 api.github.com 取
curl -fSL https://github.com/duckdb/duckdb/releases/download/<tag>/duckdb_cli-linux-amd64.zip
install -m755 /usr/local/bin/duckdb
```

### PHP 运行时（`php`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| php-cli、php-dev 多版本与 VLD | 7.4、8.1、8.3（`PHP_VERSIONS`） | [php.net](https://www.php.net)（Ondřej Surý 第三方打包，`SURY_MIRROR` 南大镜像；GPG key 从 packages.sury.org 取一次） |

```bash
# php-cli、php-dev 多版本与 VLD
apt-get install php${v}-cli php${v}-dev
apt-get install php-pear
yes '' | pecl -q -d php_suffix=${v} install vld-beta
phpenmod -v ${v} vld
```

### Mono 运行时（`mono`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| mono-devel、mono-xbuild | noble 随源 | [mono-project.com](https://www.mono-project.com)（Ubuntu 打包，tuna） |
| nuget.exe | latest | [nuget.org](https://www.nuget.org/downloads) |

```bash
# mono-devel、mono-xbuild
apt-get install -y --no-install-recommends mono-devel mono-xbuild
# nuget.exe
curl -fSL https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o /opt/nuget.exe
```

### .NET 运行时（`dotnet`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| .NET SDK | dotnet-sdk-10.0（`DOTNET_SDK`） | [dot.net](https://dot.net)（Ubuntu noble 源即 tuna；MS 仓 24.04 起不提供 .NET） |

```bash
# .NET SDK:root 与 ubuntu 写 NuGet.Config,<clear/> 后只留 ${NUGET_MIRROR}(华为 v3)
apt-get install -y dotnet-sdk-10.0
```

### PowerShell（`pwsh`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| PowerShell | powershell-lts 随仓 | [PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)（packages.microsoft.com，国内无镜像） |

```bash
# PowerShell:powershell-lts 不可用时退回 powershell
curl -fSL packages-microsoft-prod.deb && dpkg -i
apt-get install -y powershell-lts
```

### Java 工具链管理器（`sdkman`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| sdkman 本体 | 安装器最新 | [sdkman.io](https://sdkman.io) |
| temurin JDK 8、11、17、21、25 | 小版本随 tuna 目录取最新（`JAVA_VERSIONS`） | [adoptium.net](https://adoptium.net)（tuna `ADOPTIUM_MIRROR`） |
| maven | 3.9.16（`MAVEN_VERSION`） | [maven.apache.org](https://maven.apache.org)（发行包经 tuna `MAVEN_MIRROR`） |
| gradle | 8.14.3（`GRADLE_VERSION`） | [gradle.org](https://gradle.org)（阿里云 distributions 镜像） |

```bash
# sdkman 本体:config 关 selfupdate、开 auto_env
curl -fSL https://get.sdkman.io -o sdkman-init.sh
SDKMAN_DIR=/usr/local/sdkman bash sdkman-init.sh
# temurin JDK 8、11、17、21、25:tuna 目录取最新 OpenJDK${major}U-jdk_x64_linux_hotspot_*.tar.gz;java、javac 链到 /usr/local/bin
tar -C /opt/jdk/temurin-<ver> --strip-components=1
sdk install java <ver>-tem <本地路径>
sdk default java <最后一个>
# maven:写 settings.xml mirror 指 ${MAVEN_DEP_MIRROR}(阿里云)
curl -fSL ${MAVEN_MIRROR}/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz
tar -C /opt/maven --strip-components=1
# gradle:root 与 ubuntu 写 .gradle/init.d/mirrors.gradle 指阿里云 public 与 gradle-plugin
curl -fSL https://mirrors.aliyun.com/gradle/distributions/v8.14.3/gradle-8.14.3-bin.zip
unzip -d /opt/gradle
```

## 工具（`install-tools.sh`）

组列中文名与脚本键对照：文件与内容搜索=`fd`、结构化代码搜索=`ast-grep`、基础命令行工具=`cli`、终端工作区管理器=`herdr`、逆向分析套件=`ghidra`、逆向分析稳定链=`re`、攻击面测绘工具集=`pd`、Go 安全工具集=`secgo`、Rust 安全工具集=`secrust`、代理与隧道工具集=`pivot`、安全分析工具集=`p0`、命令与控制框架参考=`c2`、信标对象文件工具链=`bof`、Project Zero 工具参考=`pz`、结构化 Shell=`nu`、渗透测试运行时底线=`pentest`、渗透测试工具增补=`red`。

### 文件与内容搜索（`fd`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| fd、ripgrep | noble 随源 | [sharkdp/fd](https://github.com/sharkdp/fd)、[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)（Ubuntu 打包，tuna） |

```bash
# fd、ripgrep
apt-get install -y --no-install-recommends fd-find ripgrep
ln -sf /usr/bin/fdfind /usr/local/bin/fd
```

### 结构化代码搜索（`ast-grep`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| ast-grep（`sg`） | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（crates 经 tuna） |

```bash
# ast-grep(sg)
cargo install ast-grep --locked
ln -sf /root/.cargo/bin/sg /usr/local/bin/sg
```

### 基础命令行工具（`cli`）

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

### 终端工作区管理器（`herdr`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| herdr | 0.9.3（`HERDR_VERSION`），sha256 校验 | [herdr.dev](https://herdr.dev)（[herdrdev/herdr](https://github.com/herdrdev/herdr) release） |

```bash
# herdr:sha256 校验值取 HERDR_SHA256;aarch64 跳过校验
curl -fSL ${GITHUB_MIRROR}https://github.com/herdrdev/herdr/releases/download/v0.9.3/herdr-linux-x86_64
sha256sum -c
install -m755 /usr/local/bin/herdr
```

### 逆向分析套件（`ghidra`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| ghidra | 12.1.3（`GHIDRA_VERSION`/`GHIDRA_DATE`），sha256 校验 | [ghidra-sre.org](https://ghidra-sre.org)（[NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) release） |

```bash
# ghidra:launch.properties 写 JAVA_HOME_OVERRIDE=<temurin 21>;ghidraRun、analyzeHeadless 链到 /usr/local/bin
curl -fSL …/download/Ghidra_12.1.3_build/ghidra_12.1.3_PUBLIC_20260817.zip
sha256sum -c
unzip -d /opt/ghidra
```

### 逆向分析稳定链（`re`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| 系统库 20 项（binutils、elfutils、file、bsdmainutils、binwalk、yara、libyara-dev、libzip-dev、libpugixml-dev、libcapstone-dev、capstone-tool、meson、ninja、cmake、pkg-config、gcc、g++、python3、python3-pip、python3-venv、zlib1g-dev） | noble 随源 | 各项目官方站（Ubuntu 打包，tuna） |
| rizin | `--depth 1` 未钉 | [rizin.re](https://rizin.re)（[rizinorg/rizin](https://github.com/rizinorg/rizin)） |
| rz-ghidra | `--depth 1` 未钉（子模块钉 ghidra ref） | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra) |
| sigdb | `--depth 1` 未钉 | [rizinorg/sigdb](https://github.com/rizinorg/sigdb) |
| /opt/re-venv 五库（capstone、keystone-engine、unicorn、lief、yara-python） | 未钉 | PyPI（tuna） |

```bash
# 系统库 20 项
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

### 攻击面测绘工具集（`pd`）

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
```

### Go 安全工具集（`secgo`）

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
```

### Rust 安全工具集（`secrust`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（crates 经 tuna） |
| feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（crates 经 tuna） |

```bash
# rustscan
cargo install rustscan --locked
# feroxbuster
cargo install feroxbuster --locked
```

### 代理与隧道工具集（`pivot`）

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

### 安全分析工具集（`p0`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| apt 21 包（gdb-multiarch、qemu-user-static、python3-pwntools、python3-ropgadget、checksec、patchelf、xxd、squashfs-tools、nmap、sqlmap、tcpdump、tshark、mitmproxy、python3-scapy、upx-ucl、7zip、libimage-exiftool-perl、ssdeep、python3-impacket、john、hashid） | noble 随源 | pwntools.com、nmap.org、sqlmap.org、wireshark.org、mitmproxy.org、scapy.net、upx.github.io、7-zip.org、exiftool.org、openwall.com 等（Ubuntu 打包，tuna） |
| nasm（含 ndisasm） | 3.02（`NASM_VERSION`），源码编译 | [nasm.us](https://www.nasm.us/)（无国内镜像，包小直连；apt 版停 2.16.01） |
| flare-floss、oletools | 未钉 | [mandiant/flare-floss](https://github.com/mandiant/flare-floss)、[decalage2/oletools](https://github.com/decalage2/oletools)（PyPI 经 tuna） |
| netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec) |
| pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg) |
| jadx | 1.5.3（`JADX_VERSION`） | [skylot/jadx](https://github.com/skylot/jadx) releases |
| apktool | 2.12.0（`APKTOOL_VERSION`） | [apktool.org](https://apktool.org)（[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)） |
| capa | 9.4.0（`CAPA_VERSION`） | [mandiant/capa](https://github.com/mandiant/capa) releases |
| capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) |
| SecLists 词表 | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |
| yara 规则（Yara-Rules/rules） | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) |
| pdfid、pdf-parser | `--depth 1` 未钉 | [DidierStevens 工具集](https://blog.didierstevens.com)（[DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite)） |

```bash
# apt 21 包
apt-get install -y --no-install-recommends gdb-multiarch qemu-user-static python3-pwntools python3-ropgadget checksec patchelf xxd squashfs-tools nmap sqlmap tcpdump tshark mitmproxy python3-scapy upx-ucl 7zip libimage-exiftool-perl ssdeep python3-impacket john hashid
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

### 命令与控制框架参考（`c2`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| sliver | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver) |
| merlin | `--depth 1` 未钉 | [Ne0nd0g/merlin](https://github.com/Ne0nd0g/merlin) |
| Empire | `--depth 1` 未钉 | [BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) |
| Covenant | `--depth 1` 未钉 | [cobbr/Covenant](https://github.com/cobbr/Covenant) |
| ysoserial | `--depth 1` 未钉 | [frohoff/ysoserial](https://github.com/frohoff/ysoserial) |
| ysoserial.net | `--depth 1` 未钉 | [pwntester/ysoserial.net](https://github.com/pwntester/ysoserial.net) |

```bash
# sliver:只克隆,不安装不运行
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/bishopfox/sliver /opt/c2-ref/sliver
# merlin:只克隆
git clone --depth 1 …/Ne0nd0g/merlin /opt/c2-ref/merlin
# Empire:只克隆
git clone --depth 1 …/BC-SECURITY/Empire /opt/c2-ref/Empire
# Covenant:只克隆
git clone --depth 1 …/cobbr/Covenant /opt/c2-ref/Covenant
# ysoserial:只克隆;构建需 JDK 8
git clone --depth 1 …/frohoff/ysoserial /opt/c2-ref/ysoserial
# ysoserial.net:只克隆;运行走 mono
git clone --depth 1 …/pwntester/ysoserial.net /opt/c2-ref/ysoserial.net
```

### 信标对象文件工具链（`bof`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| mingw-w64 | noble 随源 | Ubuntu 打包（tuna） |
| COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader) |
| atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) |
| coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee)（crate 名 coffee-ldr） |
| bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher) |
| BOF-CATALOG.md | main raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) |

```bash
# mingw-w64
apt-get install -y --no-install-recommends mingw-w64
# COFFLoader:make bof 交叉编 Windows 版
git clone --depth 1 …/trustedsec/COFFLoader /tmp/coffloader
make bof
# atomic-bofs
git clone --depth 1 ${GITHUB_MIRROR}https://github.com/rasta-mouse/atomic-bofs /opt/atomic-bofs
# coffee-ldr:失败退回 --git …/hakaioffsec/coffee;链到 /usr/local/bin
rustup toolchain install nightly
cargo +nightly install coffee-ldr --locked
# bof-launcher:先下 zig 0.15.2 专用副本 /opt/zig-0.15.2
git clone --depth 1 …/The-Z-Labs/bof-launcher /tmp/bof-launcher
/opt/zig-0.15.2/zig build -Doptimize=ReleaseSafe
install -m755 /usr/local/bin/bof-launcher
# BOF-CATALOG.md
curl -fsSL ${GITHUB_MIRROR}https://github.com/chryzsh/awesome-bof/raw/main/BOF-CATALOG.md -o /opt/bofs/BOF-CATALOG.md
```

### Project Zero 工具参考（`pz`）

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

### 结构化 Shell（`nu`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| nu | release latest | [nushell.sh](https://www.nushell.sh)（[nushell/nushell](https://github.com/nushell/nushell)） |

```bash
# nu:latest tag 经 api.github.com 取
curl …/download/<tag>/nu-<tag>-x86_64-unknown-linux-gnu.tar.gz
install -m755 nu /usr/local/bin/nu
```

### 渗透测试运行时底线（`pentest`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| lab apt 批 24 包（dnsutils、whois、socat、netcat-openbsd、telnet、ftp、snmp、proxychains4、ldap-utils、smbclient、default-mysql-client、postgresql-client、redis-tools、sqlite3、freerdp2-x11、sshuttle、hashcat、pocl-opencl-icd、ocl-icd-libopencl1、hydra、android-tools-adb、android-tools-fastboot、sleuthkit、testdisk、poppler-utils、unar、cabextract、qpdf、zbar-tools、hcxtools、aircrack-ng、steghide、osslsigncode） | noble 随源 | Ubuntu apt（tuna）；sasquatch 为源码构建（[onekey-sec/sasquatch](https://github.com/onekey-sec/sasquatch) `./build.sh`） |
| Responder | `--depth 1` 未钉 | [lgandx/Responder](https://github.com/lgandx/Responder) |
| frida 全链（客户端与全架构 frida-server 版本对齐） | 客户端构建日最新；server 与客户端同版本 | [frida/frida](https://github.com/frida/frida) releases（GitHub 直下，无 tuna） |
| 离线固化接线（nuclei 模板、capa 规则、词表、pwndbg gdbinit、时区 locale、offline 函数） | 模板与规则 `--depth 1` 未钉 | [projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates)；规则见安全分析工具集 |

```bash
# lab apt 批 24 包:hashcat CPU 走 pocl
apt-get install -y --no-install-recommends …
# Responder:运行 python3 /opt/Responder/Responder.py -I eth0
git clone --depth 1 … /opt/Responder
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

### 渗透测试工具增补（`red`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| AD 横向/Web/密码/移动/云工具（kerbrute、wafw00f、arjun、ghauri、bloodhound-python、Coercer、mitm6、objection、apkleaks、jwt-tool、LinkFinder、krbrelayx、enum4linux-ng、cewl、CyberChef、kubectl、trivy、awscli） | 混合 | uv tool 走 tuna；git 克隆钉 `/opt`；gem 走 [gems.ruby-china.com](https://gems.ruby-china.com)；Release 钉版 |

```bash
# AD 横向/Web/密码/移动/云工具:trivy 构建期 --download-db-only 烘到 /opt/trivy-db
uv tool install <名>
git clone --depth 1
gem install
```

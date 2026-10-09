# pi-rs-runtime

本仓是 pi agent 的运行时环境维护仓，仓库地址为 [raystyle/pi-rs-runtime](https://github.com/raystyle/pi-rs-runtime)。输入是 Ubuntu 24.04（noble）与 `image-defs/ubuntu.yaml` 镜像定义；输出是 Incus 基础镜像 `ubuntu-24.04-base` 与发布别名 `pi-rs-runtime` 的运行时镜像；副作用包括：构建时删除同名旧镜像、在 `image-defs/` 下生成 `incus.tar.xz` 与 `rootfs.squashfs`、启动并删除临时验证容器、在容器内改写 apt 源与各类工具链配置。

## 前置条件

- 宿主需为已初始化的 Incus（`sudo incus admin init --auto` 即可）,`build-base-image.sh` 以 sudo 调用 `distrobuilder` 与 `incus`。
- `distrobuilder` 需从源码编译：Ubuntu 官方源无此包，官方只发布 Snap。需要 Go(Ubuntu 24.04 自带 `golang-go` 满足）与 `debootstrap rsync gpg squashfs-tools git make build-essential libwin-hivex-perl wimtools genisoimage`:

  ```bash
  git clone https://github.com/lxc/distrobuilder
  cd distrobuilder && make
  sudo install -m 755 "$HOME/go/bin/distrobuilder" /usr/local/bin/distrobuilder
  ```

- 容器内安装脚本（`scripts/install-*.sh`）以 root 在 Ubuntu 24.04 容器内运行，bash,`set -euo pipefail`，幂等可重跑。
- 网络：默认走清华 tuna 源与各生态国内镜像；Ghidra、vcpkg、rizin、zig 等从 GitHub 或官方直下，国内直连可能失败，可设 `GITHUB_MIRROR` 前置代理。
- 镜像源原则（`lib/common.sh` 注释）：有 tuna 走 tuna;tuna 没有的走该生态自己的国内镜像（golang 模块走 goproxy.cn,npm 走 npmmirror,sury 走南大镜像等）。

## 参数表

### 构建脚本（`build-base-image.sh`）

| 名称 | 类型 | 必填 | 默认 | 约束 |
|------|------|------|------|
| `RELEASE` | 环境变量 | 否 | `noble` | Ubuntu 套件代号，传给 `-o image.release`,yaml 不写死，必须显式给 |
| `ARCH` | 环境变量 | 否 | `amd64` | `amd64` 或 `arm64` |
| `ALIAS` | 环境变量 | 否 | `ubuntu-24.04-base` | 导入 Incus 的别名；同名旧别名先删后导 |

### 镜像源覆盖（`lib/common.sh`，全部可选）

| 名称 | 默认 | 约束 |
|------|------|------|
| `TUNA` | `https://mirrors.tuna.tsinghua.edu.cn` | 其余 tuna 系镜像的前缀 |
| `RUSTUP_DIST_SERVER` / `RUSTUP_UPDATE_ROOT` | `$TUNA/rustup`、`$TUNA/rustup/rustup` | 已 export，持久化到 `/etc/profile.d/rustup.sh` |
| `CRATES_INDEX` | `$TUNA/crates.io-index` | cargo sparse index |
| `GOPROXY` / `GOSUMDB` | `https://goproxy.cn,direct` / `sum.golang.google.cn` | 已 export,`go install` 子进程继承 |
| `GO_DOWNLOAD` | `https://mirror.nju.edu.cn/golang` | tuna 无 golang 发行包 |
| `NPM_REGISTRY` / `NODE_MIRROR` | `https://registry.npmmirror.com` 及其 `/-/binary/node` | npm registry 与 node 二进制分开 |
| `PIP_INDEX` | `https://pypi.tuna.tsinghua.edu.cn/simple` | 写 `/etc/pip.conf` 与 `/etc/uv/uv.toml`,uv 索引用同一个变量 |
| `ADOPTIUM_MIRROR` | `$TUNA/Adoptium` | temurin JDK 发行包 |
| `MAVEN_MIRROR` / `MAVEN_DEP_MIRROR` | `$TUNA/apache/maven` / `https://maven.aliyun.com/repository/public` | 发行包与 Central 依赖分开 |
| `NUGET_MIRROR` | `https://repo.huaweicloud.com/repository/nuget/v3/index.json` | 写各用户 `NuGet.Config`,`<clear/>` 后只留此源 |
| `PY2_MIRROR` | `https://mirrors.huaweicloud.com/python` | python2 源码包 |
| `SURY_MIRROR` | `https://mirror.nju.edu.cn/sury` | tuna 无 sury;GPG key 仍从官方取一次 |
| `GITHUB_MIRROR` | 空 | 可选前置代理（如 `https://ghfast.top/`)，拼在 `https://github.com` 前 |

### 版本钉（`lib/common.sh`，全部可选）

| 名称 | 默认 | 约束 |
|------|------|------|
| `GOLANG_VERSION` | `1.27.1` | sha256 从 golang.google.cn 官方 JSON 取并校验 |
| `NODE_VERSION` | `24.21.0` | npmmirror `SHASUMS256.txt` 校验 |
| `FNM_NODE_VERSIONS` | `18 20 22 24` | fnm 预装的 node 大版本，空格分隔 |
| `DOTNET_SDK` | `dotnet-sdk-10.0` | noble 自带源（即 tuna);MS 仓仅 pwsh 注册 |
| `ZIG_VERSION` | `0.16.0` | ziglang.org 直下，无国内镜像；仅 amd64/arm64 |
| `MAVEN_VERSION` / `GRADLE_VERSION` | `3.9.16` / `8.14.3` | |
| `JAVA_VERSIONS` | `8 11 17 21 25` | sdkman 预装的 temurin 主版本；小版本随 tuna 目录取最新 |
| `PD_VERSION` | `latest` | projectdiscovery 全家桶 `go install` 版本 |
| `PY2_VERSION` | `2.7.18` | 源码编译，`--enable-shared` |
| `PHP_VERSIONS` | `7.4 8.1 8.3` | sury 源；VLD 逐版本尽力编译 |
| `GHIDRA_VERSION` / `GHIDRA_DATE` / `GHIDRA_SHA256` | `12.1.3` / `20260817` / `93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54` | 三者配套，换版本时同步换 |
| `FASM_VERSION` | `1.73.32` | 见 `install-compilers.sh` 内 `install_c` |
| `JADX_VERSION` / `APKTOOL_VERSION` / `CAPA_VERSION` | `1.5.3` / `2.12.0` / `9.4.0` | 见 `install-tools.sh` 内 `install_p0` |
| `HERDR_VERSION` / `HERDR_SHA256` | `0.9.3` / `18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7` | herdr.dev stable 频道；校验和只覆盖 linux-x86_64 资产，换版本重算 |
| `SECGO_VERSION` | `latest` | Go 安全工具组 `go install` 版本 |

### 路径与工具集

| 名称 | 默认 | 约束 |
|------|------|------|
| `RE_VENV` | `/opt/re-venv` | 逆向 Python 环境（uv venv):capstone、keystone-engine、unicorn、lief、yara-python 与 FLOSS、oletools、netexec |
| `VENV_ANALYTICS` | `/opt/analytics` | 分析 venv(uv venv):polars、pyarrow、chdb、duckdb；系统 python3 不装 pip 第三方包 |
| `PD_TOOLS` / `SECGO_TOOLS` | 见脚本内 `PD_TOOLS_DEFAULT` / `SECGO_TOOLS_DEFAULT` | 空格分隔清单，留空装默认全集；单工具编译失败不中断整组 |
| `VCPKG_PKGS` | `openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara` | vcpkg 源码编译，耗时较长 |
| `PI_IMAGE` | `pi-box-dev` | `dev-instance.sh` 启动用的镜像别名 |
| `VNC_RES` / `VNC_DISPLAY` / `VNC_PORT` | `1280x800x24` / `:99` / `5900` | `vnc-screen.sh`;VNC 只绑 `127.0.0.1` |
| `VNC_PASS` | 空 | 未提供且 `~/.vnc/passfile` 不存在时生成 12 位随机口令并打印 |

### 分类与清单入口

三个分类脚本末尾各有 `*_ALL` 名单，`run_category` 校验入参；不传参数装全部，传入选项只装对应函数，未知项直接退出：

- `install-compilers.sh`:`COMPILERS_ALL=(c golang rust zig vcpkg)`
- `install-runtimes.sh`:`RUNTIMES_ALL=(node fnm bun uv python python2 duckdb php mono dotnet pwsh sdkman)`
- `install-tools.sh`:`TOOLS_ALL=(fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz nu)`

## 步骤

### 1. 准备宿主机构建环境

一次性执行：

1. 安装并初始化 Incus:`sudo apt install -y incus`，然后 `sudo incus admin init --auto`。
2. 按前置条件从源码编译并安装 `distrobuilder`。
3. （可选）把宿主 apt 源换成 tuna（deb822 格式，把 `URIs:` 改为 `https://mirrors.tuna.tsinghua.edu.cn/ubuntu/`），加快装包。

### 2. 构建基础镜像

```bash
./scripts/build-base-image.sh
```

等价于：

```bash
cd image-defs
sudo distrobuilder build-incus ubuntu.yaml \
  -o image.release=noble -o image.architecture=amd64 -o image.variant=cloud
sudo incus image import incus.tar.xz rootfs.squashfs --alias ubuntu-24.04-base
```

脚本随后启动临时容器 `verify-base`，等 cloud-init 完成后检查 apt 源、cloud-init 版本与 `apt-get update`，退出时自动删除该容器。

镜像事实（`image-defs/ubuntu.yaml`）：debootstrap 源与 `sources.list` 均指向 tuna（amd64 用 `/ubuntu`，arm 系用 `/ubuntu-ports`）；cloud 变体装 cloud-init；netplan DHCP；`ubuntu` 用户 `sudo NOPASSWD`；源是 deb822 格式，键为 `URIs:`；post-packages 动作改写 cloud-init 模板并写 `apt_preserve_sources_list: true`，使 tuna 源在 cloud-init 首启重写后仍生效。

症状：`debootstrap: You must specify a suite and a target`。原因：yaml 不写死套件，缺 `-o image.release=`。处理：显式传 `RELEASE`，或用脚本。

产物 `incus.tar.xz` 与 `rootfs.squashfs` 落在 `image-defs/` 下，不入 git。

### 3. 在容器内全量安装

```bash
incus launch ubuntu-24.04-base rt-build
incus file push scripts rt-build/root/ -r
incus exec rt-build -- bash /root/scripts/install-all.sh
```

`install-all.sh` 先装隐式依赖（`ca-certificates curl wget gpg unzip zip xz-utils file`），再按 编译器 → 运行时 → 工具 顺序跑三个分类脚本，不转发过滤器。要装单项用分类脚本，例如 `./install-compilers.sh rust` 或 `./install-runtimes.sh python node`。

安装面事实（按代码）。「安装命令」列是脚本实际执行命令的摘录，省略 `have && skip` 幂等判断；`${变量}` 均为 `lib/common.sh` 的镜像源或版本钉，可用环境变量覆盖。

编译器（`install-compilers.sh`）。组列为中文名，脚本键对照：C 工具链=`c`、Go 语言工具链=`golang`、Rust 工具链=`rust`、Zig 编译器=`zig`、C/C++ 包管理器=`vcpkg`。

| 组 | 项目 | 版本 | 官方来源 | 安装命令（脚本实际执行） |
|------|------|------|------|
| C 工具链 | build-essential、clang、lldb、gdb、cmake、ninja-build、pkg-config、autoconf、automake、libtool、m4、clang-format、clang-tidy、valgrind、strace、ltrace、ccache、musl-tools、zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | Ubuntu noble 源（tuna 镜像） | `apt-get install -y --no-install-recommends build-essential clang lldb gdb cmake ninja-build pkg-config autoconf automake libtool m4 clang-format clang-tidy valgrind strace ltrace ccache musl-tools zlib1g-dev libssl-dev libffi-dev` |
| C 工具链 | FASM | 1.73.32（`FASM_VERSION`） | [flatassembler.net](https://flatassembler.net) | `curl -fSL https://flatassembler.net/fasm-${FASM_VERSION}.tgz`；解到 `/opt/fasm`；`ln -sf /opt/fasm/fasm/fasm.x64 /usr/local/bin/fasm` |
| Go 语言工具链 | Go 工具链 | 1.27.1（`GOLANG_VERSION`） | [go.dev/dl](https://go.dev/dl/)（发行包经南大镜像 `GO_DOWNLOAD`） | `curl -fSL ${GO_DOWNLOAD}/go1.27.1.linux-amd64.tar.gz`；sha256 取 `https://golang.google.cn/dl/?mode=json` 校验；`tar -C /usr/local -xzf`；`go env -w GOPROXY=${GOPROXY} GOSUMDB=${GOSUMDB}` |
| Go 语言工具链 | dlv、gopls、golangci-lint | `@latest` 未钉 | [go-delve/delve](https://github.com/go-delve/delve)、golang.org/x-tools、[golangci/golangci-lint](https://github.com/golangci/golangci-lint) | `go install github.com/go-delve/delve/cmd/dlv@latest`；`go install golang.org/x/tools/gopls@latest`；`go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`；链到 `/usr/local/bin` |
| Go 语言工具链 | 跳板/代理库预热（goproxy、smux、yamux、quic-go、net/proxy、go-socks5 等 6 库） | `go mod tidy` 取最新 | 各库官方仓（经 `GOPROXY`） | 临时 module 写依赖后 `GOFLAGS=-mod=mod go mod tidy && go build ./...`，进模块缓存 |
| Rust 工具链 | rustup、stable toolchain | 随源最新 | [rustup.rs](https://rustup.rs)（经 tuna `RUSTUP_UPDATE_ROOT`） | `curl -fSL ${RUSTUP_UPDATE_ROOT}/dist/x86_64-unknown-linux-gnu/rustup-init`；`./rustup-init -y --default-toolchain stable --profile minimal`；`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo` |
| Rust 工具链 | llvm-tools、rustfmt、clippy、rust-analyzer | 随工具链 | [rust-lang.org](https://www.rust-lang.org)（经 tuna） | `rustup component add llvm-tools rustfmt clippy rust-analyzer`；`rust-lld` 链到 `/usr/local/bin` |
| Rust 工具链 | nightly toolchain | 随源最新 | rust-lang.org（经 tuna） | `rustup toolchain install nightly --profile minimal`（BOF 组 coffee-ldr 构建用） |
| Rust 工具链 | rust-script、cargo-zigbuild、cargo-audit | cargo 未钉 | [rust-lang/rust-script](https://github.com/rust-lang/rust-script)、[rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)、[rustsec/rustsec](https://github.com/rustsec/rustsec)（cargo-audit） | `cargo install rust-script --locked`；`cargo install cargo-zigbuild --locked`；`cargo install cargo-audit --locked`；crates 索引指 tuna sparse |
| Rust 工具链 | 件 crate 生态预热（ureq、tokio、rustls、regex 等 29 个） | `cargo fetch` 取最新 | crates.io（经 tuna sparse） | 临时 crate 写 `Cargo.toml` 依赖后 `cargo fetch --quiet`，进 registry 缓存 |
| Zig 编译器 | zig | 0.16.0（`ZIG_VERSION`）；0.15.2 副本供 BOF 工具链 | [ziglang.org/download](https://ziglang.org/download/) | `curl -fSL https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz`；`tar -C /opt/zig -xJf --strip-components=1`；`ln -sf /opt/zig/zig /usr/local/bin/zig` |
| C/C++ 包管理器（vcpkg） | vcpkg 本体与 12 库（`VCPKG_PKGS`） | `--depth 1` 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) | `apt-get install flex bison`；`git clone --depth 1 https://github.com/microsoft/vcpkg /opt/vcpkg`；`./bootstrap-vcpkg.sh -disableMetrics`；`vcpkg install openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara` |

运行时（`install-runtimes.sh`）。组列为中文名，脚本键对照：Node.js 运行时=`node`、Node 版本管理器=`fnm`、Bun 运行时=`bun`、Python 包管理器=`uv`、Python 3 运行时=`python`、Python 2 运行时=`python2`、DuckDB 分析引擎=`duckdb`、PHP 运行时=`php`、Mono 运行时=`mono`、.NET 运行时=`dotnet`、PowerShell=`pwsh`、Java 工具链管理器=`sdkman`。

| 组 | 项目 | 版本 | 官方来源 | 安装命令（脚本实际执行） |
|------|------|------|------|
| Node.js 运行时 | node、npm、npx | 24.21.0（`NODE_VERSION`） | [nodejs.org](https://nodejs.org) 二进制（npmmirror `NODE_MIRROR`，`SHASUMS256.txt` 校验） | `curl -fSL ${NODE_MIRROR}/v24.21.0/node-v24.21.0-linux-x64.tar.xz`；`sha256sum -c`；`tar -C /opt/node -xJf --strip-components=1`；node、npm、npx 链到 `/usr/local/bin` |
| Node.js 运行时 | 全局 npmrc（registry、disturl、electron_mirror） | — | npmmirror | `npm config set --location=global registry ${NPM_REGISTRY}`；直写 `/opt/node/etc/npmrc`：`disturl=https://npmmirror.com/mirrors/node`、`electron_mirror=https://npmmirror.com/mirrors/electron/` |
| Node.js 运行时 | typescript、prettier、eslint | npm 全局未钉 | [npmjs.com](https://www.npmjs.com)（npmmirror） | `npm install -g typescript`；`npm install -g prettier eslint`；tsc、tsserver、prettier、eslint 链到 `/usr/local/bin` |
| Node.js 运行时 | corepack（pnpm、yarn） | 随 node | [nodejs.org](https://nodejs.org) 自带 | `COREPACK_NPM_REGISTRY=${NPM_REGISTRY} corepack enable` |
| Node.js 运行时 | dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)（npmmirror） | `npm install -g dotnetjs` |
| Node 版本管理器（fnm） | fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)（crates 经 tuna） | `cargo install fnm --locked` |
| Node 版本管理器（fnm） | node 18、20、22、24 | 大版本内最新（`FNM_NODE_VERSIONS`） | nodejs.org 二进制（npmmirror） | `fnm install --node-dist-mirror ${NODE_MIRROR} 18`（20、22、24 同）；`fnm default <最新>`；profile.d 写 `fnm env` |
| Bun 运行时 | bun、bunx | npm 全局未钉 | [bun.sh](https://bun.sh)（npmmirror） | `npm install -g bun`；bun、bunx 链到 `/usr/local/bin`；root 与 ubuntu 各写 `.bunfig.toml` 的 `[install] registry = ${NPM_REGISTRY}` |
| Python 包管理器（uv） | uv | 官方安装器最新 | [astral.sh/uv](https://docs.astral.sh/uv/)（[astral-sh/uv](https://github.com/astral-sh/uv)） | `curl -LsSf https://astral.sh/uv/install.sh \| sh`；`ln -sf ~/.local/bin/uv /usr/local/bin/uv`；写 `/etc/uv/uv.toml`：`[[index]] url = ${PIP_INDEX}`、`default = true` |
| Python 3 运行时 | python3 及 pip、venv、dev | noble 随源 | [python.org](https://www.python.org)（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev`；写 `/etc/pip.conf` 的 `index-url = ${PIP_INDEX}`；不装任何第三方包 |
| Python 3 运行时 | ruff | uv tool 未钉 | [astral-sh/ruff](https://github.com/astral-sh/ruff) | `UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install ruff` |
| Python 3 运行时 | /opt/analytics venv：polars、pyarrow、chdb | 未钉 | PyPI（tuna） | `uv venv /opt/analytics`；`VIRTUAL_ENV=/opt/analytics uv pip install polars pyarrow chdb` |
| DuckDB 分析引擎 | duckdb python 绑定 | 未钉 | [duckdb/duckdb](https://github.com/duckdb/duckdb)（PyPI 经 tuna） | `VIRTUAL_ENV=/opt/analytics uv pip install -U duckdb` |
| DuckDB 分析引擎 | duckdb CLI | release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb) releases | api.github.com 取 latest tag；`curl -fSL https://github.com/duckdb/duckdb/releases/download/<tag>/duckdb_cli-linux-amd64.zip`；`install -m755 /usr/local/bin/duckdb` |
| Python 2 运行时 | python 2.7 | 2.7.18（`PY2_VERSION`），`--enable-shared` | [python.org](https://www.python.org/downloads/release/python-2718/)（源码包经华为云 `PY2_MIRROR`） | `apt-get install libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils libffi-dev`；`curl -fSL ${PY2_MIRROR}/2.7.18/Python-2.7.18.tgz`；`./configure --prefix=/usr/local --enable-shared && make -j$(nproc) && make altinstall` |
| PHP 运行时 | php-cli、php-dev 多版本与 VLD | 7.4、8.1、8.3（`PHP_VERSIONS`） | [php.net](https://www.php.net)（Ondřej Surý 第三方打包，`SURY_MIRROR` 南大镜像；GPG key 从 packages.sury.org 取一次） | `apt-get install php${v}-cli php${v}-dev`；`apt-get install php-pear`；`yes '' \| pecl -q -d php_suffix=${v} install vld-beta`；`phpenmod -v ${v} vld` |
| Mono 运行时 | mono-devel、mono-xbuild | noble 随源 | [mono-project.com](https://www.mono-project.com)（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends mono-devel mono-xbuild` |
| Mono 运行时 | nuget.exe | latest | [nuget.org](https://www.nuget.org/downloads) | `curl -fSL https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o /opt/nuget.exe` |
| .NET 运行时 | .NET SDK | dotnet-sdk-10.0（`DOTNET_SDK`） | [dot.net](https://dot.net)（Ubuntu noble 源即 tuna；MS 仓 24.04 起不提供 .NET） | `apt-get install -y dotnet-sdk-10.0`；root 与 ubuntu 写 `NuGet.Config`：`<clear/>` 后只留 `${NUGET_MIRROR}`（华为 v3） |
| PowerShell | PowerShell | powershell-lts 随仓 | [PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)（packages.microsoft.com，国内无镜像） | `curl -fSL packages-microsoft-prod.deb && dpkg -i`；`apt-get install -y powershell-lts`（退回 `powershell`） |
| Java 工具链管理器（SDKMAN） | sdkman 本体 | 安装器最新 | [sdkman.io](https://sdkman.io) | `curl -fSL https://get.sdkman.io -o sdkman-init.sh`；`SDKMAN_DIR=/usr/local/sdkman bash sdkman-init.sh`；config 关 selfupdate、开 auto_env |
| Java 工具链管理器（SDKMAN） | temurin JDK 8、11、17、21、25 | 小版本随 tuna 目录取最新（`JAVA_VERSIONS`） | [adoptium.net](https://adoptium.net)（tuna `ADOPTIUM_MIRROR`） | tuna 目录取最新 `OpenJDK${major}U-jdk_x64_linux_hotspot_*.tar.gz`；`tar -C /opt/jdk/temurin-<ver> --strip-components=1`；`sdk install java <ver>-tem <本地路径>`；`sdk default java <最后一个>`；java、javac 链到 `/usr/local/bin` |
| Java 工具链管理器（SDKMAN） | maven | 3.9.16（`MAVEN_VERSION`） | [maven.apache.org](https://maven.apache.org)（发行包经 tuna `MAVEN_MIRROR`） | `curl -fSL ${MAVEN_MIRROR}/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz`；`tar -C /opt/maven --strip-components=1`；写 `settings.xml` mirror 指 `${MAVEN_DEP_MIRROR}`（阿里云） |
| Java 工具链管理器（SDKMAN） | gradle | 8.14.3（`GRADLE_VERSION`） | [gradle.org](https://gradle.org)（阿里云 distributions 镜像） | `curl -fSL https://mirrors.aliyun.com/gradle/distributions/v8.14.3/gradle-8.14.3-bin.zip`；`unzip -d /opt/gradle`；root 与 ubuntu 写 `.gradle/init.d/mirrors.gradle` 指阿里云 public 与 gradle-plugin |



工具（`install-tools.sh`）。组列为中文名，脚本键对照：文件与内容搜索=`fd`、结构化代码搜索=`ast-grep`、基础命令行工具=`cli`、终端工作区管理器=`herdr`、逆向分析套件=`ghidra`、逆向分析稳定链=`re`、攻击面测绘工具集=`pd`、Go 安全工具集=`secgo`、Rust 安全工具集=`secrust`、代理与隧道工具集=`pivot`、安全分析工具集=`p0`、命令与控制框架参考=`c2`、信标对象文件工具链=`bof`、Project Zero 工具参考=`pz`、结构化 Shell=`nu`。

| 组 | 项目 | 版本 | 官方来源 | 安装命令（脚本实际执行） |
|------|------|------|------|
| 文件与内容搜索 | fd、ripgrep | noble 随源 | [sharkdp/fd](https://github.com/sharkdp/fd)、[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends fd-find ripgrep`；`ln -sf /usr/bin/fdfind /usr/local/bin/fd` |
| 结构化代码搜索（ast-grep） | ast-grep（`sg`） | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（crates 经 tuna） | `cargo install ast-grep --locked`；`ln -sf /root/.cargo/bin/sg /usr/local/bin/sg` |
| 基础命令行工具 | git、jq、shellcheck、just、tmux、rclone、aria2 | noble 随源 | git-scm.com、jqlang.github.io、shellcheck.net、just.systems、tmux、rclone.org、aria2.github.io（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends git jq shellcheck just tmux rclone aria2`；just 无 apt 包时兜底 `cargo install just --locked` |
| 基础命令行工具 | yq | `go install` 未钉 | [mikefarah/yq](https://github.com/mikefarah/yq)（goproxy.cn） | `go install github.com/mikefarah/yq/v4@latest`；`ln -sf /opt/go/bin/yq /usr/local/bin/yq` |
| 基础命令行工具 | gh（GitHub CLI） | `go install` 未钉 | [cli/cli](https://github.com/cli/cli)（goproxy.cn；官方 apt 源国内无镜像） | `go install github.com/cli/cli/v2/cmd/gh@latest`；`ln -sf /opt/go/bin/gh /usr/local/bin/gh` |
| 终端工作区管理器（herdr） | herdr | 0.9.3（`HERDR_VERSION`），sha256 校验 | [herdr.dev](https://herdr.dev)（[herdrdev/herdr](https://github.com/herdrdev/herdr) release） | `curl -fSL ${GITHUB_MIRROR}https://github.com/herdrdev/herdr/releases/download/v0.9.3/herdr-linux-x86_64`；`sha256sum -c`（`HERDR_SHA256`）；`install -m755 /usr/local/bin/herdr`；aarch64 跳过校验 |
| 逆向分析套件（Ghidra） | ghidra | 12.1.3（`GHIDRA_VERSION`/`GHIDRA_DATE`），sha256 校验 | [ghidra-sre.org](https://ghidra-sre.org)（[NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) release） | `curl -fSL …/download/Ghidra_12.1.3_build/ghidra_12.1.3_PUBLIC_20260817.zip`；`sha256sum -c`；`unzip -d /opt/ghidra`；`launch.properties` 写 `JAVA_HOME_OVERRIDE=<temurin 21>`；`ghidraRun`、`analyzeHeadless` 链到 `/usr/local/bin` |
| 逆向分析稳定链 | 系统库 20 项（binutils、elfutils、file、bsdmainutils、binwalk、yara、libyara-dev、libzip-dev、libpugixml-dev、libcapstone-dev、capstone-tool、meson、ninja、cmake、pkg-config、gcc、g++、python3、python3-pip、python3-venv、zlib1g-dev） | noble 随源 | 各项目官方站（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends binutils elfutils file bsdmainutils binwalk yara libyara-dev libzip-dev libpugixml-dev libcapstone-dev capstone-tool meson ninja-build cmake pkg-config git gcc g++ python3 python3-pip python3-venv zlib1g-dev` |
| 逆向分析稳定链 | rizin | `--depth 1` 未钉 | [rizin.re](https://rizin.re)（[rizinorg/rizin](https://github.com/rizinorg/rizin)） | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/rizinorg/rizin /tmp/rizin`；`meson setup build --buildtype=release`；`meson compile -C build && meson install -C build` |
| 逆向分析稳定链 | rz-ghidra | `--depth 1` 未钉（子模块钉 ghidra ref） | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra) | `git clone --depth 1 --recurse-submodules --shallow-submodules …/rizinorg/rz-ghidra /tmp/rz-ghidra`；`cmake -DCMAKE_BUILD_TYPE=Release -DUSE_SYSTEM_PUGIXML=ON -DRIZIN_INSTALL_PLUGINDIR=$(rizin -qc 'e dir.plugins')`；`cmake --build && cmake --install` |
| 逆向分析稳定链 | sigdb | `--depth 1` 未钉 | [rizinorg/sigdb](https://github.com/rizinorg/sigdb) | `git clone --depth 1 …/rizinorg/sigdb /tmp/sigdb`；`meson setup build --prefix=/usr/local`；`meson install -C build` |
| 逆向分析稳定链 | /opt/re-venv 五库（capstone、keystone-engine、unicorn、lief、yara-python） | 未钉 | PyPI（tuna） | `uv venv /opt/re-venv`；`VIRTUAL_ENV=/opt/re-venv uv pip install capstone keystone-engine unicorn lief yara-python` |
| 攻击面测绘工具集（ProjectDiscovery） | subfinder | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/subfinder](https://github.com/projectdiscovery/subfinder)，goproxy.cn） | `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | dnsx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/dnsx](https://github.com/projectdiscovery/dnsx)，goproxy.cn） | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | naabu | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/naabu](https://github.com/projectdiscovery/naabu)，goproxy.cn） | `go install github.com/projectdiscovery/naabu/v2/cmd/naabu@${PD_VERSION}`；`apt-get install libpcap-dev`；`setcap cap_net_raw,cap_net_admin+eip $(which naabu)` |
| 攻击面测绘工具集（ProjectDiscovery） | httpx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/httpx](https://github.com/projectdiscovery/httpx)，goproxy.cn） | `go install github.com/projectdiscovery/httpx/cmd/httpx@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | nuclei | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei)，goproxy.cn） | `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@${PD_VERSION}`；`nuclei -update-templates` |
| 攻击面测绘工具集（ProjectDiscovery） | katana | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/katana](https://github.com/projectdiscovery/katana)，goproxy.cn） | `go install github.com/projectdiscovery/katana/cmd/katana@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | uncover | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/uncover](https://github.com/projectdiscovery/uncover)，goproxy.cn） | `go install github.com/projectdiscovery/uncover/cmd/uncover@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | cloudlist | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/cloudlist](https://github.com/projectdiscovery/cloudlist)，goproxy.cn） | `go install github.com/projectdiscovery/cloudlist/cmd/cloudlist@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | notify | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/notify](https://github.com/projectdiscovery/notify)，goproxy.cn） | `go install github.com/projectdiscovery/notify/cmd/notify@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | interactsh-client | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/interactsh](https://github.com/projectdiscovery/interactsh)，goproxy.cn） | `go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | chaos | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/chaos-client](https://github.com/projectdiscovery/chaos-client)，goproxy.cn） | `go install github.com/projectdiscovery/chaos-client/cmd/chaos@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | mapcidr | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/mapcidr](https://github.com/projectdiscovery/mapcidr)，goproxy.cn） | `go install github.com/projectdiscovery/mapcidr/cmd/mapcidr@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | asnmap | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/asnmap](https://github.com/projectdiscovery/asnmap)，goproxy.cn） | `go install github.com/projectdiscovery/asnmap/cmd/asnmap@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | tlsx | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/tlsx](https://github.com/projectdiscovery/tlsx)，goproxy.cn） | `go install github.com/projectdiscovery/tlsx/cmd/tlsx@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | proxify | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/proxify](https://github.com/projectdiscovery/proxify)，goproxy.cn） | `go install github.com/projectdiscovery/proxify/cmd/proxify@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | simplehttpserver | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/simplehttpserver](https://github.com/projectdiscovery/simplehttpserver)，goproxy.cn） | `go install github.com/projectdiscovery/simplehttpserver/cmd/simplehttpserver@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | shuffledns | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/shuffledns](https://github.com/projectdiscovery/shuffledns)，goproxy.cn） | `go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@${PD_VERSION}` |
| 攻击面测绘工具集（ProjectDiscovery） | pdtm | `@${PD_VERSION}`（默认 latest） | [projectdiscovery.io](https://projectdiscovery.io)（[projectdiscovery/pdtm](https://github.com/projectdiscovery/pdtm)，goproxy.cn） | `go install github.com/projectdiscovery/pdtm/cmd/pdtm@${PD_VERSION}` |
| Go 安全工具集 | ffuf | `@${SECGO_VERSION}`（默认 latest） | [ffuf/ffuf](https://github.com/ffuf/ffuf)（goproxy.cn） | `go install github.com/ffuf/ffuf/ffuf/v2/cmd/ffuf@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | gobuster | `@${SECGO_VERSION}`（默认 latest） | [OJ/gobuster](https://github.com/OJ/gobuster)（goproxy.cn） | `go install github.com/OJ/gobuster/gobuster/v3/cmd/gobuster@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | dalfox | `@${SECGO_VERSION}`（默认 latest） | [hahwul/dalfox](https://github.com/hahwul/dalfox)（goproxy.cn） | `go install github.com/hahwul/dalfox/dalfox/v2/cmd/dalfox@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | amass | `@${SECGO_VERSION}`（默认 latest） | [owasp-amass/amass](https://github.com/owasp-amass/amass)（goproxy.cn） | `go install github.com/owasp-amass/amass/amass/v4/...@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | chisel | `@${SECGO_VERSION}`（默认 latest） | [jpillora/chisel](https://github.com/jpillora/chisel)（goproxy.cn） | `go install github.com/jpillora/chisel/chisel@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | gitleaks | `@${SECGO_VERSION}`（默认 latest） | [zricethezav/gitleaks](https://github.com/zricethezav/gitleaks)（goproxy.cn） | `go install github.com/zricethezav/gitleaks/gitleaks/v8@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | assetfinder | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/assetfinder](https://github.com/tomnomnom/assetfinder)（goproxy.cn） | `go install github.com/tomnomnom/assetfinder/assetfinder@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | httprobe | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/httprobe](https://github.com/tomnomnom/httprobe)（goproxy.cn） | `go install github.com/tomnomnom/httprobe/httprobe@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | qsreplace | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/qsreplace](https://github.com/tomnomnom/qsreplace)（goproxy.cn） | `go install github.com/tomnomnom/qsreplace/qsreplace@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | waybackurls | `@${SECGO_VERSION}`（默认 latest） | [tomnomnom/waybackurls](https://github.com/tomnomnom/waybackurls)（goproxy.cn） | `go install github.com/tomnomnom/waybackurls/waybackurls@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | gau | `@${SECGO_VERSION}`（默认 latest） | [lc/gau](https://github.com/lc/gau)（goproxy.cn） | `go install github.com/lc/gau/gau/v2/cmd/gau@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | gospider | `@${SECGO_VERSION}`（默认 latest） | [jaeles-project/gospider](https://github.com/jaeles-project/gospider)（goproxy.cn） | `go install github.com/jaeles-project/gospider/gospider@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | gowitness | `@${SECGO_VERSION}`（默认 latest） | [sensepost/gowitness](https://github.com/sensepost/gowitness)（goproxy.cn） | `go install github.com/sensepost/gowitness/gowitness@${SECGO_VERSION:-latest}` |
| Go 安全工具集 | azurehound | `@${SECGO_VERSION}`（默认 latest） | [BloodHoundAD/AzureHound](https://github.com/BloodHoundAD/AzureHound)（goproxy.cn） | `go install github.com/BloodHoundAD/AzureHound/azurehound/v2@${SECGO_VERSION:-latest}` |
| Rust 安全工具集 | rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（crates 经 tuna） | `cargo install rustscan --locked` |
| Rust 安全工具集 | feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（crates 经 tuna） | `cargo install feroxbuster --locked` |
| 代理与隧道工具集 | gost | `@latest` 未钉 | [go-gost/gost](https://github.com/go-gost/gost)（退回 [ginuerzh/gost](https://github.com/ginuerzh/gost)） | `go install github.com/go-gost/gost/cmd/gost@latest` |
| 代理与隧道工具集 | frps、frpc | release latest | [fatedier/frp](https://github.com/fatedier/frp) releases | api.github.com 取 latest tag；`curl …/download/<tag>/frp_<ver>_linux_amd64.tar.gz`；`install -m755 frps frpc /usr/local/bin` |
| 代理与隧道工具集 | wstunnel | cargo 未钉 | [erebe/wstunnel](https://github.com/erebe/wstunnel) | `cargo install --git ${GITHUB_MIRROR}https://github.com/erebe/wstunnel --locked` |
| 代理与隧道工具集 | rathole | cargo 未钉 | [rathole-org/rathole](https://github.com/rathole-org/rathole) | `cargo install rathole`（退回 `cargo install --git …/rathole-org/rathole`） |
| 代理与隧道工具集 | bore | cargo 未钉 | [ekzhang/bore](https://github.com/ekzhang/bore)（bore-cli crate） | `cargo install bore-cli --locked` |
| 安全分析工具集 | apt 22 包（gdb-multiarch、qemu-user-static、python3-pwntools、python3-ropgadget、checksec、patchelf、nasm、xxd、squashfs-tools、nmap、sqlmap、tcpdump、tshark、mitmproxy、python3-scapy、upx-ucl、7zip、libimage-exiftool-perl、ssdeep、python3-impacket、john、hashid） | noble 随源 | pwntools.com、nasm.us、nmap.org、sqlmap.org、wireshark.org、mitmproxy.org、scapy.net、upx.github.io、7-zip.org、exiftool.org、openwall.com 等（Ubuntu 打包，tuna） | `apt-get install -y --no-install-recommends gdb-multiarch qemu-user-static python3-pwntools python3-ropgadget checksec patchelf nasm xxd squashfs-tools nmap sqlmap tcpdump tshark mitmproxy python3-scapy upx-ucl 7zip libimage-exiftool-perl ssdeep python3-impacket john hashid` |
| 安全分析工具集 | flare-floss、oletools | 未钉 | [mandiant/flare-floss](https://github.com/mandiant/flare-floss)、[decalage2/oletools](https://github.com/decalage2/oletools)（PyPI 经 tuna） | `VIRTUAL_ENV=/opt/re-venv uv pip install flare-floss oletools` |
| 安全分析工具集 | netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec) | `VIRTUAL_ENV=/opt/re-venv uv pip install netexec`；缺包退回 `uv pip install git+https://github.com/Pennyw0rth/NetExec` |
| 安全分析工具集 | pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg) | `UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install git+${GITHUB_MIRROR}https://github.com/pwndbg/pwndbg` |
| 安全分析工具集 | jadx | 1.5.3（`JADX_VERSION`） | [skylot/jadx](https://github.com/skylot/jadx) releases | `curl -fSL …/skylot/jadx/releases/download/v1.5.3/jadx-1.5.3.zip`；`unzip -d /opt/jadx`；`ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx` |
| 安全分析工具集 | apktool | 2.12.0（`APKTOOL_VERSION`） | [apktool.org](https://apktool.org)（[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)） | `curl -fSL …/iBotPeaches/Apktool/releases/download/v2.12.0/apktool_2.12.0.jar -o /opt/apktool/apktool.jar`；写 `/usr/local/bin/apktool` 包装脚本 `exec java -jar /opt/apktool/apktool.jar` |
| 安全分析工具集 | capa | 9.4.0（`CAPA_VERSION`） | [mandiant/capa](https://github.com/mandiant/capa) releases | `curl -fSL …/mandiant/capa/releases/download/v9.4.0/capa-v9.4.0-linux.zip`；`unzip -d /opt/capa`；`capa` 链到 `/usr/local/bin` |
| 安全分析工具集 | capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/mandiant/capa-rules /opt/capa-rules` |
| 安全分析工具集 | SecLists 词表 | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/danielmiessler/SecLists /opt/SecLists` |
| 安全分析工具集 | yara 规则（Yara-Rules/rules） | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/Yara-Rules/rules /opt/yara-rules` |
| 安全分析工具集 | pdfid、pdf-parser | `--depth 1` 未钉 | [DidierStevens 工具集](https://blog.didierstevens.com)（[DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite)） | `git clone --depth 1 …/DidierStevens/DidierStevensSuite /tmp/dss`；`cp pdfid.py pdf-parser.py /usr/local/bin/`；shebang 改 `#!/usr/bin/env python3` |
| 命令与控制框架参考（C2） | sliver | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/bishopfox/sliver /opt/c2-ref/sliver`；只克隆，不安装不运行 |
| 命令与控制框架参考（C2） | merlin | `--depth 1` 未钉 | [Ne0nd0g/merlin](https://github.com/Ne0nd0g/merlin) | `git clone --depth 1 …/Ne0nd0g/merlin /opt/c2-ref/merlin`；只克隆 |
| 命令与控制框架参考（C2） | Empire | `--depth 1` 未钉 | [BC-SECURITY/Empire](https://github.com/BC-SECURITY/Empire) | `git clone --depth 1 …/BC-SECURITY/Empire /opt/c2-ref/Empire`；只克隆 |
| 命令与控制框架参考（C2） | Covenant | `--depth 1` 未钉 | [cobbr/Covenant](https://github.com/cobbr/Covenant) | `git clone --depth 1 …/cobbr/Covenant /opt/c2-ref/Covenant`；只克隆 |
| 命令与控制框架参考（C2） | ysoserial | `--depth 1` 未钉 | [frohoff/ysoserial](https://github.com/frohoff/ysoserial) | `git clone --depth 1 …/frohoff/ysoserial /opt/c2-ref/ysoserial`；只克隆（构建需 JDK 8） |
| 命令与控制框架参考（C2） | ysoserial.net | `--depth 1` 未钉 | [pwntester/ysoserial.net](https://github.com/pwntester/ysoserial.net) | `git clone --depth 1 …/pwntester/ysoserial.net /opt/c2-ref/ysoserial.net`；只克隆（运行走 mono） |
| 信标对象文件工具链（BOF） | mingw-w64 | noble 随源 | Ubuntu 打包（tuna） | `apt-get install -y --no-install-recommends mingw-w64` |
| 信标对象文件工具链（BOF） | COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader) | `git clone --depth 1 …/trustedsec/COFFLoader /tmp/coffloader`；`make bof`（交叉编 Windows 版） |
| 信标对象文件工具链（BOF） | atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/rasta-mouse/atomic-bofs /opt/atomic-bofs` |
| 信标对象文件工具链（BOF） | coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee)（crate 名 coffee-ldr） | `rustup toolchain install nightly`；`cargo +nightly install coffee-ldr --locked`（退回 `--git …/hakaioffsec/coffee`）；链到 `/usr/local/bin` |
| 信标对象文件工具链（BOF） | bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher) | 下 zig 0.15.2 专用副本 `/opt/zig-0.15.2`；`git clone --depth 1 …/The-Z-Labs/bof-launcher /tmp/bof-launcher`；`/opt/zig-0.15.2/zig build -Doptimize=ReleaseSafe`；`install -m755 /usr/local/bin/bof-launcher` |
| 信标对象文件工具链（BOF） | BOF-CATALOG.md | main raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) | `curl -fsSL ${GITHUB_MIRROR}https://github.com/chryzsh/awesome-bof/raw/main/BOF-CATALOG.md -o /opt/bofs/BOF-CATALOG.md` |
| Project Zero 工具参考 | sandbox-attacksurface-analysis-tools | `--depth 1` 未钉 | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools)（[Project Zero](https://googleprojectzero.blogspot.com)） | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools /opt/pz-sandbox-tools`；只克隆，dotnet 构建尽力 |
| Project Zero 工具参考 | DotNetToJScript | `--depth 1` 未钉 | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/tyranid/DotNetToJScript /opt/DotNetToJScript`；只克隆 |
| Project Zero 工具参考 | windows-logical-eop-workshop | `--depth 1` 未钉 | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) | `git clone --depth 1 ${GITHUB_MIRROR}https://github.com/tyranid/windows-logical-eop-workshop /opt/windows-logical-eop-workshop`；只克隆 |
| Project Zero 工具参考 | oleviewdotnet | 全克隆含子模块 | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) | `git clone --recurse-submodules ${GITHUB_MIRROR}https://github.com/tyranid/oleviewdotnet /opt/oleviewdotnet`；只克隆（NtApiDotNet 是嵌套子模块） |
| 结构化 Shell（Nushell） | nu | release latest | [nushell.sh](https://www.nushell.sh)（[nushell/nushell](https://github.com/nushell/nushell)） | api.github.com 取 latest tag；`curl …/download/<tag>/nu-<tag>-x86_64-unknown-linux-gnu.tar.gz`；`install -m755 nu /usr/local/bin/nu` |
### 4. 发布 pi-rs-runtime 镜像

```bash
incus stop rt-build
incus publish rt-build --alias pi-rs-runtime
incus delete rt-build
```

发布别名固定为 `pi-rs-runtime`。发布后开实例：`incus launch pi-rs-runtime <名>`。

验收建议（重跑 `install-all.sh` 后）：核对版本输出、镜像配置落点、`/opt/analytics` 与 `/opt/re-venv` 的 venv 隔离、以及 `/usr/local/bin` 链接对 `ubuntu` 用户可执行。

### 5. 开发实例挂载仓库

`dev-instance.sh` 把仓库目录以 `shift=true` 挂进开发容器，改完在 Pi 里 `/reload` 生效，不走 `incus publish`:

```bash
./scripts/dev-instance.sh pi-dev /path/to/repo
```

等价于：

```bash
incus launch pi-box-dev pi-dev
incus config device add pi-dev src disk \
  source=/path/to/repo path=/home/ubuntu/workspace shift=true
incus exec pi-dev -- sudo -u ubuntu -i bash -lc 'cd /home/ubuntu/workspace && pi'
```

事实：实例不存在才创建；`src` 设备不存在才添加；镜像别名取 `PI_IMAGE`（默认 `pi-box-dev`，该镜像的构建不在本仓，见“已知限制与未决项”）；`shift=true` 需要容器开启 idmap；挂载的是宿主管的仓库，未提交改动不进任何镜像。

### 6. （可选）给实例加 VNC 屏幕

容器内（ubuntu 用户）:

```bash
./vnc-screen.sh setup
VNC_PASS='<口令>' ./vnc-screen.sh start
./vnc-screen.sh status
```

宿主侧一次性把 5900 引到宿主回环：

```bash
sudo incus config device add <实例> vnc proxy \
  listen=tcp:127.0.0.1:5900 connect=tcp:127.0.0.1:5900
```

事实：Xvfb 起 `:99`（1280x800x24），x11vnc 只绑 `127.0.0.1:5900`；`start` 内置 `status` 校验；屏幕不含浏览器，Chrome 由后续定制构建提供；无 `VNC_PASS` 时生成随机口令并打印一次。

## 软件清单归档

逐项列出镜像内全部软件与隔离环境，apt 包逐个一行（含构建依赖）；版本与来源口径同安装面表。ProjectDiscovery 与 Go 安全工具集各 18、14 个 CLI 在安装面表中已逐行，此处不重复；命令与控制框架参考、Project Zero 工具参考只克隆不安装，见「已知限制与未决项」。

### 构建与编译

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
| nasm | noble 随源 | Ubuntu noble 源（tuna） |
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
| rustup 与 stable toolchain | 随源最新 | [rustup.rs](https://rustup.rs)（tuna rustup） |
| nightly toolchain | 随源最新 | rust-lang.org（tuna） |
| llvm-tools、rustfmt、clippy、rust-analyzer | 随工具链 | rust-lang.org（tuna） |
| rust-script | cargo 未钉 | [rust-lang/rust-script](https://github.com/rust-lang/rust-script)（tuna crates） |
| cargo-zigbuild | cargo 未钉 | [rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)（tuna crates） |
| cargo-audit | cargo 未钉 | [rustsec/rustsec](https://github.com/rustsec/rustsec)（tuna crates） |
| zig | 0.16.0 | [ziglang.org](https://ziglang.org/download/) 直下 |
| zig（0.15.2 副本） | 0.15.2 | ziglang.org 直下，供 bof-launcher 构建 |
| vcpkg | `--depth 1` 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) GitHub 直下 |
| vcpkg 库 12 个 | `VCPKG_PKGS` 集 | vcpkg 源码编译：openssl、zlib、curl、sqlite3、libpcap、fmt、spdlog、nlohmann-json、rapidjson、cpp-httplib、mbedtls、yara |
| maven | 3.9.16 | [maven.apache.org](https://maven.apache.org)（tuna apache 镜像） |
| gradle | 8.14.3 | [gradle.org](https://gradle.org)（阿里云 distributions 镜像） |

### 运行时与语言

| 软件 | 版本 | 来源 |
|------|------|------|
| python3、pip、venv、dev | noble 随源 | Ubuntu noble 源（tuna） |
| python 2.7 | 2.7.18，`--enable-shared` | [python.org](https://www.python.org/downloads/release/python-2718/)（华为云镜像） |
| node | 24.21.0 | [nodejs.org](https://nodejs.org) 二进制（npmmirror，SHASUMS256 校验） |
| node（fnm 多版本） | 18、20、22、24 大版本内最新 | nodejs.org 二进制（npmmirror） |
| typescript、prettier、eslint | npm 全局未钉 | [npmjs.com](https://www.npmjs.com)（npmmirror） |
| corepack（pnpm、yarn） | 随 node | nodejs.org 自带（`COREPACK_NPM_REGISTRY` 指 npmmirror） |
| dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)（npmmirror） |
| fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)（tuna crates） |
| bun、bunx | npm 全局未钉 | [bun.sh](https://bun.sh)（npmmirror） |
| uv | 官方安装器最新 | [astral.sh/uv](https://docs.astral.sh/uv/) |
| ruff | uv tool 未钉 | [astral-sh/ruff](https://github.com/astral-sh/ruff)（tuna PyPI） |
| polars、pyarrow、chdb | 未钉 | PyPI（tuna），`/opt/analytics` venv |
| duckdb（python 与 CLI） | CLI 取 release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb)（PyPI 经 tuna） |
| php-cli 与 php-dev（7.4、8.1、8.3） | sury 随源 | sury 源（南大镜像） |
| VLD（vld-beta） | pecl 逐版本尽力 | pecl（sury 多版本 `php_suffix`） |
| mono-devel、mono-xbuild | noble 随源 | Ubuntu noble 源（tuna） |
| nuget.exe | latest | [nuget.org](https://www.nuget.org/downloads) |
| .NET SDK | dotnet-sdk-10.0 | [dot.net](https://dot.net)（Ubuntu noble 源即 tuna） |
| powershell-lts | MS 仓随源 | packages.microsoft.com（国内无镜像） |
| sdkman 本体 | 安装器最新 | [sdkman.io](https://sdkman.io) |
| temurin JDK（8、11、17、21、25） | 小版本随 tuna 目录取最新 | [adoptium.net](https://adoptium.net)（tuna Adoptium） |

### 隔离环境与目录

| 软件 | 版本 | 来源 |
|------|------|------|
| /opt/analytics | uv venv | polars、pyarrow、chdb、duckdb；系统 python3 保持干净 |
| /opt/re-venv | uv venv | capstone、keystone-engine、unicorn、lief、yara-python、FLOSS、oletools、netexec |
| /opt/uv-tools | uv tool 根 | ruff、pwndbg 的 shim 与本体，ubuntu 可读 |
| /usr/local/sdkman | SDKMAN 目录 | temurin 注册、maven、gradle |
| fnm 数据目录 | `~/.local/share/fnm` | node 18、20、22、24 多版本 |
| NuGet 配置 | 各用户 `NuGet.Config` | `<clear/>` 后只留华为 v3 源 |

### 基础命令行与系统

| 软件 | 版本 | 来源 |
|------|------|------|
| ca-certificates、curl、wget、gpg | noble 随源 | Ubuntu noble 源（tuna）（install-all 隐式依赖） |
| unzip、zip、xz-utils、file | noble 随源 | Ubuntu noble 源（tuna） |
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

### 搜索与文本

| 软件 | 版本 | 来源 |
|------|------|------|
| fd | noble 随源（`fd-find` 链 `fd`） | Ubuntu noble 源（tuna） |
| ripgrep | noble 随源 | Ubuntu noble 源（tuna） |
| ast-grep | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（tuna crates） |

### 图形与远程屏幕

| 软件 | 版本 | 来源 |
|------|------|------|
| xvfb | noble 随源 | Ubuntu noble 源（tuna） |
| x11vnc | noble 随源 | Ubuntu noble 源（tuna） |
| x11-utils | noble 随源 | Ubuntu noble 源（tuna） |
| xterm | noble 随源 | Ubuntu noble 源（tuna） |

### 逆向分析

| 软件 | 版本 | 来源 |
|------|------|------|
| binutils、elfutils、bsdmainutils | noble 随源 | Ubuntu noble 源（tuna） |
| binwalk | noble 随源 | Ubuntu noble 源（tuna） |
| yara、libyara-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libzip-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libpugixml-dev | noble 随源 | Ubuntu noble 源（tuna） |
| libcapstone-dev、capstone-tool | noble 随源 | Ubuntu noble 源（tuna） |
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
| pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg)（uv tool） |
| jadx | 1.5.3 | [skylot/jadx](https://github.com/skylot/jadx) releases |
| apktool | 2.12.0 | [apktool.org](https://apktool.org)（[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)） |
| capa | 9.4.0 | [mandiant/capa](https://github.com/mandiant/capa) releases |
| flare-floss | 未钉 | [mandiant/flare-floss](https://github.com/mandiant/flare-floss)（PyPI 经 tuna） |
| oletools | 未钉 | [decalage2/oletools](https://github.com/decalage2/oletools)（PyPI 经 tuna） |
| pdfid、pdf-parser | `--depth 1` 未钉 | [DidierStevens 工具集](https://blog.didierstevens.com)（[DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite)） |
| COFFLoader（COFFLoader64.exe） | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader)（mingw 交叉编译） |
| atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) |
| coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee) |
| bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher)（zig 0.15.2 构建） |

### 安全测试

| 软件 | 版本 | 来源 |
|------|------|------|
| libpcap-dev | noble 随源（naabu 依赖） | Ubuntu noble 源（tuna） |
| python3-pwntools | noble 随源（只走 apt） | Ubuntu noble 源（tuna） |
| python3-ropgadget | noble 随源 | Ubuntu noble 源（tuna） |
| checksec | noble 随源 | Ubuntu noble 源（tuna） |
| patchelf | noble 随源 | Ubuntu noble 源（tuna） |
| nmap | noble 随源 | Ubuntu noble 源（tuna） |
| sqlmap | noble 随源 | Ubuntu noble 源（tuna） |
| python3-impacket | noble 随源 | Ubuntu noble 源（tuna） |
| john | noble 随源 | Ubuntu noble 源（tuna） |
| hashid | noble 随源 | Ubuntu noble 源（tuna） |
| netexec | 未钉 | [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec)（PyPI 经 tuna，缺包退回 git） |
| rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)（tuna crates） |
| feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)（tuna crates） |
| SecLists 词表 | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |
| capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) |
| yara 规则（Yara-Rules/rules） | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) |

### 网络分析

| 软件 | 版本 | 来源 |
|------|------|------|
| tcpdump | noble 随源 | Ubuntu noble 源（tuna） |
| tshark | noble 随源 | Ubuntu noble 源（tuna） |
| mitmproxy | noble 随源 | Ubuntu noble 源（tuna） |
| python3-scapy | noble 随源 | Ubuntu noble 源（tuna） |

### 代理与隧道

| 软件 | 版本 | 来源 |
|------|------|------|
| gost | `@latest` 未钉 | [go-gost/gost](https://github.com/go-gost/gost)（goproxy.cn） |
| frps、frpc | release latest | [fatedier/frp](https://github.com/fatedier/frp) releases |
| wstunnel | cargo 未钉 | [erebe/wstunnel](https://github.com/erebe/wstunnel) |
| rathole | cargo 未钉 | [rathole-org/rathole](https://github.com/rathole-org/rathole) |
| bore | cargo 未钉 | [ekzhang/bore](https://github.com/ekzhang/bore)（bore-cli crate） |

## 已知限制与未决项

- 版本未钉：temurin 小版本随 tuna Adoptium 目录取最新；`dlv`、`gopls`、`golangci-lint` 与 projectdiscovery 全家桶、Go 安全工具组用 `@latest`(`have && skip` 意味着“首次装到的那份”);rizin、rz-ghidra、sigdb、SecLists、yara 规则均为 `--depth 1` 未钉提交；pwndbg 从 git 源装、未钉 rev。
- zig 发行包无国内镜像，直下且无验签。minisig 公钥：`RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U`。验签未做。
- `/root` 0700 的残留面：rust 工具链在 `/opt`（`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`),rust 段新装产物都归 /opt;ast-grep、Rust 安全工具、代理跳板、coffee-ldr 与 fnm 经 root 的 `~/.cargo` 安装再链到 `/usr/local/bin`;tools 各组 `GOPATH=/opt/go`(dlv/gopls/golangci-lint、projectdiscovery 全家桶、Go 安全工具、代理跳板归 /opt/go 并链出）；基础 CLI 组的 yq 与 gh 未设 GOPATH，产物在 /root/go 且只链 yq,`ubuntu` 用户对 gh 不可执行。已有的 /root/.cargo、/root/go 环境不受影响。
- `install_secrust` 日志声明装 rustscan、feroxbuster、findomain，实际只装前两个；findomain 注释建议改用 [Findomain/Findomain releases](https://github.com/Findomain/Findomain/releases) 预编译。
- `install_php` 中 PHP 7.4 已无官方支持，样本动态执行需在无网络、无生产数据挂载的环境里跑，并加 `-d opcache.jit=off`；当前部署链未强制该隔离面。python2 同理（已通过实测含 `import ssl`)。
- VNC 屏幕无 Chrome 与 noVNC;Chrome 官方版不装，后续定制构建。
- C2 框架（sliver、merlin、Empire、Covenant、ysoserial 系）只克隆到 `/opt/c2-ref` 作参考，不安装不运行；.NET 参考项目（pz 组）同样只克隆。
- `pi-box-dev` 镜像（pi 二进制、pi-web、定制 Chrome）的构建脚本不在本仓，`build.sh` 未做。
- 备选路线：单个实例可直接 `incus launch images:ubuntu/24.04`,`incus stop` 后 `incus publish --alias <名>` 固化，不经 distrobuilder。

本仓只维护 yaml、脚本与文档；镜像产物不入库；distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`，失败后可手动清理。

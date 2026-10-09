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
|------|------|------|------|------|
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

安装面事实（按代码）:

编译器（`install-compilers.sh`）:

| 组 | 项目 | 版本 | 来源 |
|------|------|------|------|
| c | build-essential、clang、lldb、gdb、cmake、ninja、autoconf、automake、libtool、clang-format、clang-tidy、valgrind、strace、ltrace、ccache、musl-tools、zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | Ubuntu apt（tuna） |
| c | FASM | 1.73.32（`FASM_VERSION`） | flatassembler.net 直下，无镜像 |
| golang | Go 工具链 | 1.27.1（`GOLANG_VERSION`） | go.dev 发行包，南大镜像，sha256 校验 |
| rust | rustup、rustc、nightly、llvm-tools、rustfmt、clippy、rust-analyzer | 随源最新 | rustup.rs（tuna rustup）；`/opt/rustup`、`/opt/cargo` |
| rust | rust-script、cargo-zigbuild、cargo-audit | cargo 未钉 | crates.io（tuna crates） |
| zig | zig | 0.16.0（`ZIG_VERSION`）；0.15.2 副本供 BOF 工具链 | ziglang.org 直下，仅 amd64 与 arm64 |
| vcpkg | vcpkg 与 12 库（`VCPKG_PKGS`） | 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg)，GitHub 直下，源码编译 |

运行时（`install-runtimes.sh`）:

| 组 | 项目 | 版本 | 来源 |
|------|------|------|------|
| node | node、npm、npx | 24.21.0（`NODE_VERSION`） | nodejs/node 二进制，npmmirror，`SHASUMS256.txt` 校验；装 `/opt/node` |
| node | typescript、prettier、eslint | npm 全局未钉 | npmmirror |
| node | corepack（pnpm、yarn） | 随 node | `COREPACK_NPM_REGISTRY` 指 npmmirror |
| node | dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)，npmmirror |
| fnm | fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)，crates 走 tuna |
| fnm | node 18、20、22、24 | 大版本内最新（`FNM_NODE_VERSIONS`） | npmmirror 二进制（`--node-dist-mirror`） |
| bun | bun | npm 全局未钉 | [oven-sh/bun](https://github.com/oven-sh/bun)，npmmirror |
| uv | uv | 安装器最新 | astral.sh/uv（[astral-sh/uv](https://github.com/astral-sh/uv)）；索引写 `/etc/uv/uv.toml`（tuna） |
| python | python3 | noble 随源 | Ubuntu apt（tuna）；索引写 `/etc/pip.conf`，不装第三方包 |
| python | polars、pyarrow、chdb | 未钉 | PyPI（tuna），`/opt/analytics` venv |
| duckdb | duckdb（python 与 CLI） | CLI 取 release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb) release；python 绑定在 `/opt/analytics` |
| python2 | python | 2.7.18（`PY2_VERSION`），`--enable-shared` | python.org 源码包，华为云镜像 |
| php | php-cli、php-dev、VLD | 7.4、8.1、8.3（`PHP_VERSIONS`） | sury 源（南大镜像 `SURY_MIRROR`）；VLD 逐版本尽力编译 |
| mono | mono-devel、mono-xbuild | noble 随源 | Ubuntu apt（tuna） |
| mono | nuget.exe | latest | dist.nuget.org，存 `/opt/nuget.exe` |
| dotnet | .NET SDK | dotnet-sdk-10.0（`DOTNET_SDK`） | Ubuntu noble 源（即 tuna） |
| pwsh | PowerShell | powershell-lts 随仓 | packages.microsoft.com |
| sdkman | sdkman 本体 | 安装器最新 | get.sdkman.io，装 `/usr/local/sdkman` |
| sdkman | temurin JDK | 8、11、17、21、25（`JAVA_VERSIONS`），小版本随目录取最新 | Adoptium（tuna `ADOPTIUM_MIRROR`），本地路径注册 |
| sdkman | maven | 3.9.16（`MAVEN_VERSION`） | tuna apache 镜像；依赖写 settings.xml 指阿里云 |
| sdkman | gradle | 8.14.3（`GRADLE_VERSION`） | 阿里云 distributions；依赖经 init.d 指阿里云 |

工具（`install-tools.sh`，组键见上文 `TOOLS_ALL` 名单）:

| 组 | 项目 | 版本 | 来源 |
|------|------|------|------|
| fd | fd、ripgrep | noble 随源 | Ubuntu apt（tuna） |
| ast-grep | ast-grep（`sg`） | cargo 未钉 | [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)，crates 走 tuna |
| 基础 CLI | git、jq、shellcheck、just、tmux、rclone、aria2 | noble 随源 | Ubuntu apt（tuna） |
| 基础 CLI | yq | `go install` 未钉 | [mikefarah/yq](https://github.com/mikefarah/yq)，goproxy.cn |
| 基础 CLI | gh | `go install` 未钉 | [cli/cli](https://github.com/cli/cli)，goproxy.cn |
| herdr | herdr | 0.9.3（`HERDR_VERSION`），sha256 校验 | [herdrdev/herdr](https://github.com/herdrdev/herdr) release，装 `/usr/local/bin` |
| ghidra | ghidra | 12.1.3（`GHIDRA_VERSION`/`GHIDRA_DATE`），sha256 校验 | [NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) release；`JAVA_HOME_OVERRIDE` 钉 temurin 21 |
| 逆向稳定链 | 系统库（binutils、elfutils、file、bsdmainutils、binwalk、yara、libyara-dev、libzip-dev、libpugixml-dev、libcapstone-dev、capstone-tool、meson、ninja、cmake、pkg-config、gcc、g++、python3、python3-pip、python3-venv、zlib1g-dev） | noble 随源 | Ubuntu apt（tuna） |
| 逆向稳定链 | rizin | `--depth 1` 未钉 | [rizinorg/rizin](https://github.com/rizinorg/rizin)，源码编译 |
| 逆向稳定链 | rz-ghidra | `--depth 1` 未钉（子模块钉 ghidra ref） | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra)，源码编译 |
| 逆向稳定链 | sigdb | `--depth 1` 未钉 | [rizinorg/sigdb](https://github.com/rizinorg/sigdb) |
| 逆向稳定链 | re-venv 五库（capstone、keystone-engine、unicorn、lief、yara-python） | 未钉 | PyPI（tuna），`/opt/re-venv` |
| projectdiscovery 全家桶 | subfinder | `@latest`（`PD_VERSION`） | [projectdiscovery/subfinder](https://github.com/projectdiscovery/subfinder) |
| projectdiscovery 全家桶 | dnsx | 同上 | [projectdiscovery/dnsx](https://github.com/projectdiscovery/dnsx) |
| projectdiscovery 全家桶 | naabu | 同上 | [projectdiscovery/naabu](https://github.com/projectdiscovery/naabu)；setcap cap_net_raw |
| projectdiscovery 全家桶 | httpx | 同上 | [projectdiscovery/httpx](https://github.com/projectdiscovery/httpx) |
| projectdiscovery 全家桶 | nuclei | 同上 | [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei)；模板 `-update-templates` 尽力 |
| projectdiscovery 全家桶 | katana | 同上 | [projectdiscovery/katana](https://github.com/projectdiscovery/katana) |
| projectdiscovery 全家桶 | uncover | 同上 | [projectdiscovery/uncover](https://github.com/projectdiscovery/uncover) |
| projectdiscovery 全家桶 | cloudlist | 同上 | [projectdiscovery/cloudlist](https://github.com/projectdiscovery/cloudlist) |
| projectdiscovery 全家桶 | notify | 同上 | [projectdiscovery/notify](https://github.com/projectdiscovery/notify) |
| projectdiscovery 全家桶 | interactsh-client | 同上 | [projectdiscovery/interactsh](https://github.com/projectdiscovery/interactsh) |
| projectdiscovery 全家桶 | chaos | 同上 | [projectdiscovery/chaos-client](https://github.com/projectdiscovery/chaos-client) |
| projectdiscovery 全家桶 | mapcidr | 同上 | [projectdiscovery/mapcidr](https://github.com/projectdiscovery/mapcidr) |
| projectdiscovery 全家桶 | asnmap | 同上 | [projectdiscovery/asnmap](https://github.com/projectdiscovery/asnmap) |
| projectdiscovery 全家桶 | tlsx | 同上 | [projectdiscovery/tlsx](https://github.com/projectdiscovery/tlsx) |
| projectdiscovery 全家桶 | proxify | 同上 | [projectdiscovery/proxify](https://github.com/projectdiscovery/proxify) |
| projectdiscovery 全家桶 | simplehttpserver | 同上 | [projectdiscovery/simplehttpserver](https://github.com/projectdiscovery/simplehttpserver) |
| projectdiscovery 全家桶 | shuffledns | 同上 | [projectdiscovery/shuffledns](https://github.com/projectdiscovery/shuffledns) |
| projectdiscovery 全家桶 | pdtm | 同上 | [projectdiscovery/pdtm](https://github.com/projectdiscovery/pdtm) |
| Go 安全工具 | ffuf | `@latest`（`SECGO_VERSION`） | [ffuf/ffuf](https://github.com/ffuf/ffuf) |
| Go 安全工具 | gobuster | 同上 | [OJ/gobuster](https://github.com/OJ/gobuster) |
| Go 安全工具 | dalfox | 同上 | [hahwul/dalfox](https://github.com/hahwul/dalfox) |
| Go 安全工具 | amass | 同上 | [owasp-amass/amass](https://github.com/owasp-amass/amass) |
| Go 安全工具 | chisel | 同上 | [jpillora/chisel](https://github.com/jpillora/chisel) |
| Go 安全工具 | gitleaks | 同上 | [zricethezav/gitleaks](https://github.com/zricethezav/gitleaks) |
| Go 安全工具 | assetfinder | 同上 | [tomnomnom/assetfinder](https://github.com/tomnomnom/assetfinder) |
| Go 安全工具 | httprobe | 同上 | [tomnomnom/httprobe](https://github.com/tomnomnom/httprobe) |
| Go 安全工具 | qsreplace | 同上 | [tomnomnom/qsreplace](https://github.com/tomnomnom/qsreplace) |
| Go 安全工具 | waybackurls | 同上 | [tomnomnom/waybackurls](https://github.com/tomnomnom/waybackurls) |
| Go 安全工具 | gau | 同上 | [lc/gau](https://github.com/lc/gau) |
| Go 安全工具 | gospider | 同上 | [jaeles-project/gospider](https://github.com/jaeles-project/gospider) |
| Go 安全工具 | gowitness | 同上 | [sensepost/gowitness](https://github.com/sensepost/gowitness) |
| Go 安全工具 | azurehound | 同上 | [BloodHoundAD/AzureHound](https://github.com/BloodHoundAD/AzureHound) |
| Rust 安全工具 | rustscan | cargo 未钉 | [rustscan/rustscan](https://github.com/rustscan/rustscan)，crates 走 tuna |
| Rust 安全工具 | feroxbuster | cargo 未钉 | [epi052/feroxbuster](https://github.com/epi052/feroxbuster)，crates 走 tuna |
| 代理跳板 | gost | `go install` 未钉 | [go-gost/gost](https://github.com/go-gost/gost)（退回 ginuerzh/gost） |
| 代理跳板 | frps、frpc | release latest | [fatedier/frp](https://github.com/fatedier/frp) release 预编译 |
| 代理跳板 | wstunnel | cargo 未钉 | [erebe/wstunnel](https://github.com/erebe/wstunnel) |
| 代理跳板 | rathole | cargo 未钉 | [rathole-org/rathole](https://github.com/rathole-org/rathole) |
| 代理跳板 | bore | cargo 未钉 | bore-cli crate（[ekzhang/bore](https://github.com/ekzhang/bore)） |
| P0 补齐批 | apt 22 包（gdb-multiarch、qemu-user-static、python3-pwntools、python3-ropgadget、checksec、patchelf、nasm、xxd、squashfs-tools、nmap、sqlmap、tcpdump、tshark、mitmproxy、python3-scapy、upx-ucl、7zip、libimage-exiftool-perl、ssdeep、python3-impacket、john、hashid） | noble 随源 | Ubuntu apt（tuna） |
| P0 补齐批 | flare-floss、oletools、netexec | 未钉 | PyPI（tuna），`/opt/re-venv`；netexec 缺包退回 [Pennyw0rth/NetExec](https://github.com/Pennyw0rth/NetExec) |
| P0 补齐批 | pwndbg | git 源未钉 | [pwndbg/pwndbg](https://github.com/pwndbg/pwndbg)，uv tool |
| P0 补齐批 | jadx | 1.5.3（`JADX_VERSION`） | [skylot/jadx](https://github.com/skylot/jadx) release |
| P0 补齐批 | apktool | 2.12.0（`APKTOOL_VERSION`） | [iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool) release |
| P0 补齐批 | capa | 9.4.0（`CAPA_VERSION`） | [mandiant/capa](https://github.com/mandiant/capa) release |
| P0 补齐批 | capa-rules | `--depth 1` 未钉 | [mandiant/capa-rules](https://github.com/mandiant/capa-rules) |
| P0 补齐批 | SecLists | `--depth 1` 未钉 | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |
| P0 补齐批 | yara 规则 | `--depth 1` 未钉 | [Yara-Rules/rules](https://github.com/Yara-Rules/rules) |
| P0 补齐批 | pdfid、pdf-parser | `--depth 1` 未钉 | [DidierStevens/DidierStevensSuite](https://github.com/DidierStevens/DidierStevensSuite) |
| C2 框架参考 | sliver、merlin、Empire、Covenant、ysoserial、ysoserial.net | `--depth 1` 未钉 | [bishopfox/sliver](https://github.com/bishopfox/sliver)、Ne0nd0g/merlin、BC-SECURITY/Empire、cobbr/Covenant、frohoff/ysoserial、pwntester/ysoserial.net；只克隆到 `/opt/c2-ref`，不安装不运行 |
| BOF 工具链 | mingw-w64 | noble 随源 | Ubuntu apt（tuna） |
| BOF 工具链 | COFFLoader | `--depth 1` 未钉 | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader)，交叉编 COFFLoader64.exe |
| BOF 工具链 | atomic-bofs | `--depth 1` 未钉 | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) |
| BOF 工具链 | coffee-ldr | cargo nightly | [hakaioffsec/coffee](https://github.com/hakaioffsec/coffee) |
| BOF 工具链 | bof-launcher | `--depth 1` 未钉 | [The-Z-Labs/bof-launcher](https://github.com/The-Z-Labs/bof-launcher)，用 zig 0.15.2 构建 |
| BOF 工具链 | BOF-CATALOG.md | main  raw | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) |
| Project Zero 参考 | sandbox-attacksurface-analysis-tools | `--depth 1` 未钉 | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools)；只克隆 |
| Project Zero 参考 | DotNetToJScript | `--depth 1` 未钉 | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript)；只克隆 |
| Project Zero 参考 | windows-logical-eop-workshop | `--depth 1` 未钉 | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop)；只克隆 |
| Project Zero 参考 | oleviewdotnet | 全克隆含子模块 | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet)；只克隆 |
| nushell | nu | release latest | [nushell/nushell](https://github.com/nushell/nushell) release 预编译 |

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

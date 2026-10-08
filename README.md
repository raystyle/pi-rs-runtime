# pi-rs-runtime

本仓是 pi agent 的运行时环境维护仓，仓库地址 https://github.com/raystyle/pi-rs-runtime。输入是 Ubuntu 24.04（noble）与 `image-defs/ubuntu.yaml` 镜像定义；输出是 Incus 基础镜像 `ubuntu-24.04-base` 与发布别名 `pi-rs-runtime` 的运行时镜像；副作用包括：构建时删除同名旧镜像、在 `image-defs/` 下生成 `incus.tar.xz` 与 `rootfs.squashfs`、启动并删除临时验证容器、在容器内改写 apt 源与各类工具链配置。

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
| `ZIG_VERSION` | `0.16.0` | ziglang.org 直下，无国内镜像 |
| `MAVEN_VERSION` / `GRADLE_VERSION` | `3.9.16` / `8.14.3` | |
| `JAVA_VERSIONS` | `8 11 17 21 25` | sdkman 预装的 temurin 主版本；小版本随 tuna 目录取最新 |
| `PD_VERSION` | `latest` | projectdiscovery 全家桶 `go install` 版本 |
| `PY2_VERSION` | `2.7.18` | 源码编译，`--enable-shared` |
| `PHP_VERSIONS` | `7.4 8.1 8.3` | sury 源；VLD 逐版本尽力编译 |
| `GHIDRA_VERSION` / `GHIDRA_DATE` / `GHIDRA_SHA256` | `12.1.3` / `20260817` / `93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54` | 三者配套，换版本时同步换 |
| `FASM_VERSION` | `1.73.32` | 见 `install-compilers.sh` 内 `install_c` |
| `JADX_VERSION` / `APKTOOL_VERSION` / `CAPA_VERSION` | `1.5.3` / `2.12.0` / `9.4.0` | 见 `install-tools.sh` 内 `install_p0` |
| `SECGO_VERSION` | `latest` | secgo 组 `go install` 版本 |

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
- `install-tools.sh`:`TOOLS_ALL=(fd astgrep cli ghidra re pd secgo secrust pivot p0 c2 bof pz nu)`

## 错误表

| 条件 | 调用方收到什么 | 下一步 |
|------|--------------|--------|
| 分类脚本收到未知名 | `未知项: X(可选: …)`,退出码 1 | 对照对应脚本尾部 `*_ALL` 名单 |
| golang tarball sha256 校验失败 | `go tarball 校验失败`,退出码 1 | 校验和取自 golang.google.cn 官方 JSON；检查 `GO_DOWNLOAD` 镜像完整性后重跑 |
| node tarball sha256 校验失败 | `node tarball 校验失败`,退出码 1 | 校验和取自 npmmirror `SHASUMS256.txt`；重跑 |
| Ghidra zip 校验失败 | `ghidra zip 校验失败`,退出码 1 | `GHIDRA_VERSION`、`GHIDRA_DATE`、`GHIDRA_SHA256` 三者需配套，核对后重跑 |
| Ghidra 找不到 JDK 21 | `找不到 JDK 21,先跑 install-runtimes.sh sdkman`,退出码 1 | 先跑 `./install-runtimes.sh sdkman` 再跑 `install_ghidra` |
| 首启容器 cloud-init 持有 apt 锁 | 手工 `apt-get` 报锁占用 | `build-base-image.sh` 已内置 `cloud-init status --wait`；手工场景等待 cloud-init 完成 |
| pd/secgo 单个工具编译失败 | `!! X 编译失败(留待排查)`,继续其余工具，整组不退出 | 脚本幂等，重跑同命令补装（已装的 `have && skip`) |
| PHP 某版本安装失败 | `phpX 安装失败,跳过`,继续其余版本 | 检查 sury 源可用性后重跑 `install_php` |
| sigdb 安装失败 | `sigdb 安装失败(不影响 rizin 本体)`,继续 | rizin 与 rz-ghidra 不受影响；需要签名库时重跑 `install_re` |
| `vnc-screen.sh` 无参或未知子命令 | 打印头部注释中的用法，退出码 1 | 子命令为 `setup`、`start`、`stop`、`status` |
| zig 目标架构不是 amd64/arm64 | `install_zig` 退出码 1 | 当前仅支持两种架构 |
| 引用未定义变量 | `set -u` 中止，退出码非 0 | 检查环境变量拼写；所有覆盖变量均有默认值，正常路径不会触发 |

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

- 编译器：C 工具链（apt)、golang、rust(rustup 与 crates 走 tuna,`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`，含 rustfmt、clippy、rust-analyzer、rust-script、cargo-zigbuild、cargo-audit 与 crate 缓存预热）、zig、vcpkg(GitHub 直下，源码编译默认库集）。
- 运行时：node(npmmirror 二进制与 SHASUMS256 校验，全局 npmrc 写 registry/disturl/electron_mirror,`typescript`、`prettier`、`eslint`、corepack)、fnm 多版本、`bun`、uv（官方安装器，索引写 `/etc/uv/uv.toml`)、python3(apt，索引写 `/etc/pip.conf`；分析库全进 `/opt/analytics` venv)、duckdb(venv + GitHub release CLI)、python2.7（源码编译，华为云镜像）、PHP 多版本（sury 源 + VLD 尽力编译）、mono(xbuild,`nuget.exe` 在 `/opt/nuget.exe`)、dotnet(NuGet 走华为 v3)、pwsh(packages.microsoft.com)、sdkman(temurin 多版本本地路径注册 + maven + gradle，依赖镜像指阿里云）。
- 工具：fd、ast-grep、cli 组（git、jq、yq、shellcheck、just、tmux、gh)、ghidra（钉版 + sha256,`JAVA_HOME_OVERRIDE` 钉 temurin 21)、re 组（系统库 + rizin/rz-ghidra/sigdb 源码编译 + `/opt/re-venv`)、pd 全家桶（19 个 CLI,nuclei 模板更新尽力，naabu setcap)、secgo 组（14 个 CLI)、secrust(rustscan、feroxbuster)、pivot(gost/frp/wstunnel/rathole/bore)、p0(apt 批 + re-venv pip 批 + GitHub 钉版批：pwndbg、jadx、apktool、capa、SecLists、yara 规则、pdf 工具）、c2(6 个参考仓克隆到 `/opt/c2-ref`，不安装不运行）、bof(mingw-w64 + COFFLoader + coffee-ldr + bof-launcher)、pz(sandbox-attacksurface-analysis-tools、DotNetToJScript、windows-logical-eop-workshop、oleviewdotnet 等，只克隆参考，oleviewdotnet 需 `--recurse-submodules`)、nushell。

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

- 版本未钉：temurin 小版本随 tuna Adoptium 目录取最新；`dlv`、`gopls`、`golangci-lint` 与 pd/secgo 组用 `@latest`(`have && skip` 意味着“首次装到的那份”);rizin、rz-ghidra、sigdb、SecLists、yara 规则均为 `--depth 1` 未钉提交；pwndbg 从 git 源装、未钉 rev。
- zig 发行包无国内镜像，直下且无验签；minisig 公钥留档（`RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U`)，验签未做。
- `/root` 0700 的残留面：rust 主链已迁 `/opt`(rustup、cargo),ast-grep、secrust、pivot、coffee-ldr 与 fnm 仍经 root 的 `~/.cargo` 安装再链到 `/usr/local/bin`;tools 各组已 `export GOPATH=/opt/go`（dlv/gopls/golangci-lint、pd/secgo/pivot 产物归 /opt/go 并链出）；cli 组的 yq 与 gh 未设 GOPATH，产物落 /root/go 且只链 yq,`ubuntu` 用户对 gh 不可执行。
- `install_secrust` 日志声明装 rustscan、feroxbuster、findomain，实际只装前两个；findomain 注释建议改用 https://github.com/Findomain/Findomain/releases 预编译。
- `install_php` 中 PHP 7.4 已无官方支持，样本动态执行需在无网络、无生产数据挂载的环境里跑，并加 `-d opcache.jit=off`；当前部署链未强制该隔离面。python2 同理（已通过实测含 `import ssl`)。
- VNC 屏幕无 Chrome 与 noVNC;Chrome 官方版不装，后续定制构建。
- C2 框架（sliver、merlin、Empire、Covenant、ysoserial 系）只克隆到 `/opt/c2-ref` 作参考，不安装不运行；.NET 参考项目（pz 组）同样只克隆。
- `pi-box-dev` 镜像（pi 二进制、pi-web、定制 Chrome）的构建脚本不在本仓，`build.sh` 未做。
- 备选路线：单个实例可直接 `incus launch images:ubuntu/24.04`,`incus stop` 后 `incus publish --alias <名>` 固化，不经 distrobuilder。

运行时管理独立一层的思路与 https://github.com/raystyle/ark_rs 一致：本体可预装，库源优先 tuna。本仓只维护 yaml、脚本与文档；镜像产物不入库；distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`，失败后可手动清理。

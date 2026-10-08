# pi-rs-runtime

pi agent(pi-rs)运行时环境的基础镜像维护仓。用 [distrobuilder](https://github.com/lxc/distrobuilder) 从源码构建带清华 tuna 源的 Ubuntu 24.04 Incus 基础镜像(cloud 变体,含 cloud-init),导入本地 Incus 后作为 pi agent 运行实例的基线。

> **pi agent 运行时不必走这条路。** 单个实例直接 `incus launch ubuntu:24.04`,装完所需软件后用 `incus publish` 固化即可(见下文"备选路线")。本仓的路线适合 x86 构建机批量产出可复现的基础镜像。

## 产物

- `image-defs/ubuntu.yaml` — 镜像定义,基于 lxc-ci 官方 `images/ubuntu.yaml`,改动:
  - `source.url` 与 `repositories`(sources.list)均指向 `mirrors.tuna.tsinghua.edu.cn`(amd64 用 `/ubuntu`,ports 用 `/ubuntu-ports`)
- `scripts/build-base-image.sh` — 一键构建 + 导入 + 验证

镜像特性:Ubuntu 24.04 (noble) amd64、cloud-init、netplan DHCP、`ubuntu` 用户 sudo NOPASSWD、apt 源走 tuna。

## 宿主机构建环境(一次性)

### 1. apt 换清华源(可选,加快装包)

deb822 格式(`/etc/apt/sources.list.d/ubuntu.sources`)把 URIs 改成:

```
https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
```

### 2. 安装 Incus 并初始化

```bash
sudo apt install -y incus
sudo incus admin init --auto          # dir 存储 + NAT 网桥
sudo adduser "$USER" incus-admin      # 重新登录后免 sudo
```

### 3. 从源码编译 distrobuilder(Ubuntu 源里没有,官方只提供 Snap)

需要 Go ≥ 1.21(Ubuntu 24.04 自带 `golang-go` 即可)。只做容器镜像:

```bash
sudo apt install -y golang-go gcc debootstrap rsync gpg squashfs-tools \
  git make build-essential libwin-hivex-perl wimtools genisoimage
git clone https://github.com/lxc/distrobuilder
cd distrobuilder && make
sudo install -m 755 "$HOME/go/bin/distrobuilder" /usr/local/bin/distrobuilder
```

以后要 `--vm` 再加:`sudo apt install -y btrfs-progs dosfstools qemu-utils`。

## 构建与导入

```bash
./scripts/build-base-image.sh
```

等价于:

```bash
cd image-defs
sudo distrobuilder build-incus ubuntu.yaml \
  -o image.release=noble -o image.architecture=amd64 -o image.variant=cloud
sudo incus image import incus.tar.xz rootfs.squashfs --alias ubuntu-24.04-base
```

注意:`-o image.release=...` 必须显式给(lxc-ci 的 yaml 不写死套件);不给会报 `debootstrap: You must specify a suite and a target`。`image.variant=cloud` 决定装 cloud-init 与 cloud-init 模板,与官方 `images:ubuntu/24.04` 行为一致。

构建成功后产物在 `image-defs/` 下:`incus.tar.xz`(元数据)+ `rootfs.squashfs`(根文件系统),可直接重新 `incus image import`。

## 使用

```bash
incus launch ubuntu-24.04-base mybox
incus shell mybox
```

容器内 apt 源已是 tuna,`apt-get update/install` 直接可用。

## 开发模式:镜像只钉运行时,业务走挂载

pi agent 的开发/发布与运行时安装**彻底分开**:

| 放哪 | 内容 | 改完怎么生效 |
|------|------|--------------|
| **pi-box 镜像** | Node、Pi 二进制、pi-web、Chrome、VNC | 重新 pack(build.sh) |
| **仓库 `.pi/`** | 扩展、技能、提示词(`pi install --local` 写 `.pi/settings.json`) | 挂载后 Pi 里 `/reload`,不停容器、不 publish |
| **实例家目录** | `~/.pi/agent` 会话、密钥、浏览器配置 | 不进镜像,升级时单独拷 |

两层配置:用户层 `~/.pi/agent` 随实例走;项目层 `.pi/` 信任项目后才加载,随 git 走。

### 开发:挂仓库,不发布

```bash
./scripts/dev-instance.sh pi-dev /path/to/pi/app
# 或手动:
incus launch pi-box-dev pi-dev
incus config device add pi-dev src disk \
  source=/path/to/pi/app path=/home/ubuntu/workspace shift=true
incus exec pi-dev -- sudo -u ubuntu -i bash -lc \
  'cd /home/ubuntu/workspace && pi'
```

扩展放 `workspace/.pi/extensions/`,改完 `/reload` 立即生效;`pi install --local ./my-extension` 把声明写进项目,随 git 提交。

### 发布:build.sh 只拷钉死的版本和仓库

```bash
pi install --local ./
install -d /opt/app
cp -a /src/app/. /opt/app/      # 只拷钉住版本的 Pi + 该仓库
```

候选镜像烟测的是「钉住的 Pi 版本 + 当时的 `.pi/`」。线上实例(如 pi-01)**不挂开发目录**,避免未提交改动进生产;会话仍在 `~/.pi/agent`,升级镜像时单独拷,不跟镜像走。

`shift=true` 需要 idmap:Incus 容器默认安全式 idmap 即可支持,若挂载后权限不对,检查 `incus config show <实例> | grep security.idmap`。

## 运行时清单(安装,不是打包进镜像)

`scripts/install-runtimes.sh` 在容器内**逐个安装**下列运行时并配置国内镜像源,幂等可重跑。思路与 [ark_rs](https://github.com/raystyle/ark_rs)(Agent Runtime Kit)一致:运行时管理是独立一层,不进基础镜像。**镜像源原则:有清华 tuna 走 tuna,tuna 没有的走该生态自己的国内镜像**(已实测 tuna 无 golang/node/bun/dotnet/powershell/zig 镜像)。

按三类解耦,各自独立可跑(`lib/common.sh` 提供共享镜像源/版本钉/入口):

```bash
# 全量(顺序:编译器 → 运行时 → 工具)
./scripts/install-all.sh

# 或按类单独跑,也可只装类内某几项
./scripts/install-compilers.sh              # c golang rust zig
./scripts/install-compilers.sh rust         # 只装 rust
./scripts/install-runtimes.sh               # node(fnm 多版本) bun python python2 uv dotnet pwsh sdkman
./scripts/install-tools.sh                  # fd astgrep cli pd secgo secrust

# 容器内使用
incus launch ubuntu-24.04-base rt
incus file push scripts rt/root/ --create-dirs -r
incus exec rt -- bash /root/scripts/install-all.sh
```

| # | 类别 | 项 | 版本 | 源 / 配置落点 |
|---|------|----|------|----------------|
| 1 | 编译器 | C 工具链 | noble 安全更新 | apt **tuna** |
| 2 | 编译器 | golang | 1.27.1(官方 JSON 验 sha256) | 下载南大镜像;`go env -w` GOPROXY=goproxy.cn / GOSUMDB=sum.golang.google.cn;`go` 链 /usr/local/bin |
| 3 | 编译器 | rust + rust-lld/rustfmt/clippy/rust-script/cargo-zigbuild | stable(1.99) | **tuna** rustup(变量已持久化)+ crates sparse(含 `[registries.tuna]`);工具链链 /usr/local/bin |
| 4 | 编译器 | zig | 0.16.0 | ziglang.org 直下(无机构镜像;minisig 验签见 ROADMAP) |
| 5 | 运行时 | node + fnm 多版本(18/20/22/24) | 默认 24.21.0(SHASUMS256 校验) | npmmirror 二进制;registry/disturl/electron_mirror 写 **全局 npmrc**(`/opt/node/etc`) |
| 6 | 运行时 | bun | latest | npm 全局;**bunfig**(root/ubuntu);shim 链 /usr/local/bin |
| 7 | 运行时 | python3 + pip | noble 3.12 | 索引 **tuna** `pypi.tuna.../simple`,写 **`/etc/pip.conf`**(全用户) |
| 8 | 运行时 | python2.7(逆向) | 2.7.18 源码编译 | 华为云源;`--enable-shared` + ldconfig |
| 9 | 运行时 | uv | latest(pip 装) | **`/etc/uv/uv.toml`** `[[index]]`(UV_INDEX_URL 已废弃) |
| 10 | 运行时 | dotnet | sdk-10.0 | **noble 自带源(即 tuna)**;NuGet 走**华为 v3**;MS 仓仅 pwsh 用 |
| 11 | 运行时 | pwsh | powershell-lts | packages.microsoft.com(国内无镜像) |
| 12 | 运行时 | java ×5(sdkman) | temurin 8u504 / 11.0.32.1 / 17.0.20.1 / 21.0.12.1 / 25.0.4.1(默认 25) | **tuna** Adoptium 本地路径注册;`java/javac` 链 /usr/local/bin;JAVA_HOME 已配 |
| 13 | 工具 | fd / ripgrep | apt 最新 | apt **tuna**;`fd` 链 /usr/local/bin |
| 14 | 工具 | ast-grep(sg) | latest | cargo install(**tuna** crates) |
| 15 | 工具 | cli 组:git / jq / yq / shellcheck / just / tmux / gh | apt + go install | jq/shellcheck/just=**tuna** apt;yq/gh=`go install`(goproxy.cn) |
| 16 | 工具 | maven + settings.xml | 3.9.16 | 发行包 **tuna** apache;依赖镜像**阿里云**(写 `/opt/maven/conf/settings.xml`) |
| 17 | 工具 | gradle + init.d | 8.14.3 | 发行包**阿里云** distributions;依赖/插件**阿里云** init.d(盖 pluginManagement) |
| 17b | 运行时 | PHP 多版本(webshell 逆向) | 7.4 / 8.1 / 8.3(sury 源,南大镜像) | 全路径切换 `php7.4/php8.1/php8.3`;VLD 逐版本尽力编译;跑样本 `-d opcache.jit=off` |
| 17c | 工具 | ghidra + 逆向链 re | ghidra 12.1.3(官方 sha256 验) | GitHub 直下;`JAVA_HOME_OVERRIDE` 钉 temurin 21;rizin/rz-ghidra/sigdb 源码编译;`/opt/re-venv`(capstone/keystone/unicorn/lief/yara-python) |
| 17d | 图形 | vnc-screen(Xvfb :99 → x11vnc) | apt 最新 | 仅 127.0.0.1:5900;宿主经 incus proxy;**Chrome/noVNC 不装**——Chrome 用后续定制构建 |
| 18 | 工具 | projectdiscovery 全家桶 19 CLI | latest | `go install` 源码(goproxy.cn);naabu 已 setcap + libpcap |
| 19 | 工具 | secgo 组 14 CLI(ffuf/gobuster/dalfox/amass/chisel/gitleaks/tomnomnom 系/gau/gospider/gowitness/AzureHound) | latest | 同上 |
| 20 | 工具 | secrust 组(rustscan/feroxbuster/findomain) | latest | cargo install(**tuna** crates) |

原则:**运行时本体可预装(任意源),库源优先 tuna**——crates/pip/JDK/maven/apt 走 tuna;golang 模块(goproxy.cn)与 npm(npmmirror) tuna 没有,用生态自有国内源;pwsh/zig 无国内镜像走官方;dotnet 走 noble 自带源、NuGet 走华为 v3。

环境变量可覆盖版本与镜像:`GOLANG_VERSION NODE_VERSION DOTNET_SDK ZIG_VERSION MAVEN_VERSION JAVA_VERSIONS` 与 `TUNA GOPROXY GOSUMDB GO_DOWNLOAD NPM_REGISTRY NODE_MIRROR PIP_INDEX CRATES_INDEX ADOPTIUM_MIRROR MAVEN_MIRROR`(uv 的索引用 `PIP_INDEX`)。

镜像可用性实证(tuna 有 `rustup` `crates.io-index` `pypi` `Adoptium`(8/11/17/21/25,x64+aarch64)`apache/maven`;无 golang/node/npm registry/bun/dotnet/powershell/zig。npmmirror 二进制镜像有 node/bun/python/deno、无 zig。

## 备选路线:incus publish(适合单个 pi agent 实例 / 少量定制)

不用 distrobuilder,直接在 Incus 里做:

```bash
incus launch images:ubuntu/24.04 u24
incus exec u24 -- bash          # 装软件、改配置
incus stop u24
incus publish u24 --alias my-custom-base
incus delete u24
```

## 更新镜像

上游有安全更新时重跑 `./scripts/build-base-image.sh` 即可(脚本会先删旧 alias 再导入)。脚本默认构建 noble/amd64,可用环境变量覆盖:`RELEASE=jammy ARCH=arm64 ALIAS=ubuntu-22.04-base ./scripts/build-base-image.sh`。

## ROADMAP(评审吸收后留档)

- **JDK 五版本钉死**:当前按 tuna 目录取「最新」,小版本会漂;改钉完整 tarball 名 + 从 Adoptium API 记 sha256(镜像目录无 .sha256.txt)
- **pd/secgo/secrust/rizin 版本钉**:`@latest` + `have && skip` = 「第一天装到的那份」;攻击向 CLI 浮动 tag 是供应链面,逐步改钉
- **多用户可用性**:rustup/fnm/`go install` 产物在 `/root` 下(`/root` 0700),`ubuntu` 用户用不了;方向是 `CARGO_HOME/RUSTUP_HOME/GOPATH` 迁 `/opt` + 配置双写
- **zig minisig 验签**:公钥 `RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U`
- **python2**:已通过实测(含 `import ssl`);若换环境构建失败按 pyenv 的 OpenSSL 3 补丁集处理
- **定制 Chrome**:官方版不装(pi-box 图形层用定制构建,含 CDP 面板);vnc-screen 只提供裸屏幕
- **pi-box 镜像打包**:`dev-instance.sh` 默认 `pi-box-dev`,需 build.sh 把「钉死运行时 + Pi 二进制 + pi-web」打成该别名(未做)
- **隔离执行**:PHP 7.4 / python2 样本应在无网络、无生产挂载的容器里跑;当前部署链未强制该隔离面

## 备注

- 构建必须从 `image-defs/` 目录运行,产物落在当前目录
- distrobuilder 缓存与构建根目录在 `/tmp/distrobuilder`,失败后可手动清理
- 本仓只维护 yaml、脚本与文档;镜像产物(squashfs)不入库

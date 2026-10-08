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

| # | 运行时 | 安装方式 | 默认版本 | 镜像源 |
|---|--------|----------|----------|--------|
| 1 | C 工具链 | apt | build-essential/clang/cmake/ninja | tuna apt |
| 2 | golang | 官方 tarball | 1.23.4 | 下载 `mirror.nju.edu.cn/golang`(tuna 无,南大同为高校源;可切 `golang.google.cn`);模块 `GOPROXY=goproxy.cn`;`GOSUMDB=sum.golang.google.cn` |
| 3 | rust | rustup(`--profile minimal`) | stable | **tuna** `rustup` + `crates.io-index`(sparse) |
| 4 | node | 二进制 tarball | 22.12.0 | 下载 `npmmirror.com/-/binary/node`(tuna 无);npm registry `registry.npmmirror.com` |
| 5 | bun | npm 全局安装 | latest | 经 npmmirror registry(tuna 无) |
| 6 | python | apt + pip | noble 自带 3.12 | pip **tuna** `pypi/simple` |
| 7 | uv | pip 安装(uv 无独立国内二进制镜像,PyPI 即 tuna) | latest | 库索引 `UV_INDEX_URL`=**tuna** `pypi/simple` |
| 8 | dotnet | packages.microsoft.com apt | sdk-8.0 | 无国内镜像 |
| 9 | pwsh | packages.microsoft.com apt | LTS | 无国内镜像 |
| 10 | zig | ziglang.org 官方 tarball | 0.13.0 | 无国内镜像 |
| 11 | sdkman + 多版本 JDK | get.sdkman.io;各主版本 temurin 从 **tuna Adoptium** 拉最新,本地路径逐个注册进 sdkman | **8u504 / 11.0.32.1 / 17.0.20.1 / 21.0.12.1 / 25.0.4.1**(x64 与 aarch64 同步) | JDK **tuna** `Adoptium`;maven **tuna** `apache/maven` 直装;gradle 走 sdkman |
| 12 | projectdiscovery 全家桶 | `go install` 源码编译 19 个 CLI(subfinder/dnsx/naabu/httpx/nuclei/katana/uncover/cloudlist/notify/interactsh/chaos-client/mapcidr/asnmap/tlsx/proxify/simplehttpserver/shuffledns/crlfuzz/pdtm) | latest | 模块/源码经 `goproxy.cn`;库随编译进模块缓存;nuclei 模板另从 GitHub 拉 |

原则:**运行时本体可预装(任意源),库源优先 tuna**——crates/pip/JDK/maven/apt 走 tuna;golang 模块(goproxy.cn)与 npm(npmmirror) tuna 没有,用生态自有国内源;dotnet/pwsh/zig 及其库无国内镜像,走官方。

环境变量可覆盖版本与镜像:`GOLANG_VERSION NODE_VERSION DOTNET_SDK ZIG_VERSION MAVEN_VERSION JAVA_VERSIONS` 与 `TUNA GOPROXY GOSUMDB GO_DOWNLOAD NPM_REGISTRY NODE_MIRROR PIP_INDEX CRATES_INDEX ADOPTIUM_MIRROR MAVEN_MIRROR`(uv 的索引用 `PIP_INDEX`)。

已验证的镜像可用性:tuna 有 `rustup` `crates.io-index` `pypi` `Adoptium`(8/11/17/21/25,x64+aarch64)`apache/maven`;无 golang/node/npm registry/bun/dotnet/powershell/zig。npmmirror 二进制镜像有 node/bun/python/deno、无 zig。

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

## 备注

- 构建必须从 `image-defs/` 目录运行,产物落在当前目录
- distrobuilder 缓存与构建根目录在 `/tmp/distrobuilder`,失败后可手动清理
- 本仓只维护 yaml、脚本与文档;镜像产物(squashfs)不入库

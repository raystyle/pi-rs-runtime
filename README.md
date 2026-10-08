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

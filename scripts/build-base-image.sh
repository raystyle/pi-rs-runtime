#!/usr/bin/env bash
# 构建 pi-rs-runtime 基础镜像(ubuntu 24.04 + tuna 源 + cloud 变体)并导入 incus
set -euo pipefail

RELEASE="${RELEASE:-noble}"
ARCH="${ARCH:-amd64}"
ALIAS="${ALIAS:-ubuntu-24.04-base}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

cd "$HERE/image-defs"

echo ">> 构建 ubuntu/$RELEASE ($ARCH, cloud 变体)…"
sudo distrobuilder build-incus ubuntu.yaml \
  -o "image.release=$RELEASE" \
  -o "image.architecture=$ARCH" \
  -o "image.variant=cloud"

echo ">> 导入 incus,alias=$ALIAS"
if sudo incus image info "$ALIAS" >/dev/null 2>&1; then
  sudo incus image delete "$ALIAS"
fi
sudo incus image import incus.tar.xz rootfs.squashfs --alias "$ALIAS"

echo ">> 验证:启动临时容器检查 apt 源与 cloud-init"
sudo incus launch "$ALIAS" verify-base
trap 'sudo incus delete -f verify-base >/dev/null 2>&1 || true' EXIT
sleep 5
sudo incus exec verify-base -- sh -c \
  'grep -rh "^deb " /etc/apt/ | head -3; apt-get update -qq && echo APT_UPDATE_OK; cloud-init --version'

echo ">> 完成。之后运行:incus image delete $ALIAS 之前的旧指纹如有需要自行清理"

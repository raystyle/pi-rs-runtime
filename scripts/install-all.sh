#!/usr/bin/env bash
# 全量入口:按 编译器 → 运行时 → 库缓存 → 工具 顺序跑分类安装器
# 可装项清单见各脚本尾部 *_ALL:
#   install-compilers.sh 尾部 COMPILERS_ALL
#   install-runtimes.sh  尾部 RUNTIMES_ALL
#   install-libcache.sh  尾部 LIBCACHE_ALL
#   install-tools.sh     尾部 TOOLS_ALL
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# 前置依赖批:unzip/zip/xz 是 sdkman/ghidra/jadx/gradle/vcpkg 等的隐式依赖,
# 极简 cloud 镜像里没有;acl 供共享可写缓存的默认 ACL(shared_writable_cache);全量入口先兜底
apt-get update -qq
apt-get install -y --no-install-recommends \
    ca-certificates curl wget gpg unzip zip xz-utils file git acl

# cloud 镜像的后台自动升级会与构建抢 dpkg 锁(fresh 验证实证:fd 组被 unattended-upgrades
# 卡死);构建容器不需要自动升级,停掉计时器(不卸载,保留工具)
systemctl disable --now unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true

# 全量入口不转发过滤器:单项安装直接用对应分类脚本
bash "$HERE/install-compilers.sh"
bash "$HERE/install-runtimes.sh"
bash "$HERE/install-libcache.sh"
bash "$HERE/install-tools.sh"

# 收尾卫生:删可再生缓存与一次性残留(不碰 /opt 固化离线缓存)
bash "$HERE/clean-image.sh"

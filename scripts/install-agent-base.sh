#!/usr/bin/env bash
# agent 基座镜像安装入口(agent-base 分支主道;产品全量道是 install-all.sh,在 main)。
# 面孔:claude code / codex / pi-rs(agents 组)+ ACP 监督进程(acp 组)+ browse + clean-chrome
#      + zg 向量引擎与模型烤库(pi-rs 内置插件功能依赖,非 rctl)+ VNC 桌面(用户裁定)。
# 依赖构建环境:c(gcc/cmake 链接与 zg 的 llama.cpp)、golang(acpsup 编译)、rust(pi rust-script
# 与离线闭包)、node(claude/codex/适配器/pi-rs 的 node 载体);libcache rust 吃锁定闭包(pi 离线锚)。
# 网关接线:AGENT_GATEWAY_URL env + AGENT_GATEWAY_TOKEN/AGENT_GATEWAY_TOKEN_PATH(agents 组内消费)。
# 尾步 clean-image.sh(含瘦身批不烤面删除段)。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# 前置依赖批(与 install-all.sh 同款):极简 cloud 镜像没有 unzip/xz 等;acl 供共享可写缓存
apt-get update -qq
apt-get install -y --no-install-recommends \
    ca-certificates curl wget gpg unzip zip xz-utils file git acl

# 构建容器不需要自动升级(抢 dpkg 锁)
systemctl disable --now unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true

# 依赖构建环境(c: gcc/cmake/make;golang: acpsup;rust: pi rust-script + 闭包)
bash "$HERE/install-compilers.sh" c golang rust
# node:claude-code/codex/ACP 适配器/pi-rs 的载体
bash "$HERE/install-runtimes.sh" node
# 锁定闭包 fetch(pi 离线编译锚:scripts/lock/rust 含 pi_rust_lib 依赖闭包)
bash "$HERE/install-libcache.sh" rust
# 面孔组:zg 先于 chrome/browse 无依赖关系,按 chrome→browse(单副本指路)→vnc→agents→acp 序
bash "$HERE/install-tools.sh" zg chrome browse vnc agents acp
# 收尾卫生(不烤面删除段 + 可再生缓存)
bash "$HERE/clean-image.sh"
echo "agent 基座安装完成:$0"

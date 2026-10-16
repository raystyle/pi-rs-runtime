#!/usr/bin/env bash
# agent 基座镜像安装入口(agent-base 分支主道;产品全量道是 install-all.sh,在 main)。
# 面孔:pi-rs only(2026-10-16 用户令:cc/codex 剔除,镜像最小化)
#      + browse + clean-chrome + zg 向量引擎(pi-rs 插件面)+ VNC 桌面。
# 依赖构建环境:c(gcc/cmake 链接与 zg 的 llama.cpp)、golang(acpsup 编译后删)、
#      rust(pi rust-script + 闭包 + zigbuild)。
# 尾步 clean-image.sh(含瘦身批不烤面删除段 + 最小化剔除段)。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# 前置依赖批(与 install-all.sh 同款):极简 cloud 镜像没有 unzip/xz 等;acl 供共享可写缓存
# + 补面批(core v2 P0/P1/P2):JDK21(java_ser)/libgmp-dev(jwt)/openssh-client(oob_poll)/procps(pkill)
apt-get update -qq
apt-get install -y --no-install-recommends \
    ca-certificates curl wget gpg unzip zip xz-utils file git acl \
    openjdk-21-jdk-headless libgmp-dev openssh-client procps

# 构建容器不需要自动升级(抢 dpkg 锁)
systemctl disable --now unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true

# 依赖构建环境(c: gcc/cmake/make;golang: acpsup 编译用完后删;rust: pi 全件;zig: postex_build)
bash "$HERE/install-compilers.sh" c golang rust zig
# node 不装(pi-rs bun 二进制自含运行时;cc/codex 平台剔除)
# 锁定闭包 fetch(pi 离线编译锚)
bash "$HERE/install-libcache.sh" rust
# 面孔组:zg→chrome→browse→vnc→desktop→agents(=pi-rs only)→piocr→acp
bash "$HERE/install-tools.sh" zg chrome browse vnc desktop agents piocr acp
# go 工具链:acpsup 编译完即删(镜像最小化)
rm -rf /usr/local/go /opt/go
# 收尾卫生(不烤面删除段 + 可再生缓存 + 最小化剔除)
bash "$HERE/clean-image.sh"

# 落位自检
miss=0
for b in zg clean-chrome browse pi-rs vncserver websockify zig javac java ssh pkill; do
    command -v "$b" >/dev/null 2>&1 && echo "  ok $b" || { echo "  !! 缺 $b"; miss=$((miss+1)); }
done
command -v cargo-zigbuild >/dev/null 2>&1 && echo "  ok cargo-zigbuild" || { echo "  !! 缺 cargo-zigbuild"; miss=$((miss+1)); }
[ -f /opt/zg-models/hf_Qwen_Qwen3-Embedding-0.6B-Q8_0.gguf ] && echo "  ok zg 模型烤库" || { echo "  !! 缺 zg 模型"; miss=$((miss+1)); }
[ -f /opt/pi-ocr-models/tiny-rec/model.safetensors ] && echo "  ok pi_ocr 烤库" || { echo "  !! 缺 pi_ocr 模型"; miss=$((miss+1)); }
[ -x /opt/pi-rs/vendor/zg/x86_64-unknown-linux-gnu/zg ] && echo "  ok pi-rs vendor zg" || { echo "  !! 缺 vendor zg"; miss=$((miss+1)); }
[ -x /opt/clean-chrome/CURRENT/chrome ] && echo "  ok chrome 单副本" || { echo "  !! 缺 chrome 单副本"; miss=$((miss+1)); }
systemctl is-active --quiet acpsup && echo "  ok acpsup(active)" || { echo "  !! acpsup 未激活"; miss=$((miss+1)); }
[ -f /var/lib/acpsup/token ] && echo "  ok acpsup token" || { echo "  !! 缺 token"; miss=$((miss+1)); }
systemctl is-active --quiet xvfb99 && systemctl is-active --quiet x11vnc99 \
    && echo "  ok 桌面栈(Xvfb :99 + x11vnc 5900)" || { echo "  !! 桌面栈未起"; miss=$((miss+1)); }
[ "$miss" -gt 0 ] && { echo "!! 基座自检缺 ${miss} 件,拒绝视为完成"; exit 1; }
echo "agent 基座安装完成(pi-rs only 最小化):$0"

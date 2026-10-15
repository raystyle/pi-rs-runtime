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
# + 补面批四件(core v2 P0/P1/P2):JDK21(java_ser javac+java 双面)/libgmp-dev(jwt gcc 助手)/
#   openssh-client(oob_poll)/procps(pkill+kill:browser_suite 收口与 cdp terminate_pid 兜底)
apt-get update -qq
apt-get install -y --no-install-recommends \
    ca-certificates curl wget gpg unzip zip xz-utils file git acl \
    openjdk-21-jdk-headless libgmp-dev openssh-client procps

# 构建容器不需要自动升级(抢 dpkg 锁)
systemctl disable --now unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true

# 依赖构建环境(c: gcc/cmake/make;golang: acpsup;rust: pi rust-script + musl/zigbuild + 闭包;
# zig: postex_build 的 cargo zigbuild 面,0.16.0 与 cargo-zigbuild 0.23.4 配对)
bash "$HERE/install-compilers.sh" c golang rust zig
# node:claude-code/codex/ACP 适配器/pi-rs 的载体
bash "$HERE/install-runtimes.sh" node
# 锁定闭包 fetch(pi 离线编译锚:scripts/lock/rust 含 pi_rust_lib 依赖闭包)
bash "$HERE/install-libcache.sh" rust
# 面孔组:chrome→browse(单副本指路)→vnc(桌面依赖)→desktop(常驻桌面)→agents(pi-rs)
# →piocr(pin 抽自 pi-rs dist,须在 agents 后)→acp(监督进程收尾)
bash "$HERE/install-tools.sh" zg chrome browse vnc desktop agents piocr acp
# 收尾卫生(不烤面删除段 + 可再生缓存)
bash "$HERE/clean-image.sh"

# 落位自检:分类脚本对未知项/组内失败是软失败哲学(下轮补),入口必须硬验关键面,
# 拒绝静默半成品(基座构建连跑四轮才全绿的教训)
miss=0
for b in zg clean-chrome browse claude codex pi-rs vncserver websockify zig javac java ssh pkill; do
    command -v "$b" >/dev/null 2>&1 && echo "  ok $b" || { echo "  !! 缺 $b"; miss=$((miss+1)); }
done
command -v cargo-zigbuild >/dev/null 2>&1 && echo "  ok cargo-zigbuild" || { echo "  !! 缺 cargo-zigbuild"; miss=$((miss+1)); }
command -v go >/dev/null 2>&1 && echo "  ok go" || { echo "  !! 缺 go"; miss=$((miss+1)); }
[ -x /opt/node/bin/node ] && echo "  ok node(/opt/node)" || { echo "  !! 缺 /opt/node"; miss=$((miss+1)); }
[ -f /opt/zg-models/hf_Qwen_Qwen3-Embedding-0.6B-Q8_0.gguf ] && echo "  ok zg 模型烤库" || { echo "  !! 缺 zg 模型"; miss=$((miss+1)); }
[ -f /opt/pi-ocr-models/tiny-rec/model.safetensors ] && echo "  ok pi_ocr 烤库" || { echo "  !! 缺 pi_ocr 模型"; miss=$((miss+1)); }
[ -x /opt/pi-rs/vendor/zg/x86_64-unknown-linux-gnu/zg ] && echo "  ok pi-rs vendor zg" || { echo "  !! 缺 vendor zg(v0.5.0 落位)"; miss=$((miss+1)); }
[ -x /opt/clean-chrome/CURRENT/chrome ] && echo "  ok chrome 单副本" || { echo "  !! 缺 chrome 单副本"; miss=$((miss+1)); }
systemctl is-active --quiet acpsup && echo "  ok acpsup(active)" || { echo "  !! acpsup 未激活"; miss=$((miss+1)); }
[ -f /var/lib/acpsup/token ] && echo "  ok acpsup token" || { echo "  !! 缺 token"; miss=$((miss+1)); }
systemctl is-active --quiet xvfb99 && systemctl is-active --quiet x11vnc99 \
    && echo "  ok 桌面栈(:99 + 5900)" || { echo "  !! 桌面栈未起"; miss=$((miss+1)); }
[ "$miss" -gt 0 ] && { echo "!! 基座自检缺 ${miss} 件,拒绝视为完成"; exit 1; }
echo "agent 基座安装完成:$0"

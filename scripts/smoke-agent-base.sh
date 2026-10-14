#!/usr/bin/env bash
# agent 基座镜像发布门禁冒烟(agent-base 分支;产品全量门是 smoke-release.sh,在 main)。
# 面孔:claude code/codex/pi-rs(agents)、acpsup(acp)、browse、clean-chrome、zg 向量引擎(pi-rs 插件面)、VNC。
# 用法与视角双守卫、断网前置约定、PASS/FAIL 计数口径均照 smoke-release.sh。
#   incus file push scripts/smoke-agent-base.sh <实例>/root/scripts/
#   incus exec <实例> -- ip link set eth0 down
#   incus exec <实例> -- bash /root/scripts/smoke-agent-base.sh root
#   incus exec <实例> --user 1000 --group 1000 -- env HOME=/home/ubuntu bash <拷到 ubuntu 可读位的本脚本> ubuntu
#   incus exec <实例> -- ip link set eth0 up
set -u
VIEW="${1:?用法: smoke-agent-base.sh root|ubuntu}"
case "$VIEW" in root|ubuntu) ;; *) printf '视角取值非法:%s\n' "$VIEW" >&2; exit 2;; esac
[ "$(id -un)" = "$VIEW" ] || { printf '视角 %s 与实际 uid %s 不符\n' "$VIEW" "$(id -un)" >&2; exit 2; }
cd "$HOME" 2>/dev/null || cd /tmp
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
chk() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
chkout() {
    local d="$1" p="$2" t="$3"; shift 3
    local out; out="$(timeout "$t" "$@" 2>&1)" || true
    if printf '%s' "$out" | grep -qiE "$p"; then ok "$d"
    else bad "$d [out:$(printf '%s' "$out" | head -c 100)]"; fi
}
section() { printf '\n== %s ==\n' "$1"; }

section "[$VIEW] A. 断网自证"
if [ "$VIEW" = root ]; then
    ip link show eth0 | grep -q "state DOWN" && ok "eth0 DOWN" || bad "eth0 未 down"
    timeout 5 getent hosts github.com >/dev/null 2>&1 && bad "DNS 仍通(应失败)" || ok "DNS 快失败"
    out="$(timeout 5 curl -sS -m 4 http://1.1.1.1 2>&1)" || true
    printf '%s' "$out" | grep -qiE "timed out|failed|unreachable|refused" && ok "直连快失败" || bad "直连异常:$out"
fi

section "[$VIEW] B. 工具链与运行时版本面(基座依赖构建环境)"
chkout "gcc"     "[0-9]+\.[0-9]+" 15 gcc --version
chkout "cmake"   "cmake version" 15 cmake --version
chkout "rustc"   "rustc [0-9]" 15 rustc --version
chkout "cargo"   "cargo [0-9]" 15 cargo --version
chkout "go"      "go version go[0-9]" 15 go version
chkout "node"    "v[0-9]+\.[0-9]+" 15 node -v
chkout "npm"     "[0-9]+\.[0-9]+" 15 npm -v
chkout "git"     "git version [0-9]" 15 git --version
# 基座不装面点名(装上即错):fnm 多版 node、zig、dotnet、bun(rctl 已出镜像)
have() { command -v "$1" >/dev/null 2>&1; }
! have zig   && ok "zig 不在(基座口径)" || bad "zig 不应装"
! have dotnet && ok "dotnet 不在(基座口径)" || bad "dotnet 不应装"
! have bun    && ok "bun 不在(基座口径)" || bad "bun 不应装"
! have rctl   && ok "rctl 不在(基座口径)" || bad "rctl 不应装"

section "[$VIEW] C. 五面孔与引擎"
chkout "claude"        "claude" 30 claude --version
chkout "codex"         "codex" 30 codex --version
chkout "pi-rs"         "[0-9]+\.[0-9]+" 30 pi-rs --version
chkout "acpsup(自检)"  "selftest PASS" 90 acpsup --selftest claude
chk   "clean-chrome" clean-chrome --version
chk   "browse 版本"   browse --version
chk   "zg"            zg --version
chk   "systemd acpsup" systemctl is-active acpsup
[ -x /opt/clean-chrome/CURRENT/chrome ] && ok "chrome 单副本在(/opt/clean-chrome/CURRENT)" || bad "chrome 单副本缺席"
[ ! -e "$HOME/.browse-rs/chrome" ] && ok "browse 无托管副本(单副本口径)" || bad "browse 托管副本存在(应复用 chrome 组)"
[ -f /opt/zg-models/hf_Qwen_Qwen3-Embedding-0.6B-Q8_0.gguf ] && ok "zg 向量模型烤库在" || bad "zg 模型缺席"

section "[$VIEW] D. 实跑面"
# browse 经引擎取内网面(网关);网关在 eth0 之外可达(incusbr0 NAT 是外网道,eth0 down 不拦)
# 但断网口径下引擎导航外网必败;改验 daemon 起停与本地 blank 页
if [ "$VIEW" = root ]; then
    timeout 60 browse up --headless >/dev/null 2>&1 && ok "browse daemon 起(headless)" || bad "browse daemon 起失败"
    timeout 60 browse fetch "about:blank" >/dev/null 2>&1 && ok "browse fetch about:blank" || bad "browse fetch 失败"
    timeout 60 browse down >/dev/null 2>&1 && ok "browse daemon 停" || bad "browse down 失败"
fi
# zg 语义面:离线索引+查询(模型烤库本地)
if [ "$VIEW" = root ]; then
    T="$(mktemp -d)"
    printf 'id: probe-one\ndesc: 樱桃原子语义探针\n' > "$T/a.txt"
    ( cd "$T" && zg --index --mode direct --model-cache /opt/zg-models ) && ok "zg 离线索引" || bad "zg 索引失败"
    zg_out="$(cd "$T" && zg --search "水果原子" --mode direct --model-cache /opt/zg-models 2>&1)" || true
    printf '%s' "$zg_out" | grep -q "probe-one" && ok "zg 语义命中" || bad "zg 语义未命中:$(printf '%s' "$zg_out" | head -c 80)"
    rm -rf "$T"
fi

section "[$VIEW] E. 离线编译面(pi 闭包锚)"
if [ "$VIEW" = root ]; then
    L="${LOCKDIR:-/root/scripts/lock}/rust/Cargo.lock"
    if [ -f "$L" ]; then
        P="$(mktemp -d)"; cp "${L%/*}/Cargo.toml" "$L" "$P/"
        ( cd "$P" && cargo fetch --locked ) && ok "pi 锁定闭包 cargo fetch --locked(离线)" || bad "锁定闭包 fetch 失败"
        rm -rf "$P"
    else
        echo "  skip 锁文件缺席(LOCKDIR 未指)"
    fi
    out="$(timeout 20 go install github.com/dummy/notreal-pkg-xyz@latest 2>&1)" || true
    printf '%s' "$out" | grep -qi "GOPROXY=off" && ok "go 快失败" || bad "go 快失败异常"
    out="$(timeout 30 npm install -g definitely-not-a-real-pkg-xyz 2>&1)" || true
    printf '%s' "$out" | grep -qiE "ENOTCACHED|offline" && ok "npm 快失败" || bad "npm 快失败异常"
fi

section "[$VIEW] F. VNC 轻量面(裁定保留)"
[ -d /usr/share/novnc ] && ok "noVNC 在" || bad "noVNC 缺"
have vncserver && ok "tigervnc 在" || bad "tigervnc 缺"
[ "$VIEW" = ubuntu ] && { [ -x /usr/local/bin/vnc-screen ] && ok "vnc-screen 启动面在" || bad "vnc-screen 缺"; }

printf '\n== [%s] 汇总: PASS %d FAIL %d ==\n' "$VIEW" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

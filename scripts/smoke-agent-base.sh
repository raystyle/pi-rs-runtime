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
# 补面批(core v2 P0/P1/P2):JDK21 双面、zig+zigbuild 配对、系统件
chkout "javac"   "javac 21" 30 javac --version
chkout "java"    "java 21" 30 java --version
chkout "zig"     "0\.16\.[0-9]+" 15 zig version
chkout "cargo-zigbuild" "cargo-zigbuild 0\.23\.4" 15 cargo-zigbuild --version
chk   "ssh(oob_poll 件)"   command -v ssh
chk   "pkill(procps)"      command -v pkill
chk   "libgmp(jwt gcc 助手)" test -f /usr/lib/x86_64-linux-gnu/libgmp.so
# 基座不装面点名(装上即错):fnm 多版 node、dotnet、bun(rctl 已出镜像);
# zig 已翻正装(postex_build 的 cargo zigbuild 面,core 回执②)
have() { command -v "$1" >/dev/null 2>&1; }
! have dotnet && ok "dotnet 不在(基座口径)" || bad "dotnet 不应装"
! have bun    && ok "bun 不在(基座口径)" || bad "bun 不应装"
! have rctl   && ok "rctl 不在(基座口径)" || bad "rctl 不应装"

section "[$VIEW] C. 五面孔与引擎"
chkout "claude"        "claude" 30 claude --version
chkout "codex"         "codex" 30 codex --version
chkout "pi-rs"         "[0-9]+\.[0-9]+" 30 pi-rs --version
if [ "$VIEW" = root ]; then chkout "acpsup(自检)" "selftest PASS" 90 acpsup --selftest claude; fi   # 自检写 keys.json(0600 root),仅 root 视角
chk   "clean-chrome" clean-chrome --version
chk   "browse 版本"   browse --version
chk   "zg"            zg --version
chk   "systemd acpsup" systemctl is-active acpsup
[ -x /opt/clean-chrome/CURRENT/chrome ] && ok "chrome 单副本在(/opt/clean-chrome/CURRENT)" || bad "chrome 单副本缺席"
[ ! -e "$HOME/.browse-rs/chrome" ] && ok "browse 无托管副本(单副本口径)" || bad "browse 托管副本存在(应复用 chrome 组)"
[ -f /opt/zg-models/hf_Qwen_Qwen3-Embedding-0.6B-Q8_0.gguf ] && ok "zg 向量模型烤库在" || bad "zg 模型缺席"
# 原生 yolo 面配置断言(用户令:原生无阻塞交互;键名 grok 容器实证,行为探针在
# E2E 在线阶段——runbook §5,断网冒烟只验配置面)
if [ "$VIEW" = root ]; then H=/root; else H=/home/ubuntu; fi
grep -q '"defaultMode": "bypassPermissions"' /etc/claude-code/managed-settings.json && ok "claude 策略 bypassPermissions" || bad "managed-settings 缺 bypass"
grep -q '"IS_SANDBOX": "1"' /etc/claude-code/managed-settings.json && ok "claude 根闸 IS_SANDBOX=1(策略 env)" || bad "managed-settings 缺 IS_SANDBOX"
grep -q '"skipDangerousModePermissionPrompt": true' /etc/claude-code/managed-settings.json && ok "claude 免责框跳过键" || bad "缺 skipDangerousModePermissionPrompt"
grep -q 'hasCompletedOnboarding' "$H/.claude.json" && grep -q 'bypassPermissionsModeAccepted' "$H/.claude.json" && ok "claude TUI 首启预置键($H)" || bad "$H/.claude.json 预置缺"
[ -f /etc/profile.d/claude-yolo.sh ] && ok "profile.d 根闸面(登录壳)" || bad "profile.d/claude-yolo.sh 缺"
grep -q '^web_search = "disabled"' "$H/.codex/config.toml" && ok "codex web_search 移除(顶层正形)" || bad "codex web_search 形错($H)"
grep -q '^\[tools\.web_search\]' "$H/.codex/config.toml" && bad "codex 旧非法表残存($H)" || ok "codex 无旧表($H)"
grep -q '^approval_policy = "never"' "$H/.codex/config.toml" && grep -q '^sandbox_mode = "danger-full-access"' "$H/.codex/config.toml" && ok "codex never+全权($H)" || bad "codex approval/sandbox 形错($H)"

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
    export ZVEC_JIEBA_DICT_DIR=/usr/local/share/zvec/jieba_dict
    ( cd "$T" && zg --index --mode direct --model-cache /opt/zg-models ) && ok "zg 离线索引" || bad "zg 索引失败"
    zg_out="$(cd "$T" && zg "水果原子" --mode direct --model-cache /opt/zg-models 2>&1)" || true
    printf '%s' "$zg_out" | grep -q "probe-one" && ok "zg 语义命中" || bad "zg 语义未命中:$(printf '%s' "$zg_out" | head -c 80)"
    rm -rf "$T"
fi

section "[$VIEW] D3. 补面批实跑面(JDK 编译跑 / zigbuild 配对 / piocr pin 全绿)"
if [ "$VIEW" = root ]; then
    # java_ser 全流程形(core 回执①):javac 编译 → java 跑 Main,离线零网络
    J="$(mktemp -d)"
    printf 'public class P{public static void main(String[] a){System.out.println("jprobe-ok");}}\n' > "$J/P.java"
    ( cd "$J" && timeout 60 javac -d classes P.java ) && ok "javac 编译" || bad "javac 编译失败"
    out="$(cd "$J" && timeout 30 java -cp classes P 2>&1)" || true
    printf '%s' "$out" | grep -q "jprobe-ok" && ok "java 跑 Main" || bad "java 未跑:$(printf '%s' "$out" | head -c 80)"
    ( cd "$J" && timeout 60 javac --release 8 -d classes8 P.java ) && ok "javac --release 8 档位" || bad "--release 8 档位失败(老 gadget 源面)"
    rm -rf "$J"
    # cargo-zigbuild 配对(F-C2:上游无版本矩阵,唯一证法=实跑 musl 出件;零依赖 crate 全离线)
    Z="$(mktemp -d)"
    ( cd "$Z" && cargo init --name zprobe -q ) 2>/dev/null || ( cd "$Z" && mkdir -p src && printf '[package]\nname="zprobe"\nversion="0.0.0"\nedition="2021"\n' > Cargo.toml && printf 'fn main(){println!("z-ok");}\n' > src/main.rs )
    ( cd "$Z" && timeout 240 cargo zigbuild --release --target x86_64-unknown-linux-musl ) \
        && ok "cargo zigbuild musl 出件" || bad "zigbuild 1-2-3 失败(zig 0.16 x cargo-zigbuild 0.23.4 配对断?)"
    if [ -f "$Z/target/x86_64-unknown-linux-musl/release/zprobe" ]; then
        out="$(file "$Z/target/x86_64-unknown-linux-musl/release/zprobe")" || true
        printf '%s' "$out" | grep -q "statically linked" && ok "musl 静态件" || bad "非静态件:$out"
        out="$("$Z/target/x86_64-unknown-linux-musl/release/zprobe" 2>&1)" || true
        printf '%s' "$out" | grep -q "z-ok" && ok "musl 件实跑" || bad "musl 件跑失败:$out"
    else
        bad "zigbuild 未出件"
    fi
    rm -rf "$Z"
    # piocr 烤库 pin 全绿(install_piocr 同源抽析,smoke 不硬编码锚——与所装 pi-rs 自洽)
    O=/opt/pi-rs/dist/extensions/rust_script/lib/ocr/src/lib.rs
    if [ -f "$O" ] && [ -x /usr/bin/python3 ]; then
        python3 - "$O" <<'PY' > /tmp/piocr-smoke.sha
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"const PACKAGES:.*?=\s*&\[(.*?)\n\];", src, re.S)
for blk in re.finditer(r"PackagePin \{(.*?)\n    \},", m.group(1), re.S):
    b = blk.group(1)
    name = re.search(r'name:\s*"([^"]+)"', b)
    if not name or name.group(1) not in ("tiny-det", "tiny-rec"):
        continue
    for f in re.finditer(r'FilePin \{ name: "([^"]+)", bytes: (\d[\d_]*), sha256: "([0-9a-f]+)" \}', b):
        print(f"{f.group(3)}  /opt/pi-ocr-models/{name.group(1)}/{f.group(1)}")
PY
        if [ "$(wc -l < /tmp/piocr-smoke.sha)" -eq 8 ]; then
            sha256sum -c /tmp/piocr-smoke.sha >/dev/null 2>&1 && ok "piocr 8 文件 pin 全绿" || bad "piocr pin 校验败(烤库内容漂移)"
        else
            bad "piocr pin 抽析非 8 行(口径漂移)"
        fi
        rm -f /tmp/piocr-smoke.sha
    else
        bad "piocr 抽析前提缺(dist lib.rs 或 python3)"
    fi
fi

section "[$VIEW] E. 离线编译面(pi 闭包锚)"
if [ "$VIEW" = root ]; then
    L="${LOCKDIR:-/root/scripts/lock}/rust/Cargo.lock"
    if [ -f "$L" ]; then
        P="$(mktemp -d)"; cp "${L%/*}/Cargo.toml" "$L" "$P/"
        mkdir -p "$P/src"; printf 'fn main(){}\n' > "$P/src/main.rs"
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

section "[$VIEW] E2. pi-rs 引擎面探针(core G1:防 jieba/模型静默降级)"
if [ "$VIEW" = root ]; then
    # F2 类缺陷盲区:rctl zg CLI 面绿不等于 pi-rs 发行件内嵌引擎绿——直接调 pi-rs 面验
    T2="$(mktemp -d)"
    printf 'id: probe-sem\ndesc: 樱桃原子语义探针\n' > "$T2/a.txt"
    out="$(cd "$T2" && timeout 90 pi-rs -p '在当前目录搜「樱桃原子」,直接给文件名,不要其他内容' 2>&1)" || true
    printf '%s' "$out" | grep -q "a.txt" && ok "pi-rs rs_search 中文语义命中" || bad "pi-rs 搜索未命中(jieba/模型落位疑):$(printf '%s' "$out" | head -c 120)"
    rm -rf "$T2"
fi

section "[$VIEW] F. VNC 直显与桌面面"
chk "Xvfb" command -v Xvfb   # 此版 Xvfb 无 -version 旗标,验在位即可
chk "x11vnc" x11vnc -version
chk "xauth" xauth info   # -v 无参会挂等 stdin(--user 执行面实测)
if [ "$VIEW" = root ]; then [ -d /var/lib/acpsup/vnc ] && ok "acpsup vnc 基目录在" || bad "vnc 基目录缺"; fi   # 0700 root
# 直显面二进制与显示口纪律(主动桥面在 E2E 阶段验,冒烟只验在位)
[ -d /usr/share/novnc ] && ok "noVNC 在" || bad "noVNC 缺"
have vncserver && ok "tigervnc 在" || bad "tigervnc 缺"
[ "$VIEW" = ubuntu ] && { [ -x /usr/local/bin/vnc-screen ] && ok "vnc-screen 启动面在" || bad "vnc-screen 缺"; }
# 补面批:常驻桌面栈(desktop 组三 unit,Xvfb :99 + xfce + x11vnc 5900)
if [ "$VIEW" = root ]; then
    chk "systemd xvfb99"       systemctl is-active xvfb99
    chk "systemd xfce-desktop" systemctl is-active xfce-desktop
    chk "systemd x11vnc99"     systemctl is-active x11vnc99
    [ -S /tmp/.X11-unix/X99 ] && ok "X99 套接字在" || bad "X99 套接字缺"
    # RFB 横幅:5900 回环直读(bash /dev/tcp;超时饿死=任何阻塞交互即红)
    out="$(timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/5900; head -c 12 <&3' 2>&1)" || true
    printf '%s' "$out" | grep -q "RFB 003\." && ok "RFB 横幅(5900 回环)" || bad "RFB 横幅未吐:$(printf '%s' "$out" | head -c 60)"
    # 口令端点(admin 面,回环):JSON 应带 password(a/b 道共用的 RFB 鉴权源)
    tok="$(cat /var/lib/acpsup/token 2>/dev/null || true)"
    if [ -n "$tok" ]; then
        out="$(timeout 10 curl -s -H "Authorization: Bearer $tok" http://127.0.0.1:7663/vnc/desktop 2>&1)" || true
        printf '%s' "$out" | grep -q '"password"' && ok "/vnc/desktop 口令端点" || bad "口令端点未出:$(printf '%s' "$out" | head -c 80)"
    else
        bad "acpsup token 缺(端点探针前提)"
    fi
fi

printf '\n== [%s] 汇总: PASS %d FAIL %d ==\n' "$VIEW" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

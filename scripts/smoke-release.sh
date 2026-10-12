#!/usr/bin/env bash
# pi-rs-runtime 发布门禁冒烟(每轮 publish 前可复跑面;2026-10-11 chrome 下架批即席回归版收编,smoke-01 评审吸收)
# 用法: bash smoke-release.sh <view: root|ubuntu>;视角取值与 id -un 双守卫,不符退 2
# 宿主侧完整跑法(双视角,实例名以当前工作实例为准):
#   incus file push scripts/smoke-release.sh <实例>/root/scripts/
#   incus exec <实例> -- bash -c 'mkdir -p /home/ubuntu/scripts && cp /root/scripts/smoke-release.sh /root/scripts/vnc-screen.sh /home/ubuntu/scripts/ && cp -r /root/scripts/lock /home/ubuntu/scripts/lock && chown -R 1000:1000 /home/ubuntu/scripts && chmod -R a+rX /home/ubuntu/scripts'
#   incus exec <实例> -- ip link set eth0 down
#   incus exec <实例> -- bash /root/scripts/smoke-release.sh root
#   incus exec <实例> --user 1000 --group 1000 -- env HOME=/home/ubuntu LOCKDIR=/home/ubuntu/scripts/lock VNCSCRIPT=/home/ubuntu/scripts/vnc-screen.sh bash /home/ubuntu/scripts/smoke-release.sh ubuntu
#   incus exec <实例> -- ip link set eth0 up
# 前置: eth0 已 down(由调用方控制升降;root 视角 A 节自证断网,ubuntu 视角不自证)
# 口径: 断言看输出;不用 cmd|head 退出码;计数 PASS/FAIL,尾行汇总;FAIL>0 退出非 0(门禁败态);skip 不计分
set -u
VIEW="${1:?用法: smoke-release.sh root|ubuntu}"
case "$VIEW" in root|ubuntu) ;; *) printf '视角取值非法:%s(只收 root|ubuntu)\n' "$VIEW" >&2; exit 2;; esac
[ "$(id -un)" = "$VIEW" ] || { printf '视角 %s 与实际 uid %s 不符,双视角须按头注释跑法分别起进程\n' "$VIEW" "$(id -un)" >&2; exit 2; }
cd "$HOME" 2>/dev/null || cd /tmp   # incus exec 默认 cwd=/root,ubuntu 不可读,工具启动要 stat cwd
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
# chk <desc> <cmd...>:rc==0 即过
chk() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# chkout <desc> <pattern> <timeout> <cmd...>:输出含 pattern 即过(超时无匹配算败,超时但已有匹配仍过)
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

section "[$VIEW] B. 编译器/运行时版本面"
chkout "gcc"       "Free Software Foundation|[0-9]+\.[0-9]+\.[0-9]+" 15 gcc --version
chkout "g++"       "[0-9]+\.[0-9]+" 15 g++ --version
chkout "rustc"     "rustc [0-9]" 15 rustc --version
chkout "cargo"     "cargo [0-9]" 15 cargo --version
chkout "go"        "go version go[0-9]" 15 go version
chkout "zig"       "[0-9]+\.[0-9]+" 30 zig version
chkout "nim"       "Nim Compiler Version [0-9]" 30 nim -v
chkout "java"      "version" 30 java -version
chkout "dotnet"    "[0-9]+\.[0-9]+" 60 dotnet --version
chkout "python3"   "Python 3" 15 python3 --version
chkout "python2"   "Python 2" 15 python2 --version
chkout "php"       "PHP [0-9]" 15 php -v
chkout "mono"      "Mono JIT compiler version [0-9]" 30 mono --version
chkout "pwsh"      "[0-9]+\.[0-9]+" 60 pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
chkout "nu"        "[0-9]+\.[0-9]+" 30 nu --version
chkout "bun"       "[0-9]+\.[0-9]+" 30 bun --version
chkout "uv"        "uv [0-9]" 15 uv --version
chkout "git"       "git version [0-9]" 15 git --version
node_bin="$(command -v node || true)"
[ -n "$node_bin" ] && ok "node 在 PATH($node_bin)" || bad "node 不在 PATH"
[ -n "$node_bin" ] && chkout "node 版本" "v[0-9]+" 30 node --version
chkout "duckdb"    "[0-9]+\.[0-9]+" 30 duckdb --version
chk "clickhouse 在" bash -c 'command -v clickhouse'

section "[$VIEW] C. 工具面 command -v 扫描"
SWEEP="fd rg bat jq yq gh just shellcheck tmux rclone aria2c fzf htop vim ast-grep sg herdr \
subfinder dnsx naabu httpx nuclei katana uncover cloudlist notify interactsh-client chaos mapcidr asnmap tlsx proxify simplehttpserver shuffledns pdtm urlfinder cvemap \
ffuf gobuster dalfox amass chisel gitleaks assetfinder httprobe qsreplace waybackurls gau gospider gowitness azurehound nerva brutus aurelian trufflehog \
gost frps frpc wstunnel rathole bore \
binwalk yara cstool rizin readelf objdump eu-readelf \
nasm gdb gdb-multiarch qemu-x86_64-static checksec patchelf xxd unsquashfs nmap sqlmap tcpdump tshark mitmdump john hashid upx exiftool ssdeep \
jadx apktool capa donut pdfid.py pdf-parser.py \
dig whois socat nc telnet ftp snmpwalk proxychains4 ldapsearch smbclient mysql psql redis-cli sqlite3 xfreerdp sshuttle openvpn wg masscan hashcat hydra adb fastboot fls testdisk pdftotext unar cabextract qpdf zbarimg aircrack-ng steghide osslsigncode sasquatch responder cewl \
ghauri kerbrute wafw00f arjun bloodhound-python mitm6 objection apkleaks certipy bloodyAD bofhound semgrep coercer enum4linux-ng krbrelayx jwt-tool linkfinder evil-winrm feroxbuster trivy \
ghidraRun analyzeHeadless msfconsole frida \
nu vncserver Xvfb x11vnc websockify startxfce4 \
rctl acpsup rea phpggc commix sstimap zg overthrone ovt"
miss=0
for t in $SWEEP; do
    command -v "$t" >/dev/null 2>&1 || { miss=$((miss+1)); printf '  FAIL 缺 %s\n' "$t"; }
done
[ "$miss" = 0 ] && ok "工具面 $(echo $SWEEP | wc -w) 项全在" || bad "工具面缺 ${miss} 项(见上)"
chk "pwndbg 入口(uv tool)" bash -c 'command -v pwndbg'

section "[$VIEW] D. wrapper 实跑面(断网真跑,断言收在用法行)"
chkout "nuclei -version(wrapper -duc)" "nuclei engine|nuclei version" 60 nuclei -version
chkout "trivy --version(wrapper env)" "Version:" 60 trivy --version
chkout "capa --version" "[0-9]+\.[0-9]+" 60 capa --version
chkout "jwt-tool 裸跑(re-venv 依赖)" "usage: jwt_tool.py" 60 jwt-tool
chkout "linkfinder 裸跑(re-venv 依赖)" "usage: linkfinder" 30 linkfinder
chkout "responder -h(wrapper+re-venv)" "Usage: python3 Responder" 30 responder -h
chkout "enum4linux-ng -h" "enum4linux.{0,40}next generation" 60 enum4linux-ng -h
chkout "krbrelayx --help" "usage: krbrelayx" 30 krbrelayx --help
chkout "bloodhound-python --help" "usage: __main__.py.*COLLECTIONMETHOD" 60 bloodhound-python --help

section "[$VIEW] E. 离线构建面(锁消费路径,双视角)"
# LOCKDIR:root 视角用 /root/scripts/lock;ubuntu 视角由调用方指到可读拷贝(镜像 /root 0700)
LOCKD="${LOCKDIR:-/root/scripts/lock}"
T="$(mktemp -d /tmp/smoke-XXXXXX)"
# E1 go:GOPROXY=off 从 /opt/go 模块缓存编译(prewarm 工程自带 go.mod+go.sum,自包含)
( cp -r /opt/go-prewarm "$T/go" && cd "$T/go" \
  && GOPROXY=off timeout 600 go build -o "$T/gobin" . ) \
  && [ -x "$T/gobin" ] && ok "go build GOPROXY=off(prewarm 工程)" || bad "go build 离线失败"
# E2 cargo:锁文件离线 fetch(--locked --offline,缓存热面)
( mkdir -p "$T/cargo/src" && cp "$LOCKD/rust/Cargo.toml" "$LOCKD/rust/Cargo.lock" "$T/cargo/" \
  && printf 'fn main() {}\n' > "$T/cargo/src/main.rs" \
  && cd "$T/cargo" && timeout 300 cargo fetch --locked --offline ) \
  && ok "cargo fetch --locked --offline(仓锁)" || bad "cargo fetch --locked --offline 失败"
# E3 node:require 全局面(js-lab 链)
[ -n "$node_bin" ] && chkout "node require(js-lab 全局面)" "node-face-ok" 60 node -e "require('express');require('webcrack');require('crypto-js');console.log('node-face-ok')"
# E4 pip:轮子库直装
( python3 -m pip install -q --no-index --find-links /opt/wheelhouse --target "$T/py" asn1crypto \
  && python3 -c "import sys; sys.path.insert(0,'$T/py'); import asn1crypto; print('pip-ok')" ) \
  && ok "pip --no-index 轮子直装+import" || bad "pip 离线直装失败"
# E5 mvn:-o 从 /opt/m2 解析
( mkdir -p "$T/mvn" && cp "$LOCKD/java/pom.xml" "$T/mvn/" && cd "$T/mvn" \
  && timeout 300 mvn -o -q -DskipTests compile ) \
  && ok "mvn -o 离线编译(锁 pom)" || bad "mvn -o 失败"
# E5b dotnet 离线凭据:每用户 NuGet fallback 配置须真声明固化仓
chk "NuGet fallbackPackageFolders 配置在" bash -c '[ -r "$HOME/.nuget/NuGet/NuGet.Config" ] && grep -q fallbackPackageFolders "$HOME/.nuget/NuGet/NuGet.Config"'
# E6 dotnet:restore 走 fallback 固化仓
( mkdir -p "$T/dotnet" && cp /opt/dotnet-prewarm/dotnet-prewarm.csproj "$T/dotnet/" && cd "$T/dotnet" \
  && DOTNET_CLI_TELEMETRY_OPTOUT=1 timeout 300 dotnet restore ) \
  && ok "dotnet restore(fallback 仓)" || bad "dotnet restore 离线失败"
# E7 zig:锁 zon fetch
( cp -r /opt/zig-prewarm "$T/zig" && cd "$T/zig" && timeout 300 zig build --fetch ) \
  && ok "zig build --fetch(锁 zon)" || bad "zig build --fetch 失败"
rm -rf "$T"

section "[$VIEW] F. 参考库与数据在位"
[ -d /opt/SecLists ] && n=$(find /opt/SecLists -maxdepth 2 | wc -l) && [ "$n" -gt 50 ] && ok "SecLists($n 条目)" || bad "SecLists 缺"
rock="$(find /opt /usr/share -maxdepth 4 -name 'rockyou*' 2>/dev/null | head -1)"
[ -n "$rock" ] && ok "rockyou 在($rock)" || bad "rockyou 未找到"
chk "trivy-db 非空" bash -c '[ -n "$(ls -A /opt/trivy-db)" ]'
n=$(find /opt/nuclei-templates -name '*.yaml' 2>/dev/null | wc -l); [ "$n" -gt 5000 ] && ok "nuclei 模板($n)" || bad "nuclei 模板 $n"
chk "capa-rules 非空" bash -c '[ -d /opt/capa-rules ] && [ -n "$(ls -A /opt/capa-rules)" ]'
n=$(find /opt/frida-server -mindepth 2 -maxdepth 2 -type f 2>/dev/null | wc -l); [ "$n" -ge 8 ] && ok "frida-server 平台件($n)" || bad "frida-server $n 件"
for d in payload-ref tradecraft-ref c2dev-ref recon-ref pz-sandbox-tools windows-logical-eop-workshop yara-rules cyberchef metasploit-framework ghidra; do
    [ -d "/opt/$d" ] && ok "参考/大件 $d" || bad "参考/大件 $d 缺"
done

section "[$VIEW] G. 五生态默认快失败(运行期离线面)"
# G0 离线配置凭据:cargo [net] offline 与 uv 用户级覆盖
chk "cargo [net] offline 配置在" bash -c '[ -r "$HOME/.cargo/config.toml" ] && grep -q "offline *= *true" "$HOME/.cargo/config.toml"'
[ -e "$HOME/.config/uv/uv.toml" ] && bad "用户级 uv.toml 在,会整份盖掉全局 offline 面" || ok "无用户级 uv.toml 覆盖"
gs="$(mktemp -d)"; cd "$gs" || bad "G 节 cd 失败,以下探针可能落错目录"
out="$(timeout 20 go install github.com/dummy/notreal-pkg-xyz@latest 2>&1)" || true
printf '%s' "$out" | grep -qi "GOPROXY=off" && ok "go:module lookup disabled 快失败" || bad "go 快失败异常:$(printf '%s' "$out" | head -c 80)"
mkdir "$gs/npm" && cd "$gs/npm" && out="$(timeout 30 npm install definitely-not-a-real-pkg-xyz 2>&1)" || true
printf '%s' "$out" | grep -qi "ENOTCACHED" && ok "npm:ENOTCACHED 快失败" || bad "npm 快失败异常:$(printf '%s' "$out" | head -c 80)"
cd "$gs" 2>/dev/null || bad "G 节 cd 失败(回到工作目录)"
out="$(timeout 20 uv venv uvsmoke -q && VIRTUAL_ENV="$gs/uvsmoke" timeout 20 uv pip install definitely-not-a-real-pkg-xyz 2>&1)" || true
printf '%s' "$out" | grep -qiE "network was disabled|offline" && ok "uv:network disabled 快失败" || bad "uv 快失败异常:$(printf '%s' "$out" | head -c 80)"
out="$(timeout 30 python3 -m pip install --dry-run --break-system-packages definitely-not-a-real-pkg-xyz 2>&1)" || true
printf '%s' "$out" | grep -qiE "No matching distribution" && ok "pip:No matching distribution 快失败(假包名面)" || bad "pip 快失败异常:$(printf '%s' "$out" | head -c 80)"
mkdir "$gs/cargo" && cd "$gs/cargo" && mkdir -p src && printf '[package]\nname="smk"\nversion="0.1.0"\nedition="2021"\n[dependencies]\nnot-a-real-crate-xyz="1"\n' > Cargo.toml \
  && printf 'fn main() {}\n' > src/main.rs && out="$(timeout 30 cargo fetch 2>&1)" || true
printf '%s' "$out" | grep -qiE "offline|not found|no matching" && ok "cargo:未缓存 crate 快失败(离线配置已由 G0 单证)" || bad "cargo 快失败异常:$(printf '%s' "$out" | head -c 80)"
cd /; rm -rf "$gs"

if [ "$VIEW" = root ]; then
section "[root] H. apt 快失败(离线不可装;lists 清留由 clean-image 在 publish 收口)"
out="$(timeout 40 apt-get install -y sl 2>&1)" || true
printf '%s' "$out" | grep -qiE "Unable to locate|Unable to fetch|Temporary failure|无法定位" \
  && ok "apt 离线不可装(定位态=lists 已清或取包态=lists 在网断,两态任一)" \
  || bad "apt 异常:$(printf '%s' "$out" | head -c 80)"

section "[root] I. chrome 下架回归"
chk "/opt/clean-chrome 已卸" bash -c '[ ! -e /opt/clean-chrome ]'
for l in clean-chrome chromium chrome; do
    [ -e "/usr/local/bin/$l" ] && bad "/usr/local/bin/$l 残留" || ok "/usr/local/bin/$l 无残留"
done
out="$(timeout 20 bash /root/scripts/vnc-screen.sh chrome 2>&1)"; rc=$?
printf '%s' "$out" | grep -q "clean-chrome 未装" && [ "$rc" = 1 ] && ok "vnc chrome 面降级报错(rc=1)" || bad "vnc chrome 面异常 rc=$rc:$(printf '%s' "$out" | head -c 80)"
grep -Eq '^TOOLS_ALL=\([^)]*\<chrome\>' /root/scripts/install-tools.sh && bad "TOOLS_ALL 默认仍含 chrome" || ok "TOOLS_ALL 默认无 chrome(词边界匹配)"
grep -q "install_chrome()" /root/scripts/install-tools.sh && ok "chrome 组保留(显式可装)" || bad "chrome 组函数丢失"
pgrep -af "clean-chrome|remote-debugging-port" >/dev/null 2>&1 && bad "chrome 进程残留" || ok "无 chrome 进程"
ss -ltn | grep -q ":9222 " && bad "9222 端口残留监听" || ok "9222 无监听"
for p in /root/.clean-chrome-profile /home/ubuntu/.clean-chrome-profile; do
    [ -e "$p" ] && bad "chrome profile 目录残留:$p(冒烟产物,建议清)" || ok "$p 无残留"
done

section "[root] J1. 环境一致性"
grep -q "chrome)" /root/scripts/vnc-screen.sh && ok "vnc-screen.sh chrome 冒烟面仍在(留给显式装机后)" || bad "vnc-screen.sh chrome 冒烟面分支丢失"
ls /usr/local/sdkman/candidates/java >/dev/null 2>&1 && ok "sdkman JDK 面在($(ls /usr/local/sdkman/candidates/java | wc -l) 版)" || bad "sdkman 缺"
fi

if [ "$VIEW" = ubuntu ]; then
section "[ubuntu] J2. VNC 轻量面实跑(离线,VNCSCRIPT 指 ubuntu 可读拷贝)"
VNCSCRIPT="${VNCSCRIPT:-/root/scripts/vnc-screen.sh}"
out="$(cd /home/ubuntu && VNC_PASS=smoketest timeout 60 bash "$VNCSCRIPT" start 2>&1)" || true
printf '%s' "$out" | grep -q "轻量 VNC: 127.0.0.1:5900(仅回环)" && ok "轻量面 Xvfb+x11vnc 5900 回环" || bad "轻量面启动异常:$(printf '%s' "$out" | tail -c 120)"
ss -ltn | grep -q "127\.0\.0\.1:5900 " && ok "5900 有回环监听" || bad "5900 无回环监听(启动行失败?)"
nolib="$(ss -ltn | grep ":5900 " | grep -cvE "127\.0\.0\.1|\[::1\]" || true)"
[ "$nolib" = 0 ] && ok "5900 仅回环绑定" || bad "5900 有非回环监听($nolib 行)"
timeout 20 bash "$VNCSCRIPT" stop >/dev/null 2>&1 && ok "轻量面 stop 脚本面 rc=0" || bad "stop 脚本面异常"
sleep 1; ss -ltn | grep -q ":5900 " \
  && echo "  skip 5900 停后仍监听(宿主信号策略,known-issues;残留待容器重启清,不计分)" \
  || ok "5900 已停"
fi

printf '\n===_summary view=%s pass=%d fail=%d===\n' "$VIEW" "$PASS" "$FAIL"
[ "$FAIL" = 0 ]

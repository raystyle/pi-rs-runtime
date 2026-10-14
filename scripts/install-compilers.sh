#!/usr/bin/env bash
# 编译器安装器:c / golang / rust / zig
# 在 Ubuntu 24.04 容器(或宿主)内运行,幂等,可重复执行。
# 用法:
#   ./install-compilers.sh            # 装全部
#   ./install-compilers.sh rust  # 只装指定项(可多个)
# 镜像源与版本经环境变量覆盖,见 lib/common.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

install_c() {
    log "C 工具链 (apt: build-essential clang cmake ninja …)"
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        build-essential clang lldb gdb cmake ninja-build pkg-config \
        autoconf automake libtool m4 \
        clang-format clang-tidy valgrind strace ltrace ccache musl-tools \
        zlib1g-dev libssl-dev libffi-dev
    # strace/ltrace/valgrind:逆向与行为分析常规件;musl-tools:静态链接;ccache:编译缓存
    # FASM:Ubuntu 源没有,官方小 tarball 直下(nasm 在 P0 apt 批)
    if ! have fasm; then
        local fv="${FASM_VERSION:-1.73.32}"
        curl -fSL "https://flatassembler.net/fasm-${fv}.tgz" -o /tmp/fasm.tgz
        rm -rf /opt/fasm && mkdir -p /opt/fasm
        tar -C /opt/fasm -xzf /tmp/fasm.tgz && rm /tmp/fasm.tgz
        # 包内顶层是 fasm/ 目录;amd64 要用 fasm.x64(fasm 是 32 位)
        [ -e /opt/fasm/fasm/fasm.x64 ] && ln -sf /opt/fasm/fasm/fasm.x64 /usr/local/bin/fasm \
            || ln -sf /opt/fasm/fasm/fasm /usr/local/bin/fasm
    fi
    fasm -v 2>/dev/null | head -1 || true
}

install_golang() {
    log "golang $GOLANG_VERSION (下载 $GO_DOWNLOAD,GOPROXY=$GOPROXY)"
    # go env per-user 文件(非登录 shell 也读),root/ubuntu 同形;默认 GOPROXY=off 快失败
    # (纯离线镜像默认面;构建脚本经 common.sh export 真实代理,env 优先于此文件);
    # 放在早退前直写文件(不依赖 go 二进制),保证重跑组时两份都会刷新
    local gu
    for gu in /root /home/ubuntu; do
        [ -d "$gu" ] || continue
        install -d "$gu/.config/go"
        printf 'GOPROXY=off\nGOSUMDB=%s\nGOPATH=/opt/go\nGOMODCACHE=/opt/go/pkg/mod\n' "${GOSUMDB}" > "$gu/.config/go/env"
    done
    chown -R ubuntu:ubuntu /home/ubuntu/.config 2>/dev/null || true
    # profile.d 与 bin 链接同为配置,一并放早退前:存在才链(首装由下文安装段补链),重跑必刷新
    cat > /etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\${GOPATH:-/opt/go}
export PATH=\$PATH:\$GOPATH/bin
EOF
    [ -e /usr/local/go/bin/go ] && ln -sf /usr/local/go/bin/go /usr/local/bin/go
    # 基座口径:go 工具链本体即面(acpsup 编译用);开发三件套(dlv/gopls/golangci-lint)
    # 与跳板库预热不装(产品道 install-all.sh 面,main 分支)
    if have go && [ "$(go env GOVERSION)" = "go$GOLANG_VERSION" ]; then
        echo "已安装 $(go env GOVERSION),跳过"; return
    fi
    local tgz="go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    curl -fSL "${GO_DOWNLOAD}/${tgz}" -o "/tmp/${tgz}"
    # 校验和:官方 JSON 提供每平台 sha256(镜像站不带 .sha256 文件,不从目录取)
    if have python3; then
        local want
        want="$(curl -fsSL "https://golang.google.cn/dl/?mode=json" | python3 -c "
import json,sys
for rel in json.load(sys.stdin):
    for f in rel.get('files',[]):
        if f['filename']=='${tgz}': print(f['sha256']); break
")"
        if [ -n "$want" ]; then
            echo "${want}  /tmp/${tgz}" | sha256sum -c - || { echo "go tarball 校验失败"; exit 1; }
        fi
    fi
    rm -rf /usr/local/go && tar -C /usr/local -xzf "/tmp/${tgz}" && rm "/tmp/${tgz}"
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    export PATH=$PATH:/usr/local/go/bin
    # go env 由组首直写 root/ubuntu 两份(GOPROXY=off 默认面);本函数后续 go install
    # 走 common.sh export 的 GOPROXY(env 优先于 go env 文件),不受影响
    export PATH=$PATH:/usr/local/go/bin
    go version
}

install_rust() {
    log "rust (rustup 与 crates index 均走 tuna;工具链归 /opt 多用户可读)"
    # RUSTUP_HOME/CARGO_HOME 指 /opt:/root 是 0700,ubuntu 执行不了 /root/.cargo 下
    # 的 rustc/cargo;fresh 构建从这起装对位置(评审 F5)
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    # 判据加执行探针:shim 在但工具链缺(rustup-init 上半程失败残留)时 have 通过,
    # 下文 rustup component add 必炸且重跑永不重进 rustup-init、无自愈路径;探针失败即重装补链
    if ! have rustc || ! rustc --version >/dev/null 2>&1; then
        local triple="x86_64-unknown-linux-gnu"
        [ "$(dpkg --print-architecture)" = arm64 ] && triple="aarch64-unknown-linux-gnu"
        curl -fSL "${RUSTUP_UPDATE_ROOT}/dist/${triple}/rustup-init" -o /tmp/rustup-init
        chmod +x /tmp/rustup-init
        /tmp/rustup-init -y --default-toolchain stable --profile minimal
        rm /tmp/rustup-init
    fi
    mkdir -p /opt/cargo
    cat > /opt/cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'tuna-sparse'

[source.tuna-sparse]
registry = "sparse+${CRATES_INDEX}/"

[registries.tuna]
index = "sparse+${CRATES_INDEX}/"

[net]
git-fetch-with-cli = true
# 离线优先默认(2026-10-14 适配收口):pi_rust_lib 0.5.0 依赖闭包顶(jaq-all/duct/cancel-this/
# tokio 族/serde_json/bytes/sha1 等)已进 scripts/lock/rust 预热锁与 /opt/cargo 缓存,
# 离线解析不再缺件;构建脚本经 common.sh export CARGO_NET_OFFLINE=false 拿回在线面
offline = true
EOF
    # rustup 更新通道持久化(tuna 帮助口径),否则 rustup update 回官方源
    # RUSTUP_HOME/CARGO_HOME 一并导出:不导出则 ubuntu 会在自己家目录再下一套,断网即挂
    cat > /etc/profile.d/rustup.sh <<EOF
export RUSTUP_HOME=${RUSTUP_HOME}
export CARGO_HOME=${CARGO_HOME}
export RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER}
export RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT}
export CARGO_ZIGBUILD_CACHE_DIR=/opt/cargo-zigbuild-cache
EOF
    # 非登录 shell 不读 rustup.sh:默认位软链兜底;缓存要可写,共同组共享(grok F1)
    install -d /opt/cargo-zigbuild-cache
    for u in /root /home/ubuntu; do
        [ -d "$u" ] || continue
        install -d "$u/.cache"
        [ -L "$u/.cache/cargo-zigbuild" ] || rm -rf "$u/.cache/cargo-zigbuild"
        ln -sfn /opt/cargo-zigbuild-cache "$u/.cache/cargo-zigbuild"
    done
    shared_writable_cache /opt/cargo-zigbuild-cache
    . /opt/cargo/env
    # 基座口径:llvm-tools(rust-lld,pi-rs 件执行链链接器)+ rust-script;
    # fmt/clippy/rust-analyzer 组件、九交叉 target、cargo-zigbuild/cargo-audit 不装
    # (产品道 install-all.sh 面,main 分支)
    rustup component add llvm-tools
    have rust-script      || cargo_install_pin rust-script
    # rust-lld 进 PATH(pi-rs 件执行链直接当链接器用)
    # 注意:ls 多操作数有一个不存在即返回 2,pipefail 下会让赋值语句整个失败退出;
    # 末尾 || true 兜底,两个布局(新版 /opt/rustup、旧版 /root/.rustup)都探
    local rlld; rlld="$(ls /opt/rustup/toolchains/*/lib/rustlib/*/bin/rust-lld /root/.rustup/toolchains/*/lib/rustlib/*/bin/rust-lld 2>/dev/null | head -1 || true)"
    [ -n "$rlld" ] && ln -sf "$rlld" /usr/local/bin/rust-lld
    for b in rustc cargo rustup rust-script; do
        [ -e /opt/cargo/bin/$b ] && ln -sf /opt/cargo/bin/$b "/usr/local/bin/$b"
    done
    # 家目录兼容链:非登录 shell(incus exec/systemd/cron)不读 profile.d,
    # rustup shim 回落 \$HOME/.rustup 会报 no default;链到 /opt 共享布局(fresh 验收实证)
    for _h in /root /home/ubuntu; do
        [ -d "$_h" ] || continue
        [ -e "$_h/.rustup" ] && [ ! -L "$_h/.rustup" ] && mv "$_h/.rustup" "$_h/.rustup.bak"
        [ -e "$_h/.cargo" ] && [ ! -L "$_h/.cargo" ] && mv "$_h/.cargo" "$_h/.cargo.bak"
        ln -sfn /opt/rustup "$_h/.rustup"
        ln -sfn /opt/cargo "$_h/.cargo"
    done
    # pi-rs 件生态预热:cargo fetch 拉进 registry 缓存(经 tuna),件首跑不再下载
    local pw=/tmp/rust-prewarm
    rm -rf "$pw" && mkdir -p "$pw/src" && printf 'fn main(){}\n' > "$pw/src/main.rs"
    cat > "$pw/Cargo.toml" <<'EOF'
[package]
name = "prewarm"
version = "0.0.0"
edition = "2021"

[dependencies]
# pi-rs rs-script 件外部 crate(全景清单 29 个,去重;cj-*/cancel-this 为仓内 vendor 不预热)
ureq = "*"
url = "*"
rustls = "*"
webpki-roots = "*"
tokio = { version = "*", features = ["full"] }
tokio-rustls = "*"
reqwest = "*"
tungstenite = "*"
libc = "*"
hpack = "*"
sha1 = "*"
sha2 = "*"
hmac = "*"
base64 = "*"
num-bigint = "*"
regex = "*"
ignore = "*"
grep-matcher = "*"
grep-regex = "*"
grep-searcher = "*"
anyhow = "*"
chrono = "*"
serde_json = "*"
duct = "*"
bytes = "*"
jaq-std = "*"
jaq-json = "*"
tokio-socks = "*"   # SOCKS5 客户端(跳板链)
async-socks5 = "*"
EOF
    ( cd "$pw" && cargo fetch --quiet ) && echo "件 crate 生态已预热进 cargo 缓存" || echo "!! 预热失败(不影响链本体)"
    rm -rf "$pw"
    rustc --version && cargo --version
}

install_zig() {
    log "zig $ZIG_VERSION (ziglang.org 直下,国内无镜像)"
    # 组首直写配置(不依赖 zig 二进制),增量重跑也刷新(同 install_golang 组首直写);
    # 全局缓存进 /opt:zig fetch 的包缓存默认在 ~/.cache/zig,留在 /root 则 ubuntu 离线不可用
    cat > /etc/profile.d/zig.sh <<EOF
export ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache
EOF
    export ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache
    [ -e /opt/zig/zig ] && ln -sf /opt/zig/zig /usr/local/bin/zig
    if have zig && zig version | grep -q "^${ZIG_VERSION}"; then
        echo "已安装 $(zig version),跳过"; return
    fi
    local arch; case "$(dpkg --print-architecture)" in amd64) arch=x86_64;; arm64) arch=aarch64;; *) exit 1;; esac
    local tgz="zig-${arch}-linux-${ZIG_VERSION}.tar.xz"
    curl -fSL "https://ziglang.org/download/${ZIG_VERSION}/${tgz}" -o "/tmp/${tgz}"
    rm -rf /opt/zig && mkdir -p /opt/zig
    tar -C /opt/zig -xJf "/tmp/${tgz}" --strip-components=1 && rm "/tmp/${tgz}"
    ln -sf /opt/zig/zig /usr/local/bin/zig
    zig version
}


# ---- vcpkg(C/C++ 包管理) ----------------------------------------------
# 本体 GitHub 直下;所装库的下载走各上游(GitHub 居多),
# 量大时配 VCPKG_BINARY_SOURCES(azurl/blob)或 X_VCPKG_ASSET_SOURCES 做缓存
install_vcpkg() {
    log "vcpkg (GitHub 直下,装 /opt/vcpkg)"
    apt-get update -qq
    apt-get install -y --no-install-recommends flex bison   # vcpkg 的 libpcap 等源码构建依赖
    if [ ! -d /opt/vcpkg/.git ]; then
        rm -rf /opt/vcpkg
        clone_pin microsoft/vcpkg /opt/vcpkg || { echo "vcpkg 克隆失败(git 缺?先跑 install-all 前置批)"; return 1; }
    fi
    ( cd /opt/vcpkg && ./bootstrap-vcpkg.sh -disableMetrics ) || { echo "vcpkg bootstrap 失败"; return 1; }
    ln -sf /opt/vcpkg/vcpkg /usr/local/bin/vcpkg
    cat > /etc/profile.d/vcpkg.sh <<'EOF'
export VCPKG_ROOT=/opt/vcpkg
export PATH=$PATH:/opt/vcpkg
EOF
    vcpkg version | head -1
    # 常用库集(RE/安全方向实用集;boost/grpc 这类编译时长过高的不进默认清单)
    local pkgs="${VCPKG_PKGS:-openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara}"
    echo ">> vcpkg install $pkgs (源码编译,耗时较长)"
    vcpkg install $pkgs
}

# ---- nim(OffensiveNim 等 maldev 模板的编译器;choosenim 官方安装器) ----------
# choosenim 归 CHOOSENIM_DIR=/opt/nim;noble apt 的 nim 停 1.6.x 过旧不取
install_nim() {
    log "nim (choosenim 锁定 ${NIM_VERSION:-stable},工具链归 /opt/nim)"
    # 组首直写配置(不依赖 nim 二进制),跳出早退守卫,增量重跑也刷新(同 install_golang 组首直写)
    cat > /etc/profile.d/nim.sh <<'EOF'
export PATH=$PATH:/opt/nim/bin
EOF
    if ! have nim; then
        export CHOOSENIM_DIR=/opt/nim
        local nimv="${NIM_VERSION#v}"; nimv="${nimv:-stable}"   # pins 存 v 前缀;未写锁定版本回退 stable
        curl -fsSL https://nim-lang.org/choosenim/init.sh | sh -s -- -y "$nimv" \
            || echo "choosenim 失败(nim-lang.org 直连抖动,下轮补)"
    fi
    # 最新工具链的 bin 整批链出(幂等,守卫外每跑必重链);nim 经 /proc/self/exe 定位 stdlib,软链安全;
    # 末尾 || true:choosenim 失败/未装时 glob 为空,ls 返回 2,pipefail 下防赋值语句炸(同 install_rust rust-lld 段)
    local tc; tc="$(ls -d /opt/nim/toolchains/nim-* 2>/dev/null | sort -V | tail -1 || true)"
    [ -n "$tc" ] && for b in "$tc"/bin/*; do ln -sf "$b" /usr/local/bin/; done
    nim --version 2>/dev/null | head -1 || echo "nim 未装上(下轮补)"
    true
}

install_cross() {
    log "交叉编译链(REQ-0004 P0:arm64/armhf/mips/mipsel 四套 g++-13 + i386 multilib;不装 crossbuild 元包,grok prt-10)"
    apt-get update -qq
    # 坑(实证):gcc-multilib 与 cross gcc 包互斥(打包声明冲突),i386 面走 libc6-dev-i386 头路线
    apt-get install -y --no-install-recommends \
        g++-13-aarch64-linux-gnu g++-13-arm-linux-gnueabihf \
        g++-13-mipsel-linux-gnu g++-13-mips-linux-gnu \
        || echo "!! 外国架构交叉链部分失败(可重跑)"
    apt-get install -y --no-install-recommends libc6-dev-i386 lib32gcc-13-dev lib32stdc++-13-dev \
        || echo "!! i386 multilib 头失败"
    # 交叉命令名带 -13 代号(noble 实证:无去版本链接)
    for t in aarch64-linux-gnu arm-linux-gnueabihf mipsel-linux-gnu mips-linux-gnu; do
        command -v "${t}-g++-13" >/dev/null && echo "  ${t}-g++-13 ✓"
    done
    echo 'int main(){return 0;}' > /tmp/x.c
    command -v aarch64-linux-gnu-gcc-13 >/dev/null && aarch64-linux-gnu-gcc-13 -static -o /tmp/x-a64 /tmp/x.c && file /tmp/x-a64 | head -1 && rm -f /tmp/x-a64
    gcc -m32 -o /tmp/x-32 /tmp/x.c 2>/dev/null && file /tmp/x-32 | head -1 || echo "  i386 -m32 未通(查 libc6-dev-i386)"
    rm -f /tmp/x.c /tmp/x-32
}

COMPILERS_ALL=(c golang rust zig nim vcpkg cross)
run_category COMPILERS_ALL "$@"

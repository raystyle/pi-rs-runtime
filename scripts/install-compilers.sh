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
    # 黄金三件:调试器 dlv、语言服务器 gopls、静态检查 golangci-lint
    # 注意:go install 产物落在 $(go env GOPATH)/bin(持久化后为 /opt/go/bin),不在 /usr/local/go/bin
    export GOPATH=/opt/go
    local gobin; gobin="/opt/go/bin"
    have dlv          || go install github.com/go-delve/delve/cmd/dlv@latest
    have gopls        || go install golang.org/x/tools/gopls@latest
    have golangci-lint || go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    for b in dlv gopls golangci-lint; do
        [ -e "$gobin/$b" ] && ln -sf "$gobin/$b" "/usr/local/bin/$b"
    done
    # 跳板/代理库预热:进模块缓存,自写隧道工具 go build 不再爬网
    local gpw=/tmp/go-prewarm
    rm -rf "$gpw" && mkdir -p "$gpw"
    cat > "$gpw/go.mod" <<'EOF'
module prewarm

go 1.23
EOF
    cat > "$gpw/main.go" <<'EOF'
package main

import (
    _ "github.com/elazarl/goproxy"
    _ "github.com/xtaci/smux"
    _ "github.com/hashicorp/yamux"
    _ "github.com/quic-go/quic-go"
    _ "golang.org/x/net/proxy"
    _ "github.com/armon/go-socks5"
)

func main() {}
EOF
    ( cd "$gpw" && GOFLAGS=-mod=mod go mod tidy >/dev/null 2>&1 && go build ./... ) \
        && echo "go 跳板库已预热" || echo "!! go 库预热失败(不影响链本体)"
    rm -rf "$gpw"
    cat > /etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\${GOPATH:-/opt/go}
export PATH=\$PATH:\$GOPATH/bin
EOF
    export PATH=$PATH:/usr/local/go/bin
    go version
}

install_rust() {
    log "rust (rustup 与 crates index 均走 tuna;工具链归 /opt 多用户可读)"
    # RUSTUP_HOME/CARGO_HOME 指 /opt:/root 是 0700,ubuntu 执行不了 /root/.cargo 下
    # 的 rustc/cargo;fresh 构建从这起装对位置(评审 F5)
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    if ! have rustc; then
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
# 离线优先默认:运行期 cargo 拉新 crate 立即失败而不是挂起;
# 构建脚本经 common.sh export CARGO_NET_OFFLINE=false 拿回在线面(env 优先于 config)
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
    # pi-rs 件执行链:rust-lld(llvm-tools)+ fmt/clippy + rust-script + cargo-zigbuild
    rustup component add llvm-tools rustfmt clippy rust-analyzer
    # 全平台交叉 target(grok 全平台矩阵):rust-std 必须构建期进 /opt/rustup,离线才链得上
    # 宿主那一档由 stable 默认自带;windows-gnu 链接用 mingw,apple-darwin 纯 Rust 链接用 zig 桩
    local _t
    for _t in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu \
              x86_64-unknown-linux-musl aarch64-unknown-linux-musl \
              armv7-unknown-linux-gnueabihf riscv64gc-unknown-linux-gnu \
              x86_64-pc-windows-gnu i686-pc-windows-gnu \
              x86_64-apple-darwin aarch64-apple-darwin; do
        rustup target add "$_t" 2>/dev/null || echo "target $_t 预加失败(留待排查)"
    done
    rustup target list --installed
    have rust-script      || cargo install rust-script --locked
    have cargo-zigbuild   || cargo install cargo-zigbuild --locked
    have cargo-audit      || cargo install cargo-audit --locked   # 依赖漏洞审计
    for b in cargo-audit; do
        [ -e /opt/cargo/bin/$b ] && ln -sf /opt/cargo/bin/$b "/usr/local/bin/$b"
    done
    # rust-lld 进 PATH(pi-rs 件执行链直接当链接器用)
    # 注意:ls 多操作数有一个不存在即返回 2,pipefail 下会让赋值语句整个失败退出;
    # 末尾 || true 兜底,两个布局(新版 /opt/rustup、旧版 /root/.rustup)都探
    local rlld; rlld="$(ls /opt/rustup/toolchains/*/lib/rustlib/*/bin/rust-lld /root/.rustup/toolchains/*/lib/rustlib/*/bin/rust-lld 2>/dev/null | head -1 || true)"
    [ -n "$rlld" ] && ln -sf "$rlld" /usr/local/bin/rust-lld
    for b in rustc cargo rustup rust-script cargo-zigbuild; do
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
    if have zig && zig version | grep -q "^${ZIG_VERSION}"; then
        echo "已安装 $(zig version),跳过"; return
    fi
    local arch; case "$(dpkg --print-architecture)" in amd64) arch=x86_64;; arm64) arch=aarch64;; *) exit 1;; esac
    local tgz="zig-${arch}-linux-${ZIG_VERSION}.tar.xz"
    curl -fSL "https://ziglang.org/download/${ZIG_VERSION}/${tgz}" -o "/tmp/${tgz}"
    rm -rf /opt/zig && mkdir -p /opt/zig
    tar -C /opt/zig -xJf "/tmp/${tgz}" --strip-components=1 && rm "/tmp/${tgz}"
    ln -sf /opt/zig/zig /usr/local/bin/zig
    # 全局缓存进 /opt:zig fetch 的包缓存默认在 ~/.cache/zig,留在 /root 则 ubuntu 离线不可用
    cat > /etc/profile.d/zig.sh <<EOF
export ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache
EOF
    export ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache
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
        git clone --depth 1 https://github.com/microsoft/vcpkg /opt/vcpkg || { echo "vcpkg 克隆失败(git 缺?先跑 install-all 前置批)"; return 1; }
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
    log "nim (choosenim stable,工具链归 /opt/nim)"
    if ! have nim; then
        export CHOOSENIM_DIR=/opt/nim
        curl -fsSL https://nim-lang.org/choosenim/init.sh | sh -s -- -y \
            || echo "choosenim 失败(nim-lang.org 直连抖动,下轮补)"
        # 最新工具链的 bin 整批链出;nim 经 /proc/self/exe 定位 stdlib,软链安全
        local tc; tc="$(ls -d /opt/nim/toolchains/nim-* 2>/dev/null | sort -V | tail -1)"
        [ -n "$tc" ] && for b in "$tc"/bin/*; do ln -sf "$b" /usr/local/bin/; done
        cat > /etc/profile.d/nim.sh <<'EOF'
export PATH=$PATH:/opt/nim/bin
EOF
    fi
    nim --version 2>/dev/null | head -1 || echo "nim 未装上(下轮补)"
    true
}

COMPILERS_ALL=(c golang rust zig nim vcpkg)
run_category COMPILERS_ALL "$@"

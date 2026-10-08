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
        autoconf automake libtool m4
}

install_golang() {
    log "golang $GOLANG_VERSION (下载 $GO_DOWNLOAD,GOPROXY=$GOPROXY)"
    if have go && [ "$(go env GOVERSION)" = "go$GOLANG_VERSION" ]; then
        echo "已安装 $(go env GOVERSION),跳过"; return
    fi
    local tgz="go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    curl -fSL "${GO_DOWNLOAD}/${tgz}" -o "/tmp/${tgz}"
    rm -rf /usr/local/go && tar -C /usr/local -xzf "/tmp/${tgz}" && rm "/tmp/${tgz}"
    cat > /etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPROXY=${GOPROXY}
export GOSUMDB=${GOSUMDB}
export GOPATH=\${GOPATH:-/root/go}
export PATH=\$PATH:\$GOPATH/bin
EOF
    export PATH=$PATH:/usr/local/go/bin
    go version
}

install_rust() {
    log "rust (rustup 与 crates index 均走 tuna)"
    if ! have rustc; then
        local triple="x86_64-unknown-linux-gnu"
        [ "$(dpkg --print-architecture)" = arm64 ] && triple="aarch64-unknown-linux-gnu"
        curl -fSL "${RUSTUP_UPDATE_ROOT}/dist/${triple}/rustup-init" -o /tmp/rustup-init
        chmod +x /tmp/rustup-init
        /tmp/rustup-init -y --default-toolchain stable --profile minimal
        rm /tmp/rustup-init
    fi
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" <<EOF
[source.crates-io]
replace-with = 'tuna-sparse'

[source.tuna-sparse]
registry = "sparse+${CRATES_INDEX}/"

[net]
git-fetch-with-cli = true
EOF
    . "$HOME/.cargo/env"
    # pi-rs 件执行链:rust-lld(llvm-tools)+ fmt/clippy + rust-script + cargo-zigbuild
    rustup component add llvm-tools rustfmt clippy
    have rust-script      || cargo install rust-script --locked
    have cargo-zigbuild   || cargo install cargo-zigbuild --locked
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
    zig version
}

COMPILERS_ALL=(c golang rust zig)
run_category COMPILERS_ALL "$@"

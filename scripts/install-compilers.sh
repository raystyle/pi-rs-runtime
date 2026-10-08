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
}

install_golang() {
    log "golang $GOLANG_VERSION (下载 $GO_DOWNLOAD,GOPROXY=$GOPROXY)"
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
    # 黄金三件:调试器 dlv、语言服务器 gopls、静态检查 golangci-lint
    export PATH=$PATH:/usr/local/go/bin
    have dlv || go install github.com/go-delve/delve/cmd/dlv@latest
    have gopls || go install golang.org/x/tools/gopls@latest
    ln -sf /usr/local/go/bin/dlv /usr/local/bin/dlv 2>/dev/null || true
    ln -sf /usr/local/go/bin/gopls /usr/local/bin/gopls 2>/dev/null || true
    # go env -w 落到 $HOME/.config/go/env,go 命令自己读,不依赖 profile(incus exec 生效)
    /usr/local/bin/go env -w GOPROXY="${GOPROXY}" GOSUMDB="${GOSUMDB}"
    cat > /etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
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

[registries.tuna]
index = "sparse+${CRATES_INDEX}/"

[net]
git-fetch-with-cli = true
EOF
    # rustup 更新通道持久化(tuna 帮助口径),否则 rustup update 回官方源
    cat > /etc/profile.d/rustup.sh <<EOF
export RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER}
export RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT}
EOF
    . "$HOME/.cargo/env"
    # pi-rs 件执行链:rust-lld(llvm-tools)+ fmt/clippy + rust-script + cargo-zigbuild
    rustup component add llvm-tools rustfmt clippy rust-analyzer
    have rust-script      || cargo install rust-script --locked
    have cargo-zigbuild   || cargo install cargo-zigbuild --locked
    have cargo-audit      || cargo install cargo-audit --locked   # 依赖漏洞审计
    for b in cargo-audit; do
        [ -e "$HOME/.cargo/bin/$b" ] && ln -sf "$HOME/.cargo/bin/$b" "/usr/local/bin/$b"
    done
    for b in rustc cargo rustup rust-script cargo-zigbuild; do
        [ -e "$HOME/.cargo/bin/$b" ] && ln -sf "$HOME/.cargo/bin/$b" "/usr/local/bin/$b"
    done
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

#!/usr/bin/env bash
# pi-rs-runtime 运行时安装器
# 在 Ubuntu 24.04 容器(或宿主)内运行,幂等,可重复执行。
# 用法:
#   ./install-runtimes.sh              # 安装全部
#   ./install-runtimes.sh rust node    # 只装指定运行时(可多个)
#   VERSIONS 通过环境变量覆盖,如 GOLANG_VERSION=1.23.4
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# ---- 镜像源(可覆盖)-------------------------------------------------
export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://rsproxy.cn}"
export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}"
GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"
PIP_INDEX="${PIP_INDEX:-https://pypi.tuna.tsinghua.edu.cn/simple}"
NODE_MIRROR="${NODE_MIRROR:-https://registry.npmmirror.com/-/binary/node}"
ADOPTIUM_MIRROR="${ADOPTIUM_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/Adoptium}"

# ---- 版本钉 -------------------------------------------------------
GOLANG_VERSION="${GOLANG_VERSION:-1.23.4}"
NODE_VERSION="${NODE_VERSION:-22.12.0}"
DOTNET_SDK="${DOTNET_SDK:-dotnet-sdk-8.0}"
JAVA_VERSION="${JAVA_VERSION:-21.0.5+11}"   # temurin,注册进 sdkman 的本地版本名后缀
ZIG_VERSION="${ZIG_VERSION:-0.13.0}"

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---- C 工具链 ------------------------------------------------------
install_c() {
    log "C 工具链 (apt: build-essential clang cmake ninja …)"
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        build-essential clang lldb gdb cmake ninja-build pkg-config \
        autoconf automake libtool m4
}

# ---- golang --------------------------------------------------------
install_golang() {
    log "golang $GOLANG_VERSION (下载镜像 golang.google.cn,GOPROXY=$GOPROXY)"
    if have go && [ "$(go env GOVERSION)" = "go$GOLANG_VERSION" ]; then
        echo "已安装 $(go env GOVERSION),跳过"; return
    fi
    local tgz="go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    curl -fSL "https://golang.google.cn/dl/${tgz}" -o "/tmp/${tgz}"
    rm -rf /usr/local/go && tar -C /usr/local -xzf "/tmp/${tgz}" && rm "/tmp/${tgz}"
    cat > /etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPROXY=${GOPROXY}
export GOPATH=\${GOPATH:-/root/go}
export PATH=\$PATH:\$GOPATH/bin
EOF
    export PATH=$PATH:/usr/local/go/bin
    go version
}

# ---- rust ----------------------------------------------------------
install_rust() {
    log "rust (rustup 走 rsproxy,crates 走 rsproxy sparse)"
    if have rustc; then rustc --version; echo "已安装,跳过"; return; fi
    curl -fSL https://rsproxy.cn/rustup-init.sh -o /tmp/rustup-init.sh
    sh /tmp/rustup-init.sh -y --default-toolchain stable --profile minimal
    rm /tmp/rustup-init.sh
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" <<'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "sparse+https://rsproxy.cn/index/"

[net]
git-fetch-with-cli = true
EOF
    . "$HOME/.cargo/env" && rustc --version && cargo --version
}

# ---- node ----------------------------------------------------------
install_node() {
    log "node $NODE_VERSION (npmmirror 二进制镜像,npm registry=$NPM_REGISTRY)"
    if have node && [ "$(node -v)" = "v${NODE_VERSION}" ]; then
        echo "已安装 $(node -v),跳过"; return
    fi
    local arch ver_dir="node-v${NODE_VERSION}-linux-x64"
    case "$(dpkg --print-architecture)" in amd64) arch=x64;; arm64) arch=arm64;; *) echo "不支持的架构"; exit 1;; esac
    local tgz="node-v${NODE_VERSION}-linux-${arch}.tar.xz"
    curl -fSL "${NODE_MIRROR}/v${NODE_VERSION}/${tgz}" -o "/tmp/${tgz}"
    rm -rf "/opt/node" && mkdir -p /opt/node
    tar -C /opt/node -xJf "/tmp/${tgz}" --strip-components=1 && rm "/tmp/${tgz}"
    ln -sf /opt/node/bin/node /usr/local/bin/node
    ln -sf /opt/node/bin/npm /usr/local/bin/npm
    ln -sf /opt/node/bin/npx /usr/local/bin/npx
    npm config set registry "$NPM_REGISTRY"
    node -v && npm -v
}

# ---- bun -----------------------------------------------------------
install_bun() {
    log "bun (经 npmmirror registry 的 npm 全局安装)"
    if have bun; then bun --version; echo "已安装,跳过"; return; fi
    npm install -g bun
    ln -sf /opt/node/lib/node_modules/bun/bin/bun /usr/local/bin/bun 2>/dev/null || true
    bun --version
}

# ---- python --------------------------------------------------------
install_python() {
    log "python3 + pip (索引 $PIP_INDEX)"
    apt-get update -qq
    apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
    pip3 config set global.index-url "$PIP_INDEX"
    python3 --version && pip3 --version
}

# ---- dotnet --------------------------------------------------------
install_dotnet() {
    log "dotnet ($DOTNET_SDK,packages.microsoft.com,国内无镜像)"
    if dpkg -l "$DOTNET_SDK" >/dev/null 2>&1; then
        echo "已安装,跳过"; return
    fi
    local uver; uver="$(. /etc/os-release && echo "$VERSION_ID")"
    curl -fSL "https://packages.microsoft.com/config/ubuntu/${uver}/packages-microsoft-prod.deb" -o /tmp/ms-prod.deb
    dpkg -i /tmp/ms-prod.deb && rm /tmp/ms-prod.deb
    apt-get update -qq
    apt-get install -y "$DOTNET_SDK"
    dotnet --version
}

# ---- pwsh ----------------------------------------------------------
install_pwsh() {
    log "pwsh (packages.microsoft.com,国内无镜像)"
    if have pwsh; then pwsh --version; echo "已安装,跳过"; return; fi
    install_dotnet_repo   # 复用 MS apt 源
    apt-get install -y powershell
    pwsh --version
}

install_dotnet_repo() {
    if [ -f /etc/apt/sources.list.d/microsoft-prod.list ] || [ -f /etc/apt/sources.list.d/microsoft-prod.sources ]; then
        return
    fi
    local uver; uver="$(. /etc/os-release && echo "$VERSION_ID")"
    curl -fSL "https://packages.microsoft.com/config/ubuntu/${uver}/packages-microsoft-prod.deb" -o /tmp/ms-prod.deb
    dpkg -i /tmp/ms-prod.deb && rm /tmp/ms-prod.deb
    apt-get update -qq
}

# ---- zig -----------------------------------------------------------
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

# ---- sdkman + JDK ---------------------------------------------------
install_sdkman() {
    log "sdkman (JVM 生态: java/maven/gradle/kotlin/scala 的入口)"
    local sdk_dir="/usr/local/sdkman"
    if [ ! -d "$sdk_dir" ]; then
        curl -fSL "https://get.sdkman.io" -o /tmp/sdkman-init.sh
        SDKMAN_DIR="$sdk_dir" bash /tmp/sdkman-init.sh
        rm /tmp/sdkman-init.sh
        sed -i 's|^sdkman_auto_env=.*|sdkman_auto_env=true|' "$sdk_dir/etc/config"
    fi
    cat > /etc/profile.d/sdkman.sh <<EOF
export SDKMAN_DIR="$sdk_dir"
[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "\$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
    export SDKMAN_DIR="$sdk_dir"
    # shellcheck disable=SC1091
    . "$sdk_dir/bin/sdkman-init.sh"

    log "temurin JDK ${JAVA_VERSION%%+*} (tuna Adoptium 镜像,本地路径注册进 sdkman)"
    local jdk_dir="/opt/jdk/temurin-${JAVA_VERSION%%+*}"
    if [ ! -d "$jdk_dir" ]; then
        mkdir -p "$jdk_dir"
        local major; major="$(echo "$JAVA_VERSION" | cut -d. -f1)"
        local tgz="OpenJDK${major}U-jdk_x64_linux_hotspot_${JAVA_VERSION//+/_}.tar.gz"
        curl -fSL "${ADOPTIUM_MIRROR}/${major}/jdk/x64/linux/${tgz}" -o /tmp/jdk.tar.gz
        tar -C "$jdk_dir" -xzf /tmp/jdk.tar.gz --strip-components=1 && rm /tmp/jdk.tar.gz
    fi
    if ! sdk list java | grep -q "local only"; then
        yes | sdk install java "${JAVA_VERSION%%+*}-tem" "$jdk_dir" || true
    fi

    log "maven / gradle (sdkman)"
    sdk install maven  || true
    sdk install gradle || true
    sdk current
}

# ---- 入口 -----------------------------------------------------------
ALL=(c golang rust node bun python dotnet pwsh zig sdkman)

main() {
    local targets=("$@")
    [ ${#targets[@]} -eq 0 ] && targets=("${ALL[@]}")
    for t in "${targets[@]}"; do
        case " ${ALL[*]} " in
            *" $t "*) "install_$t" ;;
            *) echo "未知运行时: $t(可选: ${ALL[*]})"; exit 1 ;;
        esac
    done
    log "全部完成"
}

main "$@"

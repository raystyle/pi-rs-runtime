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
# 原则:有 tuna 走 tuna;tuna 没有的走该生态自己的国内镜像
TUNA="${TUNA:-https://mirrors.tuna.tsinghua.edu.cn}"
export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-$TUNA/rustup}"
export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-$TUNA/rustup/rustup}"
CRATES_INDEX="${CRATES_INDEX:-$TUNA/crates.io-index}"
GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"          # tuna 无 golang 模块代理,用七牛 goproxy
GOSUMDB="${GOSUMDB:-sum.golang.google.cn}"              # 国内可连的校验和库
GO_DOWNLOAD="${GO_DOWNLOAD:-https://mirror.nju.edu.cn/golang}" # tuna 无 golang;南大镜像同为高校源,也可用 golang.google.cn
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"            # tuna 无 npm registry
NODE_MIRROR="${NODE_MIRROR:-https://registry.npmmirror.com/-/binary/node}" # tuna 无 node 二进制
PIP_INDEX="${PIP_INDEX:-$TUNA/pypi/simple}"
ADOPTIUM_MIRROR="${ADOPTIUM_MIRROR:-$TUNA/Adoptium}"
MAVEN_MIRROR="${MAVEN_MIRROR:-$TUNA/apache/maven}"

# ---- 版本钉 -------------------------------------------------------
GOLANG_VERSION="${GOLANG_VERSION:-1.23.4}"
NODE_VERSION="${NODE_VERSION:-22.12.0}"
DOTNET_SDK="${DOTNET_SDK:-dotnet-sdk-8.0}"
ZIG_VERSION="${ZIG_VERSION:-0.13.0}"
MAVEN_VERSION="${MAVEN_VERSION:-3.9.16}"
JAVA_VERSIONS="${JAVA_VERSIONS:-8 11 17 21 25}"  # sdkman 预装的开源 JDK 主版本(temurin,tuna Adoptium;25 为新 LTS)

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

# ---- rust ----------------------------------------------------------
install_rust() {
    log "rust (rustup 与 crates index 均走 tuna)"
    if have rustc; then rustc --version; echo "已安装,跳过"; return; fi
    local triple="x86_64-unknown-linux-gnu"
    [ "$(dpkg --print-architecture)" = arm64 ] && triple="aarch64-unknown-linux-gnu"
    curl -fSL "${RUSTUP_UPDATE_ROOT}/dist/${triple}/rustup-init" -o /tmp/rustup-init
    chmod +x /tmp/rustup-init
    /tmp/rustup-init -y --default-toolchain stable --profile minimal
    rm /tmp/rustup-init
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" <<EOF
[source.crates-io]
replace-with = 'tuna-sparse'

[source.tuna-sparse]
registry = "sparse+${CRATES_INDEX}/"

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

# ---- uv (python 包/运行时管理器) --------------------------------------
install_uv() {
    log "uv (经 tuna pypi 的 pip 安装;库索引 UV_INDEX_URL=$PIP_INDEX)"
    if have uv; then uv --version; echo "已安装,跳过"; return; fi
    pip3 install -U uv
    cat > /etc/profile.d/uv.sh <<EOF
export UV_INDEX_URL=${PIP_INDEX}
EOF
    export UV_INDEX_URL="$PIP_INDEX"
    uv --version
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

# ---- sdkman + 多版本 JDK ---------------------------------------------
# sdkman 的定位:各种开源 JDK 的统一切换入口(temurin 从 tuna Adoptium 预装)
install_sdkman() {
    log "sdkman (多版本 java 管理入口,temurin 走 tuna Adoptium)"
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

    # 从 tuna Adoptium 拉各主版本的最新 temurin,本地路径注册进 sdkman
    local aarchi; case "$(dpkg --print-architecture)" in amd64) aarchi=x64;; arm64) aarchi=aarch64;; *) exit 1;; esac
    local default_ver=""
    for major in $JAVA_VERSIONS; do
        local listing tgz ver jdk_dir
        listing="$(curl -fsSL "${ADOPTIUM_MIRROR}/${major}/jdk/${aarchi}/linux/")"
        tgz="$(printf '%s' "$listing" | grep -o "OpenJDK${major}U-jdk_${aarchi}_linux_hotspot_[0-9a-zA-Z._]*\.tar\.gz" | sort -uV | tail -1)"
        [ -n "$tgz" ] || { echo "tuna Adoptium 找不到 JDK $major,跳过"; continue; }
        ver="${tgz#OpenJDK${major}U-jdk_${aarchi}_linux_hotspot_}"; ver="${ver%.tar.gz}"
        jdk_dir="/opt/jdk/temurin-${ver}"
        if [ ! -d "$jdk_dir" ]; then
            mkdir -p "$jdk_dir"
            curl -fSL "${ADOPTIUM_MIRROR}/${major}/jdk/${aarchi}/linux/${tgz}" -o /tmp/jdk.tar.gz
            tar -C "$jdk_dir" -xzf /tmp/jdk.tar.gz --strip-components=1 && rm /tmp/jdk.tar.gz
        fi
        if ! sdk list java 2>/dev/null | grep -q "${ver}-tem"; then
            yes | sdk install java "${ver}-tem" "$jdk_dir" || true
        fi
        default_ver="${ver}-tem"
        echo "java $major -> ${ver}-tem"
    done
    [ -n "$default_ver" ] && sdk default java "$default_ver" || true

    log "maven $MAVEN_VERSION (tuna apache 镜像,直装)"
    if ! have mvn; then
        local mtgz="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        curl -fSL "${MAVEN_MIRROR}/maven-3/${MAVEN_VERSION}/binaries/${mtgz}" -o "/tmp/${mtgz}"
        rm -rf /opt/maven && mkdir -p /opt/maven
        tar -C /opt/maven -xzf "/tmp/${mtgz}" --strip-components=1 && rm "/tmp/${mtgz}"
        ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn
    fi
    mvn -version | head -1

    log "gradle (sdkman)"
    sdk install gradle || true
    sdk current
}

# ---- 入口 -----------------------------------------------------------
ALL=(c golang rust node bun python uv dotnet pwsh zig sdkman)

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

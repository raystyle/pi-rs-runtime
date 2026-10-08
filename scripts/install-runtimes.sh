#!/usr/bin/env bash
# 运行时安装器:node(fnm 多版本)/bun/python3/python2/uv/dotnet/pwsh/java(sdkman 多版本)
# 在 Ubuntu 24.04 容器(或宿主)内运行,幂等,可重复执行。
# 用法:
#   ./install-runtimes.sh            # 装全部
#   ./install-runtimes.sh python node  # 只装指定项(可多个)
# 镜像源与版本经环境变量覆盖,见 lib/common.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

install_node() {
    log "node $NODE_VERSION (npmmirror 二进制镜像,npm registry=$NPM_REGISTRY)"
    if ! have node || [ "$(node -v)" != "v${NODE_VERSION}" ]; then
        local arch ver_dir="node-v${NODE_VERSION}-linux-x64"
        case "$(dpkg --print-architecture)" in amd64) arch=x64;; arm64) arch=arm64;; *) echo "不支持的架构"; exit 1;; esac
        local tgz="node-v${NODE_VERSION}-linux-${arch}.tar.xz"
        curl -fSL "${NODE_MIRROR}/v${NODE_VERSION}/${tgz}" -o "/tmp/${tgz}"
        # 校验和(npmmirror 镜像带 SHASUMS256.txt)
        curl -fsSL "${NODE_MIRROR}/v${NODE_VERSION}/SHASUMS256.txt" -o /tmp/SHASUMS256.txt
        grep " ${tgz}$" /tmp/SHASUMS256.txt | sha256sum -c - || { echo "node tarball 校验失败"; exit 1; }
        rm -f /tmp/SHASUMS256.txt
        rm -rf "/opt/node" && mkdir -p /opt/node
        tar -C /opt/node -xJf "/tmp/${tgz}" --strip-components=1 && rm "/tmp/${tgz}"
        ln -sf /opt/node/bin/node /usr/local/bin/node
        ln -sf /opt/node/bin/npm /usr/local/bin/npm
        ln -sf /opt/node/bin/npx /usr/local/bin/npx
    fi
    # 写 prefix 级全局 npmrc:对所有用户生效(默认只写 root ~/.npmrc)
    npm config set --location=global registry "$NPM_REGISTRY"
    # disturl/electron_mirror 不是 npm 11 的合法 option,config set 会拒;
    # 直写 npmrc 文件——npm 会把任意键以 npm_config_* 形式传给生命周期脚本(node-gyp/electron 正是这么读的)
    install -d /opt/node/etc
    cat >> /opt/node/etc/npmrc <<EOF
disturl=https://npmmirror.com/mirrors/node
electron_mirror=https://npmmirror.com/mirrors/electron/
EOF
    npm install -g typescript          # tsc:pi-rs 基座要求
    ln -sf /opt/node/bin/tsc /usr/local/bin/tsc
    ln -sf /opt/node/bin/tsserver /usr/local/bin/tsserver
    node -v && npm -v && tsc --version
}

install_fnm() {
    log "fnm + node $FNM_NODE_VERSIONS (fnm 经 cargo 装,node 二进制走 npmmirror 镜像)"
    . "$HOME/.cargo/env" 2>/dev/null || true
    if ! have fnm; then
        cargo install fnm --locked
    fi
    fnm --version
    for v in $FNM_NODE_VERSIONS; do
        fnm install --node-dist-mirror "$NODE_MIRROR" "$v"
    done
    # 最高版本设为默认,并把它的 node/npm/npx 固定到 /usr/local/bin
    local latest; latest="$(fnm ls | grep -o 'v[0-9.]*' | sort -uV | tail -1 | tr -d v)"
    fnm default "$latest"
    local fdir; fdir="$(fnm exec --using="$latest" which node | xargs dirname)"
    ln -sf "$fdir/node" /usr/local/bin/node
    ln -sf "$fdir/npm"  /usr/local/bin/npm
    ln -sf "$fdir/npx"  /usr/local/bin/npx
    cat > /etc/profile.d/fnm.sh <<'EOF'
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env 2>/dev/null)" || true
EOF
    fnm ls
}

install_bun() {
    log "bun (经 npmmirror registry 的 npm 全局安装)"
    if have bun; then bun --version; echo "已安装,跳过"; return; fi
    npm install -g bun
    # npm 的 shim 在 /opt/node/bin(非交互 shell 不在 PATH),固定链接到 /usr/local/bin
    ln -sf /opt/node/bin/bun /usr/local/bin/bun
    ln -sf /opt/node/bin/bunx /usr/local/bin/bunx
    # bun 不读 npmrc,要 bunfig;官方推荐写法(root 与 ubuntu 各一份)
    for u in /root /home/ubuntu; do
        [ -d "$u" ] && printf '[install]\nregistry = "%s"\n' "$NPM_REGISTRY" > "$u/.bunfig.toml"
    done
    bun --version
}

install_python() {
    log "python3 + pip (索引 $PIP_INDEX)"
    apt-get update -qq
    apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
    # 系统级 pip 配置(root 与 ubuntu 用户都读;不要加 extra-index-url,防依赖混淆)
    printf '[global]\nindex-url = %s\n' "$PIP_INDEX" > /etc/pip.conf
    python3 --version && pip3 --version
}

install_python2() {
    log "python $PY2_VERSION (源码编译,$PY2_MIRROR)"
    if have python2.7 && python2.7 --version >/dev/null 2>&1; then python2.7 --version; echo "已安装,跳过"; return; fi
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libncursesw5-dev xz-utils libffi-dev
    curl -fSL "${PY2_MIRROR}/${PY2_VERSION}/Python-${PY2_VERSION}.tgz" -o /tmp/py2.tgz
    rm -rf /tmp/py2build && mkdir -p /tmp/py2build
    tar -C /tmp/py2build -xzf /tmp/py2.tgz --strip-components=1 && rm /tmp/py2.tgz
    ( cd /tmp/py2build && ./configure --prefix=/usr/local --enable-shared \
        && make -j"$(nproc)" && make altinstall && ldconfig )
    rm -rf /tmp/py2build
    ln -sf /usr/local/bin/python2.7 /usr/local/bin/python2
    python2.7 --version
}

install_uv() {
    log "uv (经 tuna pypi 的 pip 安装;库索引 UV_INDEX_URL=$PIP_INDEX)"
    if have uv; then uv --version; echo "已安装,跳过"; return; fi
    # noble 的系统 python 标记 externally-managed(PEP 668),容器内允许直装
    pip3 install -U --break-system-packages uv
    # uv 0.4.23 起 UV_INDEX_URL 废弃;系统配置写 /etc/uv/uv.toml(tuna 帮助口径)
    install -d /etc/uv
    printf '[[index]]\nurl = "%s"\ndefault = true\n' "$PIP_INDEX" > /etc/uv/uv.toml
    export UV_DEFAULT_INDEX="$PIP_INDEX"
    uv --version
}

install_dotnet() {
    log "dotnet ($DOTNET_SDK,noble 自带源=tuna;MS 仓 24.04 起不提供 .NET)"
    apt-get update -qq
    apt-get install -y "$DOTNET_SDK" || true
    # NuGet 库镜像:华为 v3(已实证 200;不要用 azure.cn 旧 CDN,已解析失败)
    for u in /root /home/ubuntu; do
        [ -d "$u" ] && install -d "$u/.nuget/NuGet" && cat > "$u/.nuget/NuGet/NuGet.Config" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="huaweicloud" value="${NUGET_MIRROR}" />
  </packageSources>
</configuration>
EOF
    done
    dotnet --version
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

install_pwsh() {
    log "pwsh (packages.microsoft.com,国内无镜像)"
    if have pwsh; then pwsh --version; echo "已安装,跳过"; return; fi
    install_dotnet_repo   # MS apt 源只为 pwsh 注册(dotnet 走 Ubuntu 源)
    apt-get install -y powershell-lts || apt-get install -y powershell
    pwsh --version
}

install_sdkman() {
    log "sdkman (多版本 java 管理入口,temurin 走 tuna Adoptium)"
    apt-get update -qq
    apt-get install -y --no-install-recommends unzip zip   # sdkman 安装器与候选包解包依赖
    local sdk_dir="/usr/local/sdkman"
    if [ ! -d "$sdk_dir" ]; then
        curl -fSL "https://get.sdkman.io" -o /tmp/sdkman-init.sh
        SDKMAN_DIR="$sdk_dir" bash /tmp/sdkman-init.sh
        rm /tmp/sdkman-init.sh
        sed -i -e 's|^sdkman_auto_env=.*|sdkman_auto_env=true|' \
               -e 's|^sdkman_auto_selfupdate=.*|sdkman_auto_selfupdate=false|' \
               -e 's|^sdkman_auto_answer=.*|sdkman_auto_answer=true|' "$sdk_dir/etc/config"
    fi
    cat > /etc/profile.d/sdkman.sh <<EOF
export SDKMAN_DIR="$sdk_dir"
[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "\$SDKMAN_DIR/bin/sdkman-init.sh"
[ -n "\${JAVA_HOME:-}" ] || export JAVA_HOME="\$SDKMAN_DIR/candidates/java/current"
EOF
    export SDKMAN_DIR="$sdk_dir"
    set +u   # sdkman-init.sh 里有未绑定变量引用,与 set -u 冲突
    # shellcheck disable=SC1091
    . "$sdk_dir/bin/sdkman-init.sh"
    set -u

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
    if [ -n "$default_ver" ]; then
        sdk default java "$default_ver" || true
        # java 进默认 PATH(非登录 shell 也能用)
        ln -sf "$sdk_dir/candidates/java/current/bin/java" /usr/local/bin/java
        ln -sf "$sdk_dir/candidates/java/current/bin/javac" /usr/local/bin/javac
    fi

    log "maven $MAVEN_VERSION (tuna apache 镜像,直装;依赖走阿里云)"
    if ! have mvn; then
        local mtgz="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        curl -fSL "${MAVEN_MIRROR}/maven-3/${MAVEN_VERSION}/binaries/${mtgz}" -o "/tmp/${mtgz}"
        rm -rf /opt/maven && mkdir -p /opt/maven
        tar -C /opt/maven -xzf "/tmp/${mtgz}" --strip-components=1 && rm "/tmp/${mtgz}"
        ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn
    fi
    # 依赖镜像写安装目录的 settings.xml:对所有调用生效(tuna 只镜像发行包,不镜像 Central)
    cat > /opt/maven/conf/settings.xml <<EOF
<settings>
  <mirrors>
    <mirror>
      <id>aliyunmaven</id>
      <mirrorOf>central</mirrorOf>
      <name>阿里云公共仓库</name>
      <url>${MAVEN_DEP_MIRROR}</url>
    </mirror>
  </mirrors>
</settings>
EOF
    # 非交互 shell 没有 JAVA_HOME,从 sdkman current 推
    export JAVA_HOME="${JAVA_HOME:-$sdk_dir/candidates/java/current}"
    mvn -version | head -1

    log "gradle $GRADLE_VERSION (阿里云 distributions 直装;依赖经 init.d 指阿里云)"
    if ! have gradle; then
        local gver="$GRADLE_VERSION"
        local gzip="gradle-${gver}-bin.zip"
        curl -fSL "https://mirrors.aliyun.com/gradle/distributions/v${gver}/${gzip}" -o "/tmp/${gzip}"
        rm -rf /opt/gradle && mkdir -p /opt/gradle
        unzip -q "/tmp/${gzip}" -d /opt/gradle && rm "/tmp/${gzip}"
        local gdir; gdir="$(ls -d /opt/gradle/gradle-*/ | head -1)"
        ln -sf "${gdir}bin/gradle" /usr/local/bin/gradle
    fi
    # init script:同时盖插件解析与项目依赖(只改 allprojects 盖不住 settings 的 pluginManagement)
    for u in /root /home/ubuntu; do
        [ -d "$u" ] && install -d "$u/.gradle/init.d" && cat > "$u/.gradle/init.d/mirrors.gradle" <<'EOF'
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
    }
}
settingsEvaluated { settings ->
    settings.pluginManagement {
        repositories {
            maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
            gradlePluginPortal()
        }
    }
}
EOF
    done
    gradle --version 2>/dev/null | grep -m1 Gradle
    set +u; sdk current; set -u   # sdk 主脚本引用未绑定位置参数,与 set -u 冲突
}

RUNTIMES_ALL=(node fnm bun python python2 uv php dotnet pwsh sdkman)
run_category RUNTIMES_ALL "$@"

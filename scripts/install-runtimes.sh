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
        # 校验行用绝对路径:sha256sum -c 按 CWD 解析裸文件名,裸写会装失败
        grep " ${tgz}$" /tmp/SHASUMS256.txt | awk -v f="/tmp/${tgz}" '{print $1"  "f}' | sha256sum -c - \
            || { echo "node tarball 校验失败"; exit 1; }
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
    # 幂等:先清旧键再写,避免重跑追加
    sed -i -e '/^disturl=/d' -e '/^electron_mirror=/d' -e '/^offline=/d' -e '/^fetch-retries=/d' -e '/^fetch-retry-mintimeout=/d' -e '/^fetch-retry-maxtimeout=/d' /opt/node/etc/npmrc 2>/dev/null || true
    cat >> /opt/node/etc/npmrc <<EOF
disturl=https://npmmirror.com/mirrors/node
electron_mirror=https://npmmirror.com/mirrors/electron/
# 离线快失败双保险:offline=true 走 cache-only,未命中即 ENOTCACHED 亚秒退;
# fetch-retries=0 兜住绕过 cache 的解析路径(实证默认重试挂 70s+)。
# 注意 npmrc 是 prefix 级:npm --prefix 会连配置一起丢(早期误判正源于此),项目内用法才吃到。
# 构建脚本经 common.sh 的 NPM_CONFIG_OFFLINE=false + NPM_CONFIG_FETCH_* env 拿回在线面
offline=true
fetch-retries=0
fetch-retry-mintimeout=500
fetch-retry-maxtimeout=1000
EOF
    # fnm 各版本同形(prefix 级 npmrc)
    local fnmv
    for fnmv in /root/.local/share/fnm/node-versions/*/installation; do
        [ -d "$fnmv" ] || continue
        install -d "$fnmv/etc"
        sed -i -e '/^offline=/d' -e '/^fetch-retries=/d' -e '/^fetch-retry-mintimeout=/d' -e '/^fetch-retry-maxtimeout=/d' "$fnmv/etc/npmrc" 2>/dev/null || true
        printf 'offline=true\nfetch-retries=0\nfetch-retry-mintimeout=500\nfetch-retry-maxtimeout=1000\n' >> "$fnmv/etc/npmrc"
    done
    npm install -g typescript          # tsc:pi-rs 基座要求
    ln -sf /opt/node/bin/tsc /usr/local/bin/tsc
    ln -sf /opt/node/bin/tsserver /usr/local/bin/tsserver
    # 黄金:corepack 启用 pnpm/yarn;prettier/eslint 全局
    export COREPACK_NPM_REGISTRY="$NPM_REGISTRY"   # pnpm/yarn 首次下载走 npmmirror
    corepack enable 2>/dev/null || true
    npm install -g prettier eslint
    ln -sf /opt/node/bin/prettier /usr/local/bin/prettier 2>/dev/null || true
    ln -sf /opt/node/bin/eslint /usr/local/bin/eslint 2>/dev/null || true
    # dotnetjs:.NET Framework BCL 的 JS 实现(pseudocc),分析/复现 .NET 行为用
    npm install -g dotnetjs || echo "dotnetjs 失败(npmmirror)"
    node -v && npm -v && tsc --version
}

install_fnm() {
    log "fnm + node $FNM_NODE_VERSIONS (fnm 经 cargo 装,node 二进制走 npmmirror 镜像)"
    # fresh 布局:cargo/rustup 在 /opt;不导出 RUSTUP_HOME 则 shim 找 /root/.rustup 报 no default
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    . /opt/cargo/env 2>/dev/null || true
    export PATH="$PATH:/opt/cargo/bin"
    if ! have fnm; then
        cargo install fnm --locked
    fi
    fnm --version
    for v in $FNM_NODE_VERSIONS; do
        fnm install --node-dist-mirror "$NODE_MIRROR" "$v"
    done
    # 只设 fnm 默认版本,不改 /usr/local/bin:系统 node 仍是 /opt/node(24.21.0 钉),
    # 全局 npmrc/bun/tsc 都依赖那个 prefix。项目要切版本:fnm use / fnm exec。
    local latest; latest="$(fnm ls | grep -o 'v[0-9.]*' | sort -uV | tail -1 | tr -d v)"
    fnm default "$latest" || true
    cat > /etc/profile.d/fnm.sh <<'EOF'
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env 2>/dev/null)" || true
EOF
    # fnm 各版本 prefix 级 npmrc 离线面:node 组的循环在首轮 install-all 里目录尚不存在
    # (RUNTIMES_ALL 是 node 先于 fnm,grok G),装完版本后这里兜底再写一遍
    local v
    for v in /root/.local/share/fnm/node-versions/*/installation /home/ubuntu/.local/share/fnm/node-versions/*/installation; do
        [ -d "$v" ] || continue
        install -d "$v/etc"
        sed -i -e '/^offline=/d' -e '/^fetch-retries=/d' -e '/^fetch-retry-mintimeout=/d' -e '/^fetch-retry-maxtimeout=/d' "$v/etc/npmrc" 2>/dev/null || true
        printf 'offline=true\nfetch-retries=0\nfetch-retry-mintimeout=500\nfetch-retry-maxtimeout=1000\n' >> "$v/etc/npmrc"
    done
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
    log "python3 基座(apt) + uv venv 隔离(用户裁定:不碰系统 python3 的 site-packages)"
    apt-get update -qq
    apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
    # 系统级 pip 配置(apt 装的 python3-* 包和 venv 共用索引;不加 extra-index-url 防依赖混淆)
    # [install] no-index+find-links:运行期 pip install 默认只走 /opt/wheelhouse 快失败
    # (烘焙轮子内的包离线直接可装);构建脚本经 common.sh export PIP_NO_INDEX=false 覆盖;
    # pip download 不受 [install] 节影响(wheelhouse 构建不受影响)
    printf '[global]\nindex-url = %s\n\n[install]\nno-index = true\nfind-links = /opt/wheelhouse\n' "$PIP_INDEX" > /etc/pip.conf
    # 分析 venv:polars/pyarrow/chdb 等全进这里,系统 python 保持干净
    [ -d "$VENV_ANALYTICS" ] || uv venv "$VENV_ANALYTICS"
    VIRTUAL_ENV="$VENV_ANALYTICS" uv pip install polars pyarrow chdb
    # ruff 用 uv tool 隔离安装;UV_TOOL_* 指 /opt 使 ubuntu 可执行(评审 F5)
    export UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools
    have ruff || uv tool install ruff
    # pwntools 只走 apt(p0 批的 python3-pwntools):pip 版会盖住 dist-packages 造成双版本,评审 F8
    python3 --version && uv --version && ruff --version
}

# ---- duckdb(本地分析引擎;python 进分析 venv,CLI 走 GitHub release) ----------
install_duckdb() {
    log "duckdb (python 进 $VENV_ANALYTICS;CLI 走 GitHub release)"
    [ -d "$VENV_ANALYTICS" ] || uv venv "$VENV_ANALYTICS"
    VIRTUAL_ENV="$VENV_ANALYTICS" uv pip install -U duckdb
    if ! have duckdb; then
        local dt darch="amd64"; [ "$(dpkg --print-architecture)" = arm64 ] && darch="aarch64"
        dt="$(curl -fsSL "https://api.github.com/repos/duckdb/duckdb/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
        # api.github.com 限流 403 时整条链失败会 set -e 退出,|| true 兜底下轮补
        [ -n "$dt" ] && curl -fSL "https://github.com/duckdb/duckdb/releases/download/${dt}/duckdb_cli-linux-${darch}.zip" -o /tmp/duckdb.zip \
            && unzip -q -o /tmp/duckdb.zip -d /tmp && install -m755 /tmp/duckdb /usr/local/bin/duckdb && rm -f /tmp/duckdb.zip /tmp/duckdb || true
    fi
    duckdb --version 2>/dev/null || "$VENV_ANALYTICS/bin/python" -c "import duckdb; print('duckdb py', duckdb.__version__)"
}

install_clickhouse() {
    log "clickhouse 单二进制(官方 curl 脚本;用法 clickhouse local,无 clickhouse-local 软链)"
    # 官方规定:curl https://clickhouse.com/ | sh 只产一个 clickhouse 二进制,
    # 裸跑即交互式 clickhouse-local;CLICKHOUSE_ONLY=1 不附带 clickhousectl
    if ! have clickhouse; then
        rm -f /tmp/clickhouse
        (cd /tmp && curl -fsSL https://clickhouse.com/ | CLICKHOUSE_ONLY=1 sh) \
            && install -m755 /tmp/clickhouse /usr/local/bin/clickhouse && rm -f /tmp/clickhouse \
            || echo "clickhouse 下载失败(clickhouse.com 直连抖动,下轮补)"
    fi
    clickhouse local -q "SELECT version()" 2>/dev/null || echo "clickhouse 未装上(下轮补)"
    true
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
    log "uv (独立安装器,不经过系统 pip;库索引 /etc/uv/uv.toml=$PIP_INDEX)"
    # uv 0.4.23 起 UV_INDEX_URL 废弃;系统配置写 /etc/uv/uv.toml(tuna 帮助口径)
    # offline = true:运行期 uv 拉新包立即失败。实证(uv 0.12.15):UV_OFFLINE=0 压不过
    # 配置文件,只有 UV_CONFIG_FILE 指到无 offline 的文件才整面替换——构建期的在线面
    # 是 uv-online.toml(common.sh 导出 UV_CONFIG_FILE 指过去)。
    # 配置写在早退前(幂等,不依赖网络),否则增量重跑永远刷不上
    install -d /etc/uv
    printf 'offline = true\n\n[[index]]\nurl = "%s"\ndefault = true\n' "$PIP_INDEX" > /etc/uv/uv.toml
    printf '[[index]]\nurl = "%s"\ndefault = true\n' "$PIP_INDEX" > /etc/uv/uv-online.toml
    if have uv; then uv --version; echo "已安装,跳过"; return; fi
    # 用户裁定:不碰系统 python3,uv 用官方独立安装器(装到 ~/.local/bin)
    curl -LsSf https://astral.sh/uv/install.sh | sh
    [ -e "$HOME/.local/bin/uv" ] && ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv
    export UV_DEFAULT_INDEX="$PIP_INDEX"
    uv --version
}

install_dotnet() {
    log "dotnet ($DOTNET_SDK,noble 自带源=tuna;MS 仓 24.04 起不提供 .NET)"
    apt-get update -qq
    apt-get install -y "$DOTNET_SDK"
    # NuGet 库镜像:华为 v3(已实证 200;不要用 azure.cn 旧 CDN,已解析失败)
    # 离线取件走 NuGet.Config 的 fallbackPackageFolders(见下);不要再导出
    # NUGET_PACKAGES=/opt/nuget-packages——那会把 global 与 fallback 指成同一目录,
    # 登录 restore 往固化仓写,ubuntu 还会权限失败(grok G3)
    install -d /opt/nuget-packages
    cat > /etc/profile.d/dotnet.sh <<'EOF'
export DOTNET_CLI_TELEMETRY_OPTOUT=1
EOF
    for u in /root /home/ubuntu; do
        [ -d "$u" ] && install -d "$u/.nuget/NuGet" && cat > "$u/.nuget/NuGet/NuGet.Config" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="huaweicloud" value="${NUGET_MIRROR}" />
  </packageSources>
  <!-- 非登录 shell(incus exec)读不到 NUGET_PACKAGES:fallback folder 是 NuGet
       官方离线机制(同 SDK NuGetFallbackFolder),restore 直接从固化目录取件 -->
  <fallbackPackageFolders>
    <add key="prewarm" value="/opt/nuget-packages" />
  </fallbackPackageFolders>
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
    # localRepository 指 /opt/m2:留默认 ~/.m2 则 ubuntu 与 root 各一份,离线都救不了
    cat > /opt/maven/conf/settings.xml <<EOF
<settings>
  <localRepository>/opt/m2</localRepository>
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
    # GRADLE_USER_HOME 指 /opt/gradle-home:默认 ~/.gradle 在 /root 下,ubuntu 离线无解
    install -d /opt/gradle-home/init.d
    cat > /etc/profile.d/gradle.sh <<'EOF'
export GRADLE_USER_HOME=/opt/gradle-home
EOF
    # 非登录 shell(incus exec)不读 profile.d:家目录默认位软链兜底;
    # gradle 家目录要可写(daemon/锁),共同组+setgid 共享,不 1777(grok F1)
    for u in /root /home/ubuntu; do
        [ -d "$u" ] || continue
        [ -L "$u/.gradle" ] || rm -rf "$u/.gradle"
        ln -sfn /opt/gradle-home "$u/.gradle"
    done
    shared_writable_cache /opt/gradle-home
    cat > /opt/gradle-home/init.d/mirrors.gradle <<'EOF'
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
    gradle --version 2>/dev/null | grep -m1 Gradle
    set +u; sdk current; set -u   # sdk 主脚本引用未绑定位置参数,与 set -u 冲突
}

# ---- PHP 多版本(webshell 逆向:7.4 复现老样本,8.x 对照现代样本) ------------
# 依据样本兼容性选版本,不是"哪个更安全"。7.4 已无官方支持,只放隔离机。
install_php() {
    log "PHP 多版本 $PHP_VERSIONS (Ondřej Surý 源,$SURY_MIRROR)"
    # sury 源 GPG key(官方分发;镜像只镜像仓库,key 仍从官方取一次)
    curl -fsSL "https://packages.sury.org/php/apt.gpg" -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] ${SURY_MIRROR}/php noble main" \
        > /etc/apt/sources.list.d/sury-php.list
    apt-get update -qq
    local v
    for v in $PHP_VERSIONS; do
        apt-get install -y --no-install-recommends "php${v}-cli" "php${v}-dev" || echo "php${v} 安装失败,跳过"
        have "php${v}" && "php${v}" -v | head -1
    done
    # VLD(opcode dump):PHP 8.0 工具链最稳,8.1+ 常需自行编译;逐个版本尽力而为
    apt-get install -y --no-install-recommends php-pear
    for v in $PHP_VERSIONS; do
        have "php${v}" || continue
        if "php${v}" -m 2>/dev/null | grep -qi '^vld$'; then
            echo "php${v}: VLD 已在"; continue
        fi
        echo "--- 为 php${v} 编译 VLD(pecl vld-beta,sury 多版本用 php_suffix)"
        if yes '' | pecl -q -d "php_suffix=${v}" install vld-beta >/dev/null 2>&1; then
            echo "extension=vld.so" > "/etc/php/${v}/mods-available/vld.ini"
            phpenmod -v "$v" vld 2>/dev/null || true
            "php${v}" -m 2>/dev/null | grep -qi '^vld$' && echo "php${v}: VLD 装好" || echo "php${v}: VLD ini 已写但未加载,查 php${v} -m"
        else
            echo "php${v} 的 VLD 编译失败(可手动 phpize 编译 VLD 0.18.0)"
        fi
    done
    # 分析注意:跑样本前关 opcache.jit(VLD 与单步行为会偏);
    # 不要用 2021-03 被植入后门的 8.1.0-dev 快照当分析运行时。
    cat <<'EOF'
PHP 逆向提示:
  - 多版本并存:/usr/bin/php7.4、php8.1、php8.3 直接写全路径切换
  - opcode:php -d vld.active=1 <样本>;VLD 输出对齐公开数据集用 PHP 8.0 + VLD 0.18.0 最稳
  - 动态执行前:-d opcache.jit=off
  - 样本只在无网络、无生产数据挂载的环境里跑;静态先用 php-malware-finder(YARA)过一遍
EOF
}


# ---- mono(老 .NET Framework 项目的构建与运行链) --------------------------
install_mono() {
    log "mono 工具链 (apt,tuna):xbuild + .NET 4.x 引用程序集 + mono 运行时"
    log "注: noble 没有 msbuild 包(Debian #1033828 wontfix),经典 csproj 用 xbuild"
    apt-get update -qq
    apt-get install -y --no-install-recommends mono-devel mono-xbuild
    # nuget.exe:还原 packages.config 型老项目(noble apt 无 nuget 包)
    [ -f /opt/nuget.exe ] || curl -fSL "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -o /opt/nuget.exe
    xbuild /version 2>/dev/null | tail -1 || true
    mono --version 2>/dev/null | head -1
}

RUNTIMES_ALL=(node fnm bun uv python python2 duckdb clickhouse php mono dotnet pwsh sdkman)
run_category RUNTIMES_ALL "$@"

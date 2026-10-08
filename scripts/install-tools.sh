#!/usr/bin/env bash
# 工具安装器:fd/rg/astgrep/cli(jq yq shellcheck git gh just)/pd 全家桶/secgo/secrust
# 在 Ubuntu 24.04 容器(或宿主)内运行,幂等,可重复执行。
# 用法:
#   ./install-tools.sh            # 装全部
#   ./install-tools.sh pd cli  # 只装指定项(可多个)
# 镜像源与版本经环境变量覆盖,见 lib/common.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

install_fd() {
    log "fd + ripgrep (apt,tuna)"
    apt-get update -qq
    apt-get install -y --no-install-recommends fd-find ripgrep
    ln -sf /usr/bin/fdfind /usr/local/bin/fd
    fd --version && rg --version
}

install_astgrep() {
    log "ast-grep (cargo 安装,经 tuna crates)"
    . "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$PATH:/root/.cargo/bin"
    if have sg; then sg --version; echo "已安装,跳过"; return; fi
    cargo install ast-grep --locked
    ln -sf /root/.cargo/bin/sg /usr/local/bin/sg
    sg --version
}

install_cli() {
    log "git/jq/shellcheck/just (apt,tuna);yq/gh (go install,goproxy.cn)"
    apt-get update -qq
    apt-get install -y --no-install-recommends git jq shellcheck just || true
    export PATH="$PATH:/usr/local/go/bin:/root/go/bin"
    export GOPROXY GOSUMDB
    if ! have yq; then
        go install github.com/mikefarah/yq/v4@latest
        ln -sf /root/go/bin/yq /usr/local/bin/yq
    fi
    if ! have gh; then
        go install github.com/cli/cli/v2/cmd/gh@latest   # gh 官方 apt 源国内无镜像,源码编译
        ln -sf /root/go/bin/gh /usr/local/bin/gh
    fi
    # just 在部分套件下无 apt 包,兜底 cargo
    if ! have just; then
        . "$HOME/.cargo/env" 2>/dev/null || true
        cargo install just --locked
        ln -sf /root/.cargo/bin/just /usr/local/bin/just
    fi
    git --version && jq --version && yq --version && shellcheck --version | head -1 \
        && just --version && gh --version | head -1
}

PD_TOOLS_DEFAULT=(
    subfinder/v2/cmd/subfinder
    dnsx/cmd/dnsx
    naabu/v2/cmd/naabu
    httpx/cmd/httpx
    nuclei/v3/cmd/nuclei
    katana/cmd/katana
    uncover/cmd/uncover
    cloudlist/cmd/cloudlist
    notify/cmd/notify
    interactsh/cmd/interactsh-client
    chaos-client/cmd/chaos
    mapcidr/cmd/mapcidr
    asnmap/cmd/asnmap
    tlsx/cmd/tlsx
    proxify/cmd/proxify
    simplehttpserver/cmd/simplehttpserver
    shuffledns/cmd/shuffledns
    pdtm/cmd/pdtm
)

install_pd() {
    log "projectdiscovery 全家桶 (go install @${PD_VERSION},经 $GOPROXY)"
    . "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$PATH:/usr/local/go/bin:${GOPATH:-/root/go}/bin"
    export GOPROXY GOSUMDB
    # shellcheck disable=SC2206
    local tools=( ${PD_TOOLS:-} ); [ ${#tools[@]} -eq 0 ] && tools=("${PD_TOOLS_DEFAULT[@]}")
    local t bin
    for t in "${tools[@]}"; do
        bin="${t##*/}"
        if have "$bin"; then echo "$bin 已装,跳过"; continue; fi
        echo "--- go install $t@${PD_VERSION}"
        go install "github.com/projectdiscovery/${t}@${PD_VERSION}" || echo "!! $bin 编译失败(留待排查)" 
        have "$bin" && ln -sf "$(command -v "$bin")" "/usr/local/bin/$bin"
    done
    echo "已装 PD 工具:"; for t in "${tools[@]}"; do command -v "${t##*/}" >/dev/null && printf '  %s\n' "${t##*/}"; done
    # nuclei 模板(从 GitHub 拉,国内可能慢,失败不影响工具本体)
    if have nuclei; then nuclei -update-templates 2>/dev/null || echo "nuclei 模板更新失败,可稍后重试"; fi
    # naabu SYN 扫描需要 libpcap 与 cap_net_raw
    apt-get install -y --no-install-recommends libpcap-dev
    if have naabu; then setcap cap_net_raw,cap_net_admin+eip "$(command -v naabu)" 2>/dev/null || true; fi
}

SECGO_TOOLS_DEFAULT=(
    ffuf/v2@github.com/ffuf
    gobuster/v3@github.com/OJ
    dalfox/v2@github.com/hahwul
    amass/v4/...@github.com/owasp-amass
    chisel@github.com/jpillora
    gitleaks/v8@github.com/zricethezav
    assetfinder@github.com/tomnomnom
    httprobe@github.com/tomnomnom
    qsreplace@github.com/tomnomnom
    waybackurls@github.com/tomnomnom
    gau/v2/cmd/gau@github.com/lc
    gospider@github.com/jaeles-project
    gowitness@github.com/sensepost
    azurehound/v2@github.com/bloodhoundad
)

install_secgo() {
    log "Go 安全 CLI (go install @${SECGO_VERSION:-latest},经 $GOPROXY)"
    export PATH="$PATH:/usr/local/go/bin:/root/go/bin"
    export GOPROXY GOSUMDB
    # shellcheck disable=SC2206
    local tools=( ${SECGO_TOOLS:-} ); [ ${#tools[@]} -eq 0 ] && tools=("${SECGO_TOOLS_DEFAULT[@]}")
    local spec path repo bin first last produced
    local gobin; gobin="$(go env GOBIN 2>/dev/null || true)"; [ -n "$gobin" ] || gobin="$HOME/go/bin"
    for spec in "${tools[@]}"; do
        path="${spec%@*}"; repo="${spec#*@}"
        first="${path%%/*}"; last="${path##*/}"
        # 目标二进制名:带版本目录的模块(ffuf/v2)产物名是版本号(v2),要改名
        bin="$first"
        produced="$last"
        [ "$last" = "..." ] && produced="$first"
        if have "$bin"; then echo "$bin 已装,跳过"; continue; fi
        echo "--- go install $repo/$path@${SECGO_VERSION:-latest}"
        if go install "${repo}/${path}@${SECGO_VERSION:-latest}"; then
            if ! have "$bin" && [ "$produced" != "$bin" ] && [ -f "$gobin/$produced" ]; then
                mv "$gobin/$produced" "$gobin/$bin"   # v2/v3/v8 -> ffuf/gobuster/gitleaks
            fi
            have "$bin" && ln -sf "$gobin/$bin" "/usr/local/bin/$bin"
        else
            echo "!! $bin 编译失败(留待排查)"
        fi
    done
    echo "已装:"; for spec in "${tools[@]}"; do path="${spec%@*}"; bin="${path%%/*}"; have "$bin" && printf '  %s\n' "$bin"; done
    true   # 循环尾可能是 command -v 失败,吞掉以防 set -e 中断后续组
}

install_secrust() {
    log "rustscan / feroxbuster / findomain (cargo,经 tuna crates)"
    . "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$PATH:/root/.cargo/bin"
    have rustscan    || cargo install rustscan --locked
    have feroxbuster || cargo install feroxbuster --locked
    # findomain 依赖多,cargo 失败则提示走 GitHub Releases 预编译
    have findomain   || cargo install findomain --locked || echo "findomain 编译失败,改走 https://github.com/Findomain/Findomain/releases 预编译"
    for b in rustscan feroxbuster findomain; do
        if have "$b"; then
            ln -sf "$HOME/.cargo/bin/$b" "/usr/local/bin/$b" 2>/dev/null || true
            "$b" --version 2>/dev/null | head -1
        fi
    done
}


# ---- Ghidra(逆向;硬依赖 64 位 JDK 21,temurin 21 已在 runtimes 装好) -------
install_ghidra() {
    log "ghidra $GHIDRA_VERSION (GitHub Releases 直下,无国内镜像)"
    local z="ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"
    local url="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/${z}"
    if [ ! -d /opt/ghidra ]; then
        curl -fSL "$url" -o "/tmp/${z}"
        # 官方发布页给出的 SHA-256(GHIDRA_SHA256 钉在 common.sh,换版本时同步换)
        if [ -n "${GHIDRA_SHA256:-}" ]; then
            echo "${GHIDRA_SHA256}  /tmp/${z}" | sha256sum -c - || { echo "ghidra zip 校验失败"; exit 1; }
        fi
        mkdir -p /opt/ghidra
        unzip -q "/tmp/${z}" -d /opt/ghidra && rm "/tmp/${z}"
    fi
    local gdir; gdir="$(ls -d /opt/ghidra/ghidra_*/ | head -1)"
    # 钉死 JDK 21:多版本共存时防止被默认 JDK(25)抢
    local j21; j21="$(ls -d /opt/jdk/temurin-21* /usr/local/sdkman/candidates/java/21* 2>/dev/null | head -1)"
    [ -n "$j21" ] || { echo "找不到 JDK 21,先跑 install-runtimes.sh sdkman"; exit 1; }
    local lp="${gdir}support/launch.properties"
    if grep -q '^JAVA_HOME_OVERRIDE=' "$lp" 2>/dev/null; then
        sed -i "s|^JAVA_HOME_OVERRIDE=.*|JAVA_HOME_OVERRIDE=${j21}|" "$lp"
    else
        printf 'JAVA_HOME_OVERRIDE=%s\n' "$j21" >> "$lp"
    fi
    ln -sf "${gdir}ghidraRun" /usr/local/bin/ghidraRun
    ln -sf "${gdir}support/analyzeHeadless" /usr/local/bin/analyzeHeadless
    echo "JDK21 -> $j21"
    echo "headless 用法: analyzeHeadless /tmp/ghidra-proj MyProj -import /path/to/bin"
}


# ---- 逆向稳定链:系统库 + rizin/rz-ghidra/sigdb + Python RE venv ------------
# 不装 apt 的 radare2,不装 knife/rsleigh/Ghidrust;Keystone/Unicorn 走 venv 不走 apt
install_re() {
    log "逆向链系统库 (apt,tuna)"
    # libzip-dev 必须给:缺了 meson 会去 libzip.org 拉子项目,国内必失败
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        binutils elfutils file bsdmainutils binwalk \
        yara libyara-dev \
        libzip-dev \
        libpugixml-dev \
        libcapstone-dev capstone-tool \
        meson ninja-build cmake pkg-config git gcc g++ \
        python3 python3-pip python3-venv zlib1g-dev
    for b in readelf objdump eu-readelf yara cstool file binwalk; do
        have "$b" && printf '  %-12s %s\n' "$b" "$($b --version 2>/dev/null | head -1)"
    done

    log "rizin + rz-ghidra + sigdb (源码编译;JDK 不另装,temurin 21 已够 ghidra 用)"
    local gh; gh="${GITHUB_MIRROR}https://github.com"
    if ! have rizin; then
        rm -rf /tmp/rizin && git clone --depth 1 "${gh}/rizinorg/rizin" /tmp/rizin
        meson setup /tmp/rizin/build /tmp/rizin --buildtype=release
        meson compile -C /tmp/rizin/build && meson install -C /tmp/rizin/build
        rm -rf /tmp/rizin
    fi
    ldconfig
    if ! rizin -qc 'Lc' /bin/ls 2>/dev/null | grep -qi ghidra; then
        rm -rf /tmp/rz-ghidra
        git clone --depth 1 "${gh}/rizinorg/rz-ghidra" /tmp/rz-ghidra
        # rz-ghidra 硬编码从 <rz-ghidra>/ghidra/ghidra/Ghidra/... 取反编译器源
        # (ghidra/CMakeLists.txt:146 的 SOURCE_DIR,发布 zip 里没有这些源),
        # 把 ghidra 源码克隆放到这个嵌套位置
        git clone --depth 1 --branch "Ghidra_${GHIDRA_VERSION}_build" "${gh}/NationalSecurityAgency/ghidra" /tmp/rz-ghidra/ghidra/ghidra \
            || git clone --depth 1 "${gh}/NationalSecurityAgency/ghidra" /tmp/rz-ghidra/ghidra/ghidra
        export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
        # rz_core.pc 的 plugindir 是相对路径,pkg-config 直取会装到 CWD 相对目录
        # 然后被 rm 掉;用 rizin 运行时报告的 dir.plugins 为准
        local plugdir; plugdir="$(rizin -qc 'e dir.plugins' -q 2>/dev/null || true)"
        [ -n "$plugdir" ] || plugdir="/usr/local/lib/x86_64-linux-gnu/rizin/plugins"
        # USE_SYSTEM_PUGIXML:third-party 的 pugixml 也是子模块,用系统包绕过
        cmake -S /tmp/rz-ghidra -B /tmp/rz-ghidra/build -DCMAKE_BUILD_TYPE=Release \
            -DUSE_SYSTEM_PUGIXML=ON \
            -DRIZIN_INSTALL_PLUGINDIR="${plugdir}"
        cmake --build /tmp/rz-ghidra/build && cmake --install /tmp/rz-ghidra/build
        rm -rf /tmp/rz-ghidra
    fi
    if ! ls -d /usr/share/rizin/sigdb /usr/local/share/rizin/sigdb "$HOME"/.local/share/rizin/sigdb >/dev/null 2>&1; then
        rm -rf /tmp/sigdb && git clone --depth 1 "${gh}/rizinorg/sigdb" /tmp/sigdb
        ( cd /tmp/sigdb && ./install.sh ) || echo "sigdb 安装失败(不影响 rizin 本体)"
        rm -rf /tmp/sigdb
        ls -d /usr/share/rizin/sigdb /usr/local/share/rizin/sigdb "$HOME"/.local/share/rizin/sigdb >/dev/null 2>&1 \
            && echo "sigdb 已装" || echo "!! sigdb 未找到,查 install.sh 输出"
    fi
    rizin -v
    rizin -qc 'Lc' /bin/ls 2>/dev/null | grep -i ghidra || echo "!! rz-ghidra 未进插件目录"

    log "Python RE venv ($RE_VENV;capstone/keystone/unicorn/lief/yara-python)"
    if [ ! -x "$RE_VENV/bin/python" ]; then
        python3 -m venv "$RE_VENV"
    fi
    "$RE_VENV/bin/pip" install -U pip >/dev/null
    "$RE_VENV/bin/pip" install capstone keystone-engine unicorn lief yara-python
    "$RE_VENV/bin/python" -c 'import capstone,keystone,unicorn,lief,yara; print("re-venv ok")'
    cat <<EOF
对应关系:capstone 反汇编 / keystone 汇编 / unicorn 模拟执行 / lief 解析改写 PE-ELF-MachO / yara-python 规则扫描
EOF
}

TOOLS_ALL=(fd astgrep cli ghidra re pd secgo secrust)
run_category TOOLS_ALL "$@"

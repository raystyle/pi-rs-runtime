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
    # sg 与 shadow 包的 /usr/bin/sg(switch group)撞名,have sg 恒真会跳过安装;
    # 判装与链接都用全名 ast-grep
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    . /opt/cargo/env 2>/dev/null || true
    export PATH="$PATH:/opt/cargo/bin"
    if have ast-grep; then ast-grep --version; echo "已安装,跳过"; return; fi
    cargo install ast-grep --locked
    ln -sf /opt/cargo/bin/ast-grep /usr/local/bin/ast-grep
    ln -sf /opt/cargo/bin/sg /usr/local/bin/sg
    ast-grep --version
}

install_cli() {
    log "git/jq/shellcheck/just (apt,tuna);yq/gh (go install,goproxy.cn)"
    apt-get update -qq
    apt-get install -y --no-install-recommends git jq shellcheck just tmux rclone aria2 || true
    # GOPATH 指 /opt/go:不设则 go install 产物落 /root/go(0700),ubuntu 不可执行
    export PATH="$PATH:/usr/local/go/bin:/opt/go/bin"
    export GOPATH=/opt/go
    export GOPROXY GOSUMDB
    if ! have yq; then
        go install github.com/mikefarah/yq/v4@latest
        ln -sf /opt/go/bin/yq /usr/local/bin/yq
    fi
    if ! have gh; then
        go install github.com/cli/cli/v2/cmd/gh@latest   # gh 官方 apt 源国内无镜像,源码编译
        ln -sf /opt/go/bin/gh /usr/local/bin/gh
    fi
    # just 在部分套件下无 apt 包,兜底 cargo
    if ! have just; then
        . "$HOME/.cargo/env" 2>/dev/null || true
        cargo install just --locked
        ln -sf /root/.cargo/bin/just /usr/local/bin/just
    fi
    git --version && jq --version && yq --version && shellcheck --version | head -1 \
        && just --version && gh --version | head -1
    aria2c --version | head -1
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
    export GOPATH=/opt/go PATH="$PATH:/usr/local/go/bin:/opt/go/bin"
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
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    . /opt/cargo/env 2>/dev/null || true
    export PATH="$PATH:/opt/cargo/bin"
    have rustscan    || cargo install rustscan --locked
    have feroxbuster || cargo install feroxbuster --locked
    # findomain 依赖多,cargo 失败则提示走 GitHub Releases 预编译
    # findomain 依赖多常编不过,要用时走 https://github.com/Findomain/Findomain/releases 预编译
    for b in rustscan feroxbuster; do
        if have "$b"; then
            ln -sf "/opt/cargo/bin/$b" "/usr/local/bin/$b" 2>/dev/null || true
            "$b" --version 2>/dev/null | head -1 || true
        fi
    done
}


# ---- herdr(终端 workspace 管理器;tmux 之外的 agent 编排面) -----------------
# 官方安装通道是 herdr.dev/install.sh(解析 latest.json 下 GitHub release);
# 这里等价实现并钉版:装到 /usr/local/bin 全局可用,不走 ~/.local/bin
install_herdr() {
    log "herdr $HERDR_VERSION (release 直下,无国内镜像;sha256 钉版)"
    local gh="${GITHUB_MIRROR}https://github.com"
    local harch; case "$(dpkg --print-architecture)" in
        amd64) harch=x86_64 ;;
        arm64) harch=aarch64 ;;
        *) echo "不支持的架构"; return 1 ;;
    esac
    if ! have herdr; then
        curl -fSL "${gh}/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-${harch}" -o /tmp/herdr
        # sha256 只钉了 x86_64 资产;arm64 换版本时重算补钉
        if [ "$harch" = x86_64 ] && [ -n "${HERDR_SHA256:-}" ]; then
            echo "${HERDR_SHA256}  /tmp/herdr" | sha256sum -c - || { echo "herdr 校验失败"; exit 1; }
        fi
        install -m755 /tmp/herdr /usr/local/bin/herdr && rm /tmp/herdr
    fi
    herdr --version
    true
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
    # ls 多 glob 有一个布局不存在即返回 2,pipefail 下赋值会失败退出,|| true 兜底
    local j21; j21="$(ls -d /opt/jdk/temurin-21* /usr/local/sdkman/candidates/java/21* 2>/dev/null | head -1 || true)"
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
        have "$b" && printf '  %-12s %s\n' "$b" "$($b --version 2>/dev/null | head -1)" || true
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
        # ghidra 是 rz-ghidra 的 git 子模块,其提交钉死了匹配的 ghidra ref;
        # 自己按版本号克隆会 API 不匹配(core_ghidra.cpp 编译错),必须走子模块
        git clone --depth 1 --recurse-submodules --shallow-submodules "${gh}/rizinorg/rz-ghidra" /tmp/rz-ghidra
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
        # sigdb 已改版为纯数据仓库(elf/pe + meson),旧 install.sh 不存在,用 meson 装
        rm -rf /tmp/sigdb && git clone --depth 1 "${gh}/rizinorg/sigdb" /tmp/sigdb
        meson setup /tmp/sigdb/build /tmp/sigdb --prefix=/usr/local >/dev/null \
            && meson install -C /tmp/sigdb/build || echo "sigdb 安装失败(不影响 rizin 本体)"
        rm -rf /tmp/sigdb
        ls -d /usr/local/share/rizin/sigdb >/dev/null 2>&1 && echo "sigdb 已装" || echo "!! sigdb 未找到"
    fi
    rizin -v
    rizin -qc 'Lc' /bin/ls 2>/dev/null | grep -i ghidra || echo "!! rz-ghidra 未进插件目录"

    log "Python RE venv ($RE_VENV;uv venv;capstone/keystone/unicorn/lief/yara-python)"
    . "$HOME/.local/bin/env" 2>/dev/null || true
    [ -x "$RE_VENV/bin/python" ] || uv venv "$RE_VENV"
    VIRTUAL_ENV="$RE_VENV" uv pip install capstone keystone-engine unicorn lief yara-python
    "$RE_VENV/bin/python" -c 'import capstone,keystone,unicorn,lief,yara; print("re-venv ok")'
    cat <<EOF
对应关系:capstone 反汇编 / keystone 汇编 / unicorn 模拟执行 / lief 解析改写 PE-ELF-MachO / yara-python 规则扫描
EOF
}


# ---- 代理跳板(pivot):隧道/反向代理工具 + 库预热 --------------------------
install_pivot() {
    log "代理跳板: gost/frp/wstunnel/rathole/bore (go install + cargo,国内源)"
    export PATH="$PATH:/usr/local/go/bin:/opt/go/bin"
    export GOPATH=/opt/go GOPROXY GOSUMDB
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    . /opt/cargo/env 2>/dev/null || true
    export PATH="$PATH:/opt/cargo/bin"
    # Go 栈
    have gost   || go install github.com/go-gost/gost/cmd/gost@latest \
        || go install github.com/ginuerzh/gost/cmd/gost@latest || echo "gost 失败"
    # frp:go.mod 带 replace(go install 拒装),源码 build 又缺 web/dist(embed 失败)
    # → 直接下 GitHub Release 预编译(arm 机器改 FRP_ARCH)
    if ! have frps || ! have frpc; then
        local ftag farch="amd64"; [ "$(dpkg --print-architecture)" = arm64 ] && farch="arm64"
        ftag="$(curl -fsSL "https://api.github.com/repos/fatedier/frp/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
        if [ -n "$ftag" ]; then
            local ftgz="frp_${ftag#v}_linux_${farch}.tar.gz"
            curl -fSL "https://github.com/fatedier/frp/releases/download/${ftag}/${ftgz}" -o "/tmp/${ftgz}" \
                && tar -C /tmp -xzf "/tmp/${ftgz}" \
                && install -m755 "/tmp/frp_${ftag#v}_linux_${farch}/frps" "/tmp/frp_${ftag#v}_linux_${farch}/frpc" /usr/local/bin/ \
                && rm -rf "/tmp/${ftgz}" "/tmp/frp_${ftag#v}_linux_${farch}"
        fi
        have frps || echo "frp 失败"
    fi
    # Rust 栈
    # wstunnel 不在 crates.io,cargo install --git 拉源码(依赖走 tuna)
    have wstunnel || cargo install --git https://github.com/erebe/wstunnel --locked || echo "wstunnel 失败"
    # rathole 0.5.0 老锁在新 rustc 上编不过,先去 --locked,再退回 git 主干
    have rathole || cargo install rathole \
        || cargo install --git https://github.com/rathole-org/rathole || echo "rathole 失败"
    have bore     || cargo install bore-cli --locked || echo "bore 失败"
    local gobin; gobin="/opt/go/bin"; export GOPATH=/opt/go
    for b in gost frps frpc; do
        [ -e "$gobin/$b" ] && ln -sf "$gobin/$b" "/usr/local/bin/$b"
    done
    for b in wstunnel rathole bore; do
        [ -e "$HOME/.cargo/bin/$b" ] && ln -sf "/opt/cargo/bin/$b" "/usr/local/bin/$b"
    done
    for b in gost frps frpc wstunnel rathole bore; do have "$b" && printf '  %s\n' "$b"; done
    true
}


# ---- P0 补齐(grok 业界调研;Kali/REMnux/FLARE 重叠缺口) ------------------
# 分三步:apt 批(全 TUNA)/ re-venv pip 批(TUNA PyPI)/ GitHub 钉版批
install_p0() {
    log "P0 apt 批(22 包,TUNA):多架构调试/pwn/流量/分诊/AD/口令"
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        gdb-multiarch qemu-user-static \
        python3-pwntools python3-ropgadget checksec patchelf nasm xxd squashfs-tools \
        nmap sqlmap tcpdump tshark mitmproxy python3-scapy \
        upx-ucl 7zip libimage-exiftool-perl ssdeep python3-impacket \
        john hashid || echo "!! p0 apt 批部分失败(网络抖动可重跑,已装的会跳过)"
    # 批失败不退出:后续 pip 批与 GitHub 批与 apt 包相互独立

    log "P0 re-venv 批(uv venv + uv pip,TUNA):FLOSS/oletools/netexec"
    . "$HOME/.local/bin/env" 2>/dev/null || true
    export PATH="$PATH:/usr/local/bin"
    [ -x "$RE_VENV/bin/python" ] || uv venv "$RE_VENV"
    # netexec 在 tuna 索引里可能缺,退回 git 源
    VIRTUAL_ENV="$RE_VENV" uv pip install flare-floss oletools \
        || VIRTUAL_ENV="$RE_VENV" uv pip install --no-cache flare-floss oletools
    VIRTUAL_ENV="$RE_VENV" uv pip install netexec \
        || VIRTUAL_ENV="$RE_VENV" uv pip install "git+https://github.com/Pennyw0rth/NetExec"
    # venv 里的 CLI 进默认 PATH(评审 F6):pd/secgo 约定是 /usr/local/bin
    for b in floss olevba oleid netexec; do
        [ -e "$RE_VENV/bin/$b" ] && ln -sf "$RE_VENV/bin/$b" "/usr/local/bin/$b"
    done

    log "P0 GitHub 批(钉版,无国内镜像):pwndbg/jadx/apktool/capa/SecLists/YARA规则/pdf工具"
    local gh="${GITHUB_MIRROR}https://github.com"
    # pwndbg: PyPI 有官方包,比 deb 简单且可钉版
    # pwndbg:tuna/PyPI 无包;uv tool 从 git 源装(未钉 rev,上游 dev 分支会漂,见 ROADMAP)
    # UV_TOOL_BIN_DIR/UV_TOOL_DIR 指到 /opt:shim 与工具体对 ubuntu 可读(评审 F5)
    . "$HOME/.local/bin/env" 2>/dev/null || true
    export UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools
    have pwndbg || uv tool install "git+${gh}/pwndbg/pwndbg" || echo "pwndbg 失败"
    # jadx:CLI zip
    if ! have jadx; then
        local jv; jv="${JADX_VERSION:-1.5.3}"
        local jz="jadx-${jv}.zip"
        curl -fSL "${gh}/skylot/jadx/releases/download/v${jv}/${jz}" -o "/tmp/${jz}" \
            && unzip -q "/tmp/${jz}" -d /opt/jadx && rm "/tmp/${jz}"
        # zip 根布局是 bin/jadx + lib/,没有版本目录
        ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx 2>/dev/null || true
    fi
    # apktool:jar + 包装脚本
    if ! have apktool; then
        local av; av="${APKTOOL_VERSION:-2.12.0}"
        install -d /opt/apktool
        curl -fSL "${gh}/iBotPeaches/Apktool/releases/download/v${av}/apktool_${av}.jar" -o /opt/apktool/apktool.jar
        printf '#!/bin/sh\nexec java -jar /opt/apktool/apktool.jar "$@"\n' > /usr/local/bin/apktool
        chmod +x /usr/local/bin/apktool
    fi
    # capa:独立发行包(带规则);规则库单独克隆便于更新
    if ! have capa; then
        local cv; cv="${CAPA_VERSION:-9.4.0}"   # v9.5.0 上游不存在,latest=v9.4.0(已核)
        local cz="capa-v${cv}-linux.zip"
        curl -fSL "${gh}/mandiant/capa/releases/download/v${cv}/${cz}" -o "/tmp/${cz}" \
            && unzip -q "/tmp/${cz}" -d /opt/capa && rm "/tmp/${cz}"
        find /opt/capa -name capa -type f -exec ln -sf {} /usr/local/bin/capa \; 2>/dev/null || true
    fi
    [ -d /opt/capa-rules ] || git clone --depth 1 "${gh}/mandiant/capa-rules" /opt/capa-rules
    # YARA 规则集(REMnux v8 选 yara-forge;经典集 Yara-Rules/rules)
    [ -d /opt/yara-rules ] || git clone --depth 1 "${gh}/Yara-Rules/rules" /opt/yara-rules
    # pdfid / pdf-parser(DidierStevens,只拷两只脚本)
    if ! have pdfid.py; then
        rm -rf /tmp/dss && git clone --depth 1 "${gh}/DidierStevens/DidierStevensSuite" /tmp/dss
        # shebang 是 python,noble 无此命令,拷完改成 python3
        cp /tmp/dss/pdfid.py /tmp/dss/pdf-parser.py /usr/local/bin/ 2>/dev/null \
            && chmod +x /usr/local/bin/pdfid.py /usr/local/bin/pdf-parser.py \
            && sed -i '1s|^#!.*|#!/usr/bin/env python3|' /usr/local/bin/pdfid.py /usr/local/bin/pdf-parser.py
        rm -rf /tmp/dss
    fi
    # SecLists 词表(大,depth 1)
    [ -d /opt/SecLists ] || git clone --depth 1 "${gh}/danielmiessler/SecLists" /opt/SecLists

    echo "P0 核对:"
    for b in gdb-multiarch checksec patchelf nasm ROPgadget nmap sqlmap tshark capa jadx apktool john hashid; do
        have "$b" && printf '  %s\n' "$b"
    done
    ls -d /opt/SecLists /opt/capa-rules /opt/yara-rules >/dev/null 2>&1 && echo "  词表与规则库就位(/opt/{SecLists,capa-rules,yara-rules})"
    true
}


# ---- C2 框架参考(sliver/merlin/empire/covenant/ysoserial 系) ---------------
# 用户裁定(2026-10-08):C2 代码不安装不编译,只克隆给后渗透参考——
# 自架 C2 等于在自己基础设施上起 beacon 服务,供给面风险自负
install_c2() {
    log "C2 参考克隆(不安装不运行): sliver/merlin/empire/covenant/ysoserial/ysoserial.net"
    local gh="${GITHUB_MIRROR}https://github.com"
    install -d /opt/c2-ref
    local r
    for r in bishopfox/sliver Ne0nd0g/merlin BC-SECURITY/Empire cobbr/Covenant \
             frohoff/ysoserial pwntester/ysoserial.net; do
        local d="/opt/c2-ref/$(basename "$r")"
        [ -d "$d/.git" ] || git clone --depth 1 "${gh}/${r}" "$d" || echo "$r 克隆失败"
    done
    echo "参考就位: /opt/c2-ref/(构建与运行属部署面,参考 grok dotnetfx 方案与各仓库文档)"
    true
}

# ---- BOF(Beacon Object File)工具链:交叉编译 + 脱离 C2 运行 ----------------
install_bof() {
    log "BOF 工具链: mingw-w64 + COFFLoader + atomic-bofs + 目录"
    local gh="${GITHUB_MIRROR}https://github.com"
    apt-get update -qq
    apt-get install -y --no-install-recommends mingw-w64
    # COFFLoader 的 standalone 仍依赖 Windows 类型(BOOL/InternalFunctions),
    # Linux 直编过不了上游也没支持;交叉编 Windows 版(wine 下可用),
    # Linux 上跑 BOF 用 coffee / bof-launcher
    if [ ! -f /opt/COFFLoader/COFFLoader64.exe ]; then
        rm -rf /tmp/coffloader && git clone --depth 1 "${gh}/trustedsec/COFFLoader" /tmp/coffloader
        ( cd /tmp/coffloader && make bof && install -d /opt/COFFLoader \
            && install -m644 COFFLoader64.exe test64.out /opt/COFFLoader/ ) || echo "coffloader mingw 构建失败"
        rm -rf /tmp/coffloader
    fi
    # atomic-bofs:rasta-mouse 的 COFF 独立运行 harness(带打包参数)
    [ -d /opt/atomic-bofs/.git ] || git clone --depth 1 "${gh}/rasta-mouse/atomic-bofs" /opt/atomic-bofs
    # Coffee(hakaioffsec):Rust 现代 COFF loader,crate 名 coffee-ldr
    # 上游 lib.rs 用 #![feature(c_variadic/core_intrinsics)],stable 编不过,需 nightly
    if ! have coffee-ldr; then
        export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
        . /opt/cargo/env 2>/dev/null || true
        export PATH="$PATH:/opt/cargo/bin"
        rustup toolchain install nightly --profile minimal >/dev/null 2>&1 || true
        cargo +nightly install coffee-ldr --locked \
            || cargo +nightly install --git "${gh}/hakaioffsec/coffee" --locked \
            || echo "coffee 失败(nightly 亦不过则上游问题,留档)"
        [ -e /opt/cargo/bin/coffee-ldr ] && ln -sf /opt/cargo/bin/coffee-ldr /usr/local/bin/coffee-ldr
        [ -e "$HOME/.cargo/bin/coffee-ldr" ] && ln -sf "$HOME/.cargo/bin/coffee-ldr" /usr/local/bin/coffee-ldr
    fi
    have coffee-ldr && echo "coffee-ldr 就绪" || echo "coffee-ldr 未装上(BOF 运行还有 bof-launcher 与 mingw/wine 路径)"
    # bof-launcher(The-Z-Labs):Zig 写的 BOF 加载器;仓库钉 zig 0.15.2,
    # 系统 zig 0.16 可能编不过,失败则提示按仓库说明下 0.15.2
    if ! have bof-launcher; then
        # 仓库钉 zig 0.15.2,系统 0.16 编不过;下载 0.15.2 专用副本构建
        local z152=/opt/zig-0.15.2
        if [ ! -x "$z152/zig" ]; then
            local za; case "$(dpkg --print-architecture)" in amd64) za=x86_64;; arm64) za=aarch64;; esac
            curl -fSL "https://ziglang.org/download/0.15.2/zig-${za}-linux-0.15.2.tar.xz" -o /tmp/zig152.tar.xz \
                && mkdir -p "$z152" && tar -C "$z152" -xJf /tmp/zig152.tar.xz --strip-components=1 && rm /tmp/zig152.tar.xz
        fi
        rm -rf /tmp/bof-launcher && git clone --depth 1 "${gh}/The-Z-Labs/bof-launcher" /tmp/bof-launcher
        if [ -x "$z152/zig" ] && ( cd /tmp/bof-launcher && "$z152/zig" build -Doptimize=ReleaseSafe ); then
            find /tmp/bof-launcher/zig-out -name bof-launcher -type f -exec install -m755 {} /usr/local/bin/bof-launcher \;
        else
            echo "bof-launcher 构建失败"
        fi
        rm -rf /tmp/bof-launcher
    fi
    have bof-launcher && echo "bof-launcher 就绪"
    # 参考目录
    install -d /opt/bofs
    curl -fsSL "${gh}/chryzsh/awesome-bof/raw/main/BOF-CATALOG.md" -o /opt/bofs/BOF-CATALOG.md \
        || echo "目录下载失败(不影响工具链)"
    x86_64-w64-mingw32-gcc --version | head -1
    [ -f /opt/COFFLoader/COFFLoader64.exe ] && echo "COFFLoader64.exe 在 /opt/COFFLoader(wine 用);Linux 直跑 BOF 用 coffee/bof-launcher"
    ls -d /opt/atomic-bofs >/dev/null 2>&1 && echo "atomic-bofs 在 /opt/atomic-bofs"
    echo "用法: x86_64-w64-mingw32-gcc -c bof.c -o bof.o; coffee run bof.o / bof-launcher run bof.o"
    true
}


# ---- Project Zero 沙箱攻击面分析工具(Windows 参考系) ----------------------
# NtObjectManager/NtApiDotNet 系:运行时强依赖 Windows(p/invoke ntdll),
# Linux 容器里主要价值是源码参考(syscall/结构文档级);尽力 dotnet 编译
install_pz() {
    log "Project Zero sandbox-attacksurface-analysis-tools"
    local gh="${GITHUB_MIRROR}https://github.com"
    if [ ! -d /opt/pz-sandbox-tools/.git ]; then
        rm -rf /opt/pz-sandbox-tools
        git clone --depth 1 "${gh}/googleprojectzero/sandbox-attacksurface-analysis-tools" /opt/pz-sandbox-tools
    fi
    if have dotnet; then
        ( cd /opt/pz-sandbox-tools && dotnet build sandbox-attacksurface-analysis-tools.sln -c Release ) >/dev/null 2>&1 \
            && echo "编译完成" || echo "编译失败(多目标旧 framework 常见;源码参考不受影响)"
    fi
    echo "参考: /opt/pz-sandbox-tools(NtObjectManager/NtApiDotNet 的 syscall 与对象定义)"

    # tyranid(James Forshaw)三件套,同属性:Windows 参考系,Linux 下源码价值为主
    # 方案依据 /tmp/pi-rs-dotnetfx-plan.md(grok 调研,noble mono/dotnet 实况)
    local r
    [ -d /opt/DotNetToJScript/.git ] || git clone --depth 1 "${gh}/tyranid/DotNetToJScript" /opt/DotNetToJScript
    [ -d /opt/windows-logical-eop-workshop/.git ] || git clone --depth 1 "${gh}/tyranid/windows-logical-eop-workshop" /opt/windows-logical-eop-workshop
    # oleviewdotnet 必须 --recurse-submodules(NtApiDotNet 是嵌套子模块),浅克隆会拉丢
    [ -d /opt/oleviewdotnet/.git ] || git clone --recurse-submodules "${gh}/tyranid/oleviewdotnet" /opt/oleviewdotnet

    # 用户裁定(2026-10-08):这些 .NET 项目只当参考代码,后渗透用到时再编;
    # noble 的 mono/xbuild/dotnet10 构建路径见 /tmp/pi-rs-dotnetfx-plan.md(grok 方案,留档)

    echo "EOP 教材: /opt/windows-logical-eop-workshop"
    true
}


# ---- nushell(结构化 shell) ------------------------------------------------
install_nu() {
    log "nushell (GitHub release 预编译)"
    local gh="${GITHUB_MIRROR}https://github.com"
    if ! have nu; then
        local ntag narc; case "$(dpkg --print-architecture)" in amd64) narc=x86_64;; arm64) narc=aarch64;; esac
        # 取 tag 用 git ls-remote:api.github.com 未认证限流 60 次/时(fresh 验证实证 403),
        # git 协议不受限流影响
        # GitHub 直连间歇性归零(与 tuna 抖动同期),重试 3 次取 tag
        local _try
        for _try in 1 2 3; do
            # pipefail:ls-remote 失败时整条管道非零,赋值即 set -e 退出;|| true 兜底
            ntag="$(git ls-remote --tags "${gh}/nushell" 2>/dev/null | grep -oE 'refs/tags/[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 | sed 's|refs/tags/||' || true)"
            if [ -n "$ntag" ]; then break; fi
            sleep 5
        done
        if [ -n "$ntag" ]; then
            local ntgz="nu-${ntag}-${narc}-unknown-linux-gnu.tar.gz"
            curl -fSL "${gh}/nushell/nushell/releases/download/${ntag}/${ntgz}" -o "/tmp/${ntgz}" \
                && tar -C /tmp -xzf "/tmp/${ntgz}" \
                && install -m755 "/tmp/nu-${ntag}-${narc}-unknown-linux-gnu/nu" /usr/local/bin/nu \
                && rm -rf "/tmp/${ntgz}" "/tmp/nu-${ntag}-${narc}-unknown-linux-gnu"
        else
            echo "nushell tag 获取失败(git ls-remote 不通?)"
        fi
    fi
    nu --version 2>/dev/null || echo "nu 未装上(下轮补)"
    true
}

# ---- 渗透测试运行时底线(智能体渗透测试运行时系统的底线件;claude 体检 P0 + grok 评审吸收) --
# 内网客户端批 + hashcat + Responder + frida 全链 + 离线固化接线
# 原则:全部 apt(tuna)或构建期钉版下载;离线期新装失败是显式报错,缓存必须进 /opt
install_pentest() {
    log "pentest apt 批(31 包,阿里云):内网客户端/远程/爆破/取证/移动/无线/签名"
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        dnsutils whois socat netcat-openbsd telnet ftp snmp proxychains4 \
        ldap-utils smbclient \
        default-mysql-client postgresql-client redis-tools sqlite3 \
        freerdp2-x11 sshuttle \
        hashcat pocl-opencl-icd ocl-icd-libopencl1 \
        hydra \
        android-tools-adb android-tools-fastboot \
        sleuthkit testdisk poppler-utils unar cabextract qpdf zbar-tools \
        hcxtools aircrack-ng steghide osslsigncode || true
    # sasquatch:binwalk 解非标准 SquashFS 的补丁版,源码构建
    if ! have sasquatch; then
        local gh="${GITHUB_MIRROR}https://github.com"
        rm -rf /tmp/sasquatch && git clone --depth 1 "${gh}/onekey-sec/sasquatch" /tmp/sasquatch \
            && ( cd /tmp/sasquatch && ./build.sh ) || echo "sasquatch 构建失败(不影响 binwalk 本体)"
        rm -rf /tmp/sasquatch
    fi
    hashcat -I 2>/dev/null | head -3 || echo "hashcat 装不上(查 pocl)"

    log "Responder(LLMNR/NBT-NS 毒化,内网测试起点)"
    local gh="${GITHUB_MIRROR}https://github.com"
    [ -d /opt/Responder/.git ] || git clone --depth 1 "${gh}/lgandx/Responder" /opt/Responder || echo "Responder 克隆失败"
    ls -d /opt/Responder >/dev/null 2>&1 && echo "Responder 在 /opt/Responder(运行:python3 /opt/Responder/Responder.py -I eth0)"

    log "frida 全链:客户端 + 全架构 frida-server(版本严格对齐)"
    . "$HOME/.local/bin/env" 2>/dev/null || true
    export UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools
    have frida || uv tool install frida-tools || echo "frida-tools 失败"
    if have frida; then
        local fv; fv="$(frida --version 2>/dev/null | tr -d ' ')"
        # frida-server 与客户端同版本;GitHub Releases 直下(可用 GITHUB_MIRROR),无 tuna
        local d="/opt/frida-server/${fv}"
        install -d "$d"
        # frida 发布资产命名:windows 带 .exe,其余裸名;windows-x86/arm64 多数版本不发,容错跳过
        local plat
        for plat in windows-x86_64 windows-arm64 \
                    android-arm64 android-arm android-x86_64 android-x86 \
                    linux-x86_64 linux-arm64; do
            local f
            case "$plat" in
                windows-*) f="frida-server-${fv}-${plat}.exe.xz" ;;
                *)         f="frida-server-${fv}-${plat}.xz" ;;
            esac
            [ -e "${d}/${f%.xz}" ] && continue
            curl -fSL --connect-timeout 10 --max-time 300 "${gh}/frida/frida/releases/download/${fv}/${f}" -o "/tmp/${f}" \
                && xz -d "/tmp/${f}" && mv "/tmp/${f%.xz}" "$d/" || echo "$plat server 下载失败(该版本可能未发布)"
        done
        ls "$d" | wc -l
    fi

    log "离线固化接线:nuclei 模板 / capa 规则 / 词表 / pwndbg gdbinit / 时区 locale"
    # nuclei 模板:在线 -update-templates 落家目录且失败容忍,离线静默坏;改钉 /opt
    [ -d /opt/nuclei-templates/.git ] || git clone --depth 1 "${gh}/projectdiscovery/nuclei-templates" /opt/nuclei-templates || echo "nuclei-templates 克隆失败"
    # 注意:set -e 下 a && b 链整体失败即退出,循环体必须 if 包裹
    for u in /root /home/ubuntu; do
        [ -d "$u" ] || continue
        if [ -e "$u/nuclei-templates" ] && [ ! -L "$u/nuclei-templates" ]; then
            # 已有真实目录(旧 update-templates 产物):挪开再链,不删内容
            mv "$u/nuclei-templates" "$u/nuclei-templates.bak" 2>/dev/null || true
        fi
        ln -sfn /opt/nuclei-templates "$u/nuclei-templates"
    done
    # nuclei wrapper:-duc 禁版本检查,离线期不卡更新
    if have nuclei && [ ! -e /usr/local/bin/nuclei.real ]; then
        local real; real="$(readlink -f "$(command -v nuclei)")"
        if [ "$real" != /usr/local/bin/nuclei ] && [ "$real" != /usr/local/bin/nuclei.real ]; then
            mv "$real" /usr/local/bin/nuclei.real
        fi
        printf '#!/bin/sh\nexec /usr/local/bin/nuclei.real -duc "$@"\n' > /usr/local/bin/nuclei
        chmod +x /usr/local/bin/nuclei
    fi
    # capa 规则接线:不指定时 capa 会自下载规则到 ~/.local/share/capa,离线报晦涩错
    if have capa && [ ! -e /usr/local/bin/capa.real ]; then
        local capa_bin; capa_bin="$(find /opt/capa -name capa -type f 2>/dev/null | head -1)"
        if [ -n "$capa_bin" ]; then
            ln -sf "$capa_bin" /usr/local/bin/capa.real
            printf '#!/bin/sh\nexec /usr/local/bin/capa.real -r /opt/capa-rules "$@"\n' > /usr/local/bin/capa
            chmod +x /usr/local/bin/capa
        else
            echo "capa 二进制未找到(p0 组先跑)"
        fi
    fi
    # 词表约定:/usr/share/wordlists 软链入口 + rockyou 解包(chmod 644 供 hashcat/john)
    install -d /usr/share/wordlists
    ln -sfn /opt/SecLists /usr/share/wordlists/SecLists
    if [ ! -f /usr/share/wordlists/rockyou.txt ]; then
        local ry; ry="$(find /opt/SecLists/Passwords -name 'rockyou.txt*' 2>/dev/null | head -1)"
        if [ -n "$ry" ]; then
            case "$ry" in
                *.tar.gz|*.tgz) tar -C /usr/share/wordlists -xzf "$ry" rockyou.txt 2>/dev/null || true ;;
                *) cp "$ry" /usr/share/wordlists/rockyou.txt || true ;;
            esac
            chmod 644 /usr/share/wordlists/rockyou.txt 2>/dev/null || true
        fi
    fi
    ls -l /usr/share/wordlists/rockyou.txt 2>/dev/null || echo "rockyou 未解出(SecLists 路径变了再查)"
    # pwndbg 系统 gdbinit:不接线则 gdb 静默降级为裸 gdb
    local gdbinit_py; gdbinit_py="$(find /opt/uv-tools -name gdbinit.py -path '*pwndbg*' 2>/dev/null | head -1)"
    if [ -n "$gdbinit_py" ]; then
        cat > /etc/gdb/gdbinit <<EOF
source ${gdbinit_py}
set auto-load safe-path /
set history save on
set pagination off
EOF
        gdb --batch -ex quit 2>&1 | grep -qi pwndbg && echo "pwndbg gdbinit 冒烟通过" || echo "!! pwndbg 冒烟未见 banner,查 gdbinit"
    else
        echo "pwndbg gdbinit.py 未找到(p0 组先跑)"
    fi
    # 时区与 locale:时区钉上海;生成 zh_CN.UTF-8 但默认 LANG 保持 en_US(工具输出可解析性)
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo "Asia/Shanghai" > /etc/timezone
    apt-get install -y --no-install-recommends locales || true
    sed -i 's/^# *\(zh_CN.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
    locale-gen 2>/dev/null || true
    # offline 快失败函数:离线期新依赖解析默认长超时挂起,半静默最伤现场
    cat > /etc/profile.d/offline.sh <<'EOF'
offline() {
    export GOPROXY=off CARGO_NET_OFFLINE=true NPM_CONFIG_PREFER_OFFLINE=true UV_OFFLINE=1
    echo "offline mode: go/cargo/npm/uv 新依赖将立即失败而不是挂起"
}
EOF
    timedatectl show -p Timezone 2>/dev/null || cat /etc/timezone
    locale -a 2>/dev/null | grep -i zh_CN | head -2
    true
}


# ---- 渗透测试工具增补(claude 体检 P1:AD 横向 / Web / 密码 / 移动 / 云) -------
# 原则:能 uv tool 走 tuna 就走 uv tool;git 克隆钉 /opt;gem 走 ruby-china;Release 钉版
install_red() {
    log "AD 横向与 Web 工具(uv tool 走 tuna:tuna 有轮子即成功)"
    . "$HOME/.local/bin/env" 2>/dev/null || true
    export PATH="$PATH:/usr/local/bin:/opt/go/bin"
    export UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools
    export GOPATH=/opt/go GOPROXY GOSUMDB
    local t
    for t in kerbrute wafw00f arjun ghauri bloodhound-python Coercer mitm6 objection apkleaks; do
        have "$t" 2>/dev/null || VIRTUAL_ENV= uv tool install "$t" >/dev/null 2>&1 \
            && echo "$t 已装" || echo "$t 失败(留待排查)"
    done
    # 命名差异:kerbrute/Coercer 等二进名与包名可能不同,统一链接检查
    for t in kerbrute wafw00f arjun ghauri bloodhound-python coercer Coercer mitm6 objection apkleaks; do
        [ -e "/opt/uv-tools/$t/bin/$t" ] && ln -sf "/opt/uv-tools/$t/bin/$t" "/usr/local/bin/$t" 2>/dev/null
    done

    log "git 克隆批(钉 /opt,依赖进 re-venv 尽力)"
    local gh="${GITHUB_MIRROR}https://github.com"
    local r
    for r in mubix/jwt-tool sensepost/LinkFinder dirkjanm/krbrelayx CarHaeck/enum4linux-ng; do
        local d="/opt/$(basename "$r")"
        [ -d "$d/.git" ] || git clone --depth 1 "${gh}/${r}" "$d" || echo "$r 克隆失败"
    done
    # LinkFinder / enum4linux-ng 的 python 依赖进 re-venv
    [ -x "$RE_VENV/bin/python" ] || uv venv "$RE_VENV"
    [ -f /opt/LinkFinder/requirements.txt ] \
        && VIRTUAL_ENV="$RE_VENV" uv pip install -r /opt/LinkFinder/requirements.txt >/dev/null 2>&1 || true
    [ -f /opt/enum4linux-ng/requirements.txt ] \
        && VIRTUAL_ENV="$RE_VENV" uv pip install -r /opt/enum4linux-ng/requirements.txt >/dev/null 2>&1 || true
    for b in jwt-tool linkfinder enum4linux-ng krbrelayx; do
        [ -e "$RE_VENV/bin/$b" ] && ln -sf "$RE_VENV/bin/$b" "/usr/local/bin/$b" 2>/dev/null
    done

    log "Ruby 生态引入(gems.ruby-china;解锁 CeWL)"
    apt-get update -qq
    apt-get install -y --no-install-recommends ruby-full || true
    if have gem; then
        gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ >/dev/null 2>&1 || true
        have cewl || gem install cewl --no-document >/dev/null 2>&1 && echo "cewl 已装" || echo "cewl 失败"
    fi

    log "CyberChef(离线瑞士军刀,Release zip 钉 /opt)"
    if [ ! -d /opt/cyberchef ]; then
        local gh2="${GITHUB_MIRROR}https://github.com"
        # api.github.com 限流改用 git ls-remote(nushell 同款)
        local ctag; ctag="$(git ls-remote --tags "${gh2}/CyberChef" 2>/dev/null | grep -oE 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 | sed 's|refs/tags/||' || true)"
        if [ -n "$ctag" ]; then
            local cz="CyberChef_${ctag#v}.zip"
            curl -fSL "${gh2}/gchq/CyberChef/releases/download/${ctag}/${cz}" -o "/tmp/${cz}" \
                && install -d /opt/cyberchef && unzip -q -o "/tmp/${cz}" -d /opt/cyberchef && rm "/tmp/${cz}" \
                && echo "CyberChef 就位: /opt/cyberchef(用 python3 -m http.server 起本地页)" \
                || echo "CyberChef 下载失败"
        fi
    fi

    log "云与内网:kubectl(aliyun)/trivy+db 烘焙/awscli v2"
    # kubectl:阿里云 kubernetes-release 镜像
    if ! have kubectl; then
        # 国内无 kubectl 二进制镜像(阿里云/ustc/华为实测均无 release 布局);直连官方 CDN 钉版
        local karch="amd64"; [ "$(dpkg --print-architecture)" = arm64 ] && karch="arm64"
        curl -fSL --retry 3 "https://dl.k8s.io/release/v1.32.0/bin/linux/${karch}/kubectl" -o /usr/local/bin/kubectl 2>/dev/null \
            && chmod +x /usr/local/bin/kubectl || echo "kubectl 失败(dl.k8s.io 直连不通,有网阶段重试)"
    fi
    # trivy:GitHub .deb + 构建期烘 db 到 /opt/trivy-db(离线期 --skip-db-update)
    if ! have trivy; then
        local tarch="64bit"; [ "$(dpkg --print-architecture)" = arm64 ] && tarch="ARM64"
        local tv; tv="$(curl -fsSL https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
        if [ -n "$tv" ]; then
            local tdeb="trivy_${tv#v}_Linux-${tarch}.deb"
            curl -fSL "${GITHUB_MIRROR}https://github.com/aquasecurity/trivy/releases/download/${tv}/${tdeb}" -o "/tmp/${tdeb}" \
                && dpkg -i "/tmp/${tdeb}" && rm "/tmp/${tdeb}" || echo "trivy deb 失败"
        fi
    fi
    if have trivy; then
        export TRIVY_CACHE_DIR=/opt/trivy-db
        install -d /opt/trivy-db
        trivy image --download-db-only >/dev/null 2>&1 || echo "trivy db 烘焙失败(离线期将无法扫描)"
        cat > /etc/profile.d/trivy.sh <<'EOF'
export TRIVY_CACHE_DIR=/opt/trivy-db
alias trivy='trivy --skip-db-update'
EOF
    fi
    # awscli v2:官方 zip 安装器(无国内镜像,构建期直连)
    if ! have aws; then
        curl -fSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip 2>/dev/null \
            && unzip -q -o /tmp/awscliv2.zip -d /tmp && /tmp/aws/install --update >/dev/null 2>&1 || /tmp/aws/install >/dev/null 2>&1 \
            && rm -rf /tmp/awscliv2.zip /tmp/aws || echo "awscli v2 失败(国内直连 awscli.amazonaws.com 不通时可跳过)"
    fi
    true
}


TOOLS_ALL=(fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz nu pentest red)
run_category TOOLS_ALL "$@"

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
    apt-get install -y --no-install-recommends git jq shellcheck just tmux || true
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
    # findomain 依赖多常编不过,要用时走 https://github.com/Findomain/Findomain/releases 预编译
    for b in rustscan feroxbuster; do
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


# ---- 代理跳板(pivot):隧道/反向代理工具 + 库预热 --------------------------
install_pivot() {
    log "代理跳板: gost/frp/wstunnel/rathole/bore (go install + cargo,国内源)"
    export PATH="$PATH:/usr/local/go/bin:/root/go/bin:/root/.cargo/bin"
    export GOPROXY GOSUMDB
    . "$HOME/.cargo/env" 2>/dev/null || true
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
    local gobin; gobin="$(go env GOPATH)/bin"
    for b in gost frps frpc; do
        [ -e "$gobin/$b" ] && ln -sf "$gobin/$b" "/usr/local/bin/$b"
    done
    for b in wstunnel rathole bore; do
        [ -e "$HOME/.cargo/bin/$b" ] && ln -sf "$HOME/.cargo/bin/$b" "/usr/local/bin/$b"
    done
    for b in gost frps frpc wstunnel rathole bore; do have "$b" && printf '  %s\n' "$b"; done
    true
}


# ---- P0 补齐(grok 业界调研;Kali/REMnux/FLARE 重叠缺口) ------------------
# 分三步:apt 批(全 TUNA)/ re-venv pip 批(TUNA PyPI)/ GitHub 钉版批
install_p0() {
    log "P0 apt 批(21 包,TUNA):多架构调试/pwn/流量/分诊/AD/口令"
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        gdb-multiarch qemu-user-static \
        python3-pwntools python3-ropgadget checksec patchelf nasm xxd squashfs-tools \
        nmap sqlmap tcpdump tshark mitmproxy python3-scapy \
        upx-ucl 7zip libimage-exiftool-perl ssdeep python3-impacket \
        john hashid

    log "P0 re-venv pip 批(TUNA PyPI):FLOSS/oletools/netexec"
    [ -x "$RE_VENV/bin/pip" ] || python3 -m venv "$RE_VENV"
    "$RE_VENV/bin/pip" install -U pip >/dev/null
    # netexec 在 tuna 索引里可能缺,PyPI 装不上退回 git 源
    "$RE_VENV/bin/pip" install flare-floss oletools \
        || "$RE_VENV/bin/pip" install --no-cache-dir flare-floss oletools
    "$RE_VENV/bin/pip" install netexec \
        || "$RE_VENV/bin/pip" install "git+https://github.com/Pennyw0rth/NetExec"
    # venv 里的 CLI 进默认 PATH(评审 F6):pd/secgo 约定是 /usr/local/bin
    for b in floss olevba oleid netexec; do
        [ -e "$RE_VENV/bin/$b" ] && ln -sf "$RE_VENV/bin/$b" "/usr/local/bin/$b"
    done

    log "P0 GitHub 批(钉版,无国内镜像):pwndbg/jadx/apktool/capa/SecLists/YARA规则/pdf工具"
    local gh="${GITHUB_MIRROR}https://github.com"
    # pwndbg: PyPI 有官方包,比 deb 简单且可钉版
    # pwndbg:tuna/PyPI 无包;uv tool 从 git 源装(未钉 rev,上游 dev 分支会漂,见 ROADMAP)
    have pwndbg || uv tool install "git+${gh}/pwndbg/pwndbg" || echo "pwndbg 失败"
    [ -e "$HOME/.local/bin/pwndbg" ] && ln -sf "$HOME/.local/bin/pwndbg" /usr/local/bin/pwndbg
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


# ---- C2 框架(sliver/merlin/empire/covenant) -----------------------------
# 只装默认骨架;监听/证书配置属部署面,不在安装器里做
install_c2() {
    log "C2: sliver + merlin + empire + covenant"
    local gh="${GITHUB_MIRROR}https://github.com"
    export PATH="$PATH:/usr/local/go/bin:/root/go/bin:/usr/local/bin"

    # sliver:GitHub Release 预编译,按资产名匹配 linux 包
    if ! have sliver-server; then
        curl -fsSL "https://api.github.com/repos/bishopfox/sliver/releases/latest" \
            | python3 -c "
import json,sys,urllib.request,os
rel=json.load(sys.stdin)
mirror=os.environ.get('GITHUB_MIRROR','')
for want in ('sliver-server_linux','sliver-client_linux'):
    for a in rel['assets']:
        n=a['name']
        if want in n and not any(x in n for x in ('windows','darwin','mac','.sig','.minisig','.pem','SHA256','sbom')):
            print(mirror+a['browser_download_url']+' '+want)
" | while read -r url name; do
            curl -fSL "$url" -o "/tmp/${name}.bin" && install -m755 "/tmp/${name}.bin" "/usr/local/bin/${name}" && rm "/tmp/${name}.bin"
        done
    fi
    have sliver-server && sliver-server version 2>/dev/null | head -1 || echo "sliver-server 装失败(可手动下 release)"

    # merlin:latest tag(v1.5.1)没有 cmd/merlinserver,v2 在 master
    have merlinserver || go install github.com/Ne0nd0g/merlin/cmd/merlinserver@master \
        && ln -sf /root/go/bin/merlinserver /usr/local/bin/merlinserver || echo "merlinserver 失败"

    # empire:Python 重型框架,装依赖交互多;克隆钉版,首次启用走 /opt/Empire 的 install
    if [ ! -d /opt/Empire/.git ]; then
        rm -rf /opt/Empire && git clone --depth 1 "${gh}/BC-SECURITY/Empire" /opt/Empire
    fi
    echo "Empire 已克隆到 /opt/Empire;首次启用: cd /opt/Empire && ./ps-empire install (交互,依赖较多)"

    # covenant:.NET C2(项目已归档,可能编不过新 dotnet);克隆并尽力 build
    if [ ! -d /opt/Covenant/.git ]; then
        rm -rf /opt/Covenant && git clone --depth 1 "${gh}/cobbr/Covenant" /opt/Covenant
    fi
    if have dotnet && [ ! -f /opt/Covenant/Covenant/bin/Release/net*/Covenant ]; then
        ( cd /opt/Covenant/Covenant && dotnet build -c Release ) >/dev/null 2>&1 \
            && echo "covenant 编译完成" || echo "covenant 编译失败(项目归档,旧 target framework;可用 dotnet 10 需自行迁移)"
    fi
    # ysoserial:Java 反序列化 payload 生成;maven 依赖已走阿里云(settings.xml)
    if ! have ysoserial; then
        rm -rf /tmp/ysoserial && git clone --depth 1 "${gh}/frohoff/ysoserial" /tmp/ysoserial
        # 项目钉 Java 1.6,javac 21 拒编;pom 升到 1.8 再打包
        sed -i 's/1\.6/1.8/g' /tmp/ysoserial/pom.xml
        if ( cd /tmp/ysoserial && mvn -q package -DskipTests ); then
            install -d /opt/ysoserial
            cp /tmp/ysoserial/target/ysoserial-*.jar /opt/ysoserial/ysoserial.jar
            printf '#!/bin/sh\nexec java -jar /opt/ysoserial/ysoserial.jar "$@"\n' > /usr/local/bin/ysoserial
            chmod +x /usr/local/bin/ysoserial
        else
            echo "ysoserial 打包失败(mvn package;查依赖下载)"
        fi
        rm -rf /tmp/ysoserial
    fi
    have ysoserial && echo "ysoserial 就绪" || true

    # ysoserial.net:.NET Framework v4.7.2 老式 csproj,dotnet 10 编不了;
    # 下 release 预编译 + mono 运行
    if ! have ysoserial.net; then
        apt-get install -y --no-install-recommends mono-runtime
        local ynurl; ynurl="$(curl -fsSL "https://api.github.com/repos/pwntester/ysoserial.net/releases/latest" \
            | python3 -c "
import json,sys,os
rel=json.load(sys.stdin)
mirror=os.environ.get('GITHUB_MIRROR','')
for a in rel['assets']:
    if a['name'].endswith('.zip'):
        print(mirror+a['browser_download_url']); break
")"
        if [ -n "$ynurl" ]; then
            curl -fSL "$ynurl" -o /tmp/ysoserialnet.zip
            rm -rf /opt/ysoserial.net && mkdir -p /opt/ysoserial.net
            unzip -q /tmp/ysoserialnet.zip -d /opt/ysoserial.net && rm /tmp/ysoserialnet.zip
            local ynexe; ynexe="$(find /opt/ysoserial.net -name 'ysoserial*.exe' | head -1)"
            if [ -n "$ynexe" ]; then
                printf '#!/bin/sh\nexec mono %s "$@"\n' "$ynexe" > /usr/local/bin/ysoserial.net
                chmod +x /usr/local/bin/ysoserial.net
            fi
        fi
    fi
    have ysoserial.net && ysoserial.net --help 2>/dev/null | head -1 || echo "ysoserial.net 装失败"
    true
}


# ---- BOF(Beacon Object File)工具链:交叉编译 + 脱离 C2 运行 ----------------
install_bof() {
    log "BOF 工具链: mingw-w64 + COFFLoader + atomic-bofs + 目录"
    local gh="${GITHUB_MIRROR}https://github.com"
    apt-get update -qq
    apt-get install -y --no-install-recommends mingw-w64
    # COFFLoader:先编 Linux 版(gcc 直编,可跑独立 BOF);mingw 目标也顺带验证编译器
    if ! have coffloader; then
        rm -rf /tmp/coffloader && git clone --depth 1 "${gh}/trustedsec/COFFLoader" /tmp/coffloader
        ( cd /tmp/coffloader && gcc -Wall -DCOFF_STANDALONE beacon_compatibility.c COFFLoader.c -o /usr/local/bin/coffloader ) \
            || echo "coffloader linux 构建失败"
        rm -rf /tmp/coffloader
    fi
    # atomic-bofs:rasta-mouse 的 COFF 独立运行 harness(带打包参数)
    [ -d /opt/atomic-bofs/.git ] || git clone --depth 1 "${gh}/rasta-mouse/atomic-bofs" /opt/atomic-bofs
    # Coffee(hakaioffsec):Rust 现代 COFF loader,crate 名 coffee-ldr
    if ! have coffee; then
        . "$HOME/.cargo/env" 2>/dev/null || true
        export PATH="$PATH:/root/.cargo/bin"
        cargo install coffee-ldr --locked \
            || cargo install --git "${gh}/hakaioffsec/coffee" --locked \
            || echo "coffee 失败"
        [ -e "$HOME/.cargo/bin/coffee" ] && ln -sf "$HOME/.cargo/bin/coffee" /usr/local/bin/coffee
    fi
    have coffee && coffee --help 2>/dev/null | head -1
    # 参考目录
    install -d /opt/bofs
    curl -fsSL "${gh}/chryzsh/awesome-bof/raw/main/BOF-CATALOG.md" -o /opt/bofs/BOF-CATALOG.md \
        || echo "目录下载失败(不影响工具链)"
    x86_64-w64-mingw32-gcc --version | head -1
    have coffloader && echo "coffloader 就绪"
    ls -d /opt/atomic-bofs >/dev/null 2>&1 && echo "atomic-bofs 在 /opt/atomic-bofs"
    echo "用法: x86_64-w64-mingw32-gcc -c bof.c -o bof.o; coffloader go bof.o <args...>"
    true
}

TOOLS_ALL=(fd astgrep cli ghidra re pd secgo secrust pivot p0 c2 bof)
run_category TOOLS_ALL "$@"

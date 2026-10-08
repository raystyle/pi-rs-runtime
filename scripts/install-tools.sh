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
    dnsx/v2/cmd/dnsx
    naabu/v2/cmd/naabu
    httpx/v2/cmd/httpx
    nuclei/v3/cmd/nuclei
    katana/cmd/katana
    uncover/cmd/uncover
    cloudlist/cmd/cloudlist
    notify/cmd/notify
    interactsh/cmd/interactsh-client
    chaos-client/cmd/chaos-client
    mapcidr/cmd/mapcidr
    asnmap/cmd/asnmap
    tlsx/cmd/tlsx
    proxify/cmd/proxify
    simplehttpserver/cmd/simplehttpserver
    shuffledns/cmd/shuffledns
    crlfuzz/cmd/crlfuzz
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
    gitleaks/v8@github.com/gitleaks
    assetfinder@github.com/tomnomnom
    httprobe@github.com/tomnomnom
    qsreplace@github.com/tomnomnom
    waybackurls@github.com/tomnomnom
    gau/v2/cmd/gau@github.com/lc
    gospider@github.com/jaeles-project
    gowitness@github.com/sensepost
    AzureHound/v2@github.com/BloodHoundAD
)

install_secgo() {
    log "Go 安全 CLI (go install @${SECGO_VERSION:-latest},经 $GOPROXY)"
    export PATH="$PATH:/usr/local/go/bin:/root/go/bin"
    export GOPROXY GOSUMDB
    # shellcheck disable=SC2206
    local tools=( ${SECGO_TOOLS:-} ); [ ${#tools[@]} -eq 0 ] && tools=("${SECGO_TOOLS_DEFAULT[@]}")
    local spec path repo bin
    for spec in "${tools[@]}"; do
        path="${spec%@*}"; repo="${spec#*@}"
        bin="${path##*/}"; [ "$bin" = "..." ] && bin="${path%%/*}"
        if have "$bin"; then echo "$bin 已装,跳过"; continue; fi
        echo "--- go install $repo/$path@${SECGO_VERSION:-latest}"
        go install "${repo}/${path}@${SECGO_VERSION:-latest}" || echo "!! $bin 编译失败(留待排查)"
    done
    echo "已装:"; for spec in "${tools[@]}"; do path="${spec%@*}"; bin="${path##*/}"; [ "$bin" = "..." ] && bin="${path%%/*}"; command -v "$bin" >/dev/null && printf '  %s\n' "$bin"; done
}

install_secrust() {
    log "rustscan / feroxbuster / findomain (cargo,经 tuna crates)"
    . "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$PATH:/root/.cargo/bin"
    have rustscan    || cargo install rustscan --locked
    have feroxbuster || cargo install feroxbuster --locked
    # findomain 依赖多,cargo 失败则提示走 GitHub Releases 预编译
    have findomain   || cargo install findomain --locked || echo "findomain 编译失败,改走 https://github.com/Findomain/Findomain/releases 预编译"
    for b in rustscan feroxbuster findomain; do have "$b" && "$b" --version 2>/dev/null | head -1; done
}

TOOLS_ALL=(fd astgrep cli pd secgo secrust)
run_category TOOLS_ALL "$@"

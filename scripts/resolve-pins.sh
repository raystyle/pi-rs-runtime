#!/usr/bin/env bash
# 版本钉升级器:从各生态索引/远端实解析当前最新,重写 lib/pins.sh。
# 钉版纪律(用户裁定):安装脚本只消费 pins.sh;升级 = 跑本脚本 + 审 diff + 增量发布。
# 用法:
#   ./scripts/resolve-pins.sh          # 全量重解析并覆写 lib/pins.sh
#   ./scripts/resolve-pins.sh --check  # 只打印会变的行,不写文件(审升级面)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PINS="$HERE/lib/pins.sh"
GH_MIRROR="${GITHUB_MIRROR:-https://proxy.ohmygh.com/}"
GOPROXY_API="${GOPROXY_API:-https://goproxy.cn}"
CRATES_SPARSE="${CRATES_SPARSE:-https://rsproxy.cn/index}"
PYPI_SIMPLE="${PYPI_SIMPLE:-https://mirrors.aliyun.com/pypi/simple}"
GEM_API="${GEM_API:-https://gems.ruby-china.com/api/v1/versions}"
NUGET_FLAT="${NUGET_FLAT:-https://repo.huaweicloud.com/artifactory/api/nuget/v3/nuget-remote}"   # 服务索引 PackageBaseAddress 实证路径
ADOPTIUM_MIRROR="${ADOPTIUM_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/Adoptium}"

say() { printf '%s\n' "$*" >&2; }

# ---- go 模块:goproxy /@latest 先行;失败回退仓 tag;无 tag 仓回退 HEAD sha ----
# (goproxy.cn 对冷门模块「not found: temporarily unavailable」实证;go install @sha 合法)
go_latest() { # go_latest <module/path> → vX.Y.Z 或 40 位 sha
    local esc="$1" try v=""
    esc="$(printf '%s' "$esc" | sed 's/\([A-Z]\)/!\l\1/g')"
    for try in 1 2; do
        v="$(curl -fsSL -m 12 "$GOPROXY_API/$esc/@latest" 2>/dev/null | grep -o '"Version": *"[^"]*"' | cut -d'"' -f4 || true)"
        [ -n "$v" ] && { printf '%s' "$v"; return; } || sleep 1
    done
    case "$esc" in
        golang.org/x/tools/gopls) git_latest_tag golang/tools "gopls/" ;;
        github.com/*) local repo; repo="$(echo "$esc" | cut -d/ -f2-3)"
            v="$(git_latest_tag "$repo")"; [ -n "$v" ] || v="$(git_head "$repo")"
            printf '%s' "$v" ;;
        *) : ;;
    esac
}

# ---- crates:sparse 索引最后一行 JSON 的 vers --------------------------------
crate_latest() { # crate_latest <name>
    local n="$1" len path
    len=${#n}
    if [ "$len" -eq 1 ]; then path="1/$n"
    elif [ "$len" -eq 2 ]; then path="2/$n"
    elif [ "$len" -eq 3 ]; then path="3/${n:0:1}/$n"
    else path="${n:0:2}/${n:2:2}/$n"; fi
    curl -fsSL -m 15 "$CRATES_SPARSE/$path" 2>/dev/null | tail -1 | grep -o '"vers":"[^"]*"' | head -1 | cut -d'"' -f4 || true
}

# ---- PyPI:pypi.org JSON API(aliyun simple 文件名连字符/下划线不统一,实证) ----
pypi_latest() {
    local try v=""
    for try in 1 2 3; do
        v="$(curl -fsSL -m 15 "https://pypi.org/pypi/$1/json" 2>/dev/null | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4 || true)"
        [ -n "$v" ] && break || sleep 2
    done
    printf '%s' "$v"
}

# ---- gem:rubygems.org 官方 API(ruby-china 是文件镜像无 API,实证) -------------
gem_latest() { curl -fsSL -m 15 "https://rubygems.org/api/v1/versions/$1/latest.json" 2>/dev/null | grep -o '"version": *"[^"]*"' | cut -d'"' -f4 || true; }

# ---- git 仓:HEAD sha --------------------------------------------------------
git_head() {
    local try v=""
    for try in 1 2 3; do
        v="$(git ls-remote "${GH_MIRROR}https://github.com/$1" HEAD 2>/dev/null | cut -c1-40 || true)"
        [ -n "$v" ] && break || sleep 2
    done
    printf '%s' "$v"
}

# ---- git 仓:latest tag(原生形态返回;排序键剥前缀与 v,防 v 系/裸系混排错乱,nushell 实证) --
git_latest_tag() { # git_latest_tag <owner/repo> [tag前缀]
    local repo="$1" prefix="${2:-}" try v=""
    for try in 1 2 3; do
        v="$(git ls-remote --tags --refs "${GH_MIRROR}https://github.com/$repo" 2>/dev/null \
            | awk -F/ '{print $NF}' | grep -E "^${prefix}v?[0-9]+\.[0-9]+\.[0-9]+" \
            | while read -r tag; do local k="${tag#$prefix}"; printf '%s %s\n' "${k#v}" "$tag"; done \
            | sort -uV -k1,1 | tail -1 | cut -d' ' -f2 || true)"
        [ -n "$v" ] && break || sleep 2
    done
    printf '%s' "${v#$prefix}"   # 返回值剥子目录前缀(gopls/v0.x→v0.x),保留原生 v
}

# ---- npm:npmmirror 包 latest(scoped 包名直接进路径) --------------------------
npm_latest() { curl -fsSL -m 15 "https://registry.npmmirror.com/$1/latest" 2>/dev/null | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4 || true; }

# ---- PSGallery:官方 v2 API(IsLatestVersion 过滤) ----------------------------
psgallery_latest() {
    curl -fsSL -m 20 "https://www.powershellgallery.com/api/v2/FindPackagesById()?\$filter=IsLatestVersion%20eq%20true&\$top=1&id='$1'" 2>/dev/null \
        | grep -oE '<d:Version>[^<]+' | head -1 | sed 's/<d:Version>//' || true
}

# ---- nuget flat:v3 flatcontainer(地址从服务索引 PackageBaseAddress 取,华为实证路径) ----
nuget_latest() { curl -fsSL -m 15 "${NUGET_FLAT:-https://repo.huaweicloud.com/artifactory/api/nuget/v3/nuget-remote}/$1/index.json" 2>/dev/null | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"' || true; }

# ---- temurin:tuna Adoptium 目录列表 ------------------------------------------
temurin_latest() { # temurin_latest <major> → 目录里的版本串(如 25.0.4.1_9)
    local major="$1"
    curl -fsSL -m 15 "$ADOPTIUM_MIRROR/$major/jdk/x64/linux/" 2>/dev/null \
        | grep -o "OpenJDK${major}U-jdk_x64_linux_hotspot_[0-9a-zA-Z._]*\.tar\.gz" | sort -uV | tail -1 \
        | sed "s/OpenJDK${major}U-jdk_x64_linux_hotspot_//;s/\.tar\.gz//" || true
}
# ---- 清单与生成 -------------------------------------------------------------
# 清单与消费点对账:新增 go install/cargo install/uv tool/git clone 消费点时,
# 必须同步这里的清单(否则该点缺钉直接失败)。

GO_SPECS=(
    # cli/compilers/libcache
    github.com/mikefarah/yq/v4 github.com/cli/cli/v2/cmd/gh
    github.com/go-delve/delve/cmd/dlv golang.org/x/tools/gopls github.com/golangci/golangci-lint/cmd/golangci-lint
    github.com/dominicbreuker/pspy github.com/tc-hib/go-winres
    github.com/go-gost/gost/cmd/gost
    # pd 全家桶(github.com/projectdiscovery/ 前缀)
    github.com/projectdiscovery/subfinder/v2/cmd/subfinder github.com/projectdiscovery/dnsx/cmd/dnsx
    github.com/projectdiscovery/naabu/v2/cmd/naabu github.com/projectdiscovery/httpx/cmd/httpx
    github.com/projectdiscovery/nuclei/v3/cmd/nuclei github.com/projectdiscovery/katana/cmd/katana
    github.com/projectdiscovery/uncover/cmd/uncover github.com/projectdiscovery/cloudlist/cmd/cloudlist
    github.com/projectdiscovery/notify/cmd/notify github.com/projectdiscovery/interactsh/cmd/interactsh-client
    github.com/projectdiscovery/chaos-client/cmd/chaos github.com/projectdiscovery/mapcidr/cmd/mapcidr
    github.com/projectdiscovery/asnmap/cmd/asnmap github.com/projectdiscovery/tlsx/cmd/tlsx
    github.com/projectdiscovery/proxify/cmd/proxify github.com/projectdiscovery/simplehttpserver/cmd/simplehttpserver
    github.com/projectdiscovery/shuffledns/cmd/shuffledns github.com/projectdiscovery/pdtm/cmd/pdtm
    github.com/projectdiscovery/urlfinder/cmd/urlfinder github.com/projectdiscovery/cvemap/cmd/cvemap
    # secgo(完整 install spec 作键)
    github.com/ffuf/ffuf/v2 github.com/OJ/gobuster/v3 github.com/hahwul/dalfox/v2
    github.com/owasp-amass/amass/v4 github.com/jpillora/chisel github.com/zricethezav/gitleaks/v8
    github.com/tomnomnom/assetfinder github.com/tomnomnom/httprobe github.com/tomnomnom/qsreplace
    github.com/tomnomnom/waybackurls github.com/lc/gau/v2 github.com/jaeles-project/gospider
    github.com/sensepost/gowitness github.com/bloodhoundad/azurehound/v2
    github.com/praetorian-inc/nerva/cmd/nerva github.com/praetorian-inc/brutus/cmd/brutus
    github.com/praetorian-inc/aurelian
)
# spec → 模块路径(截到版本目录或仓名):/@latest 要模块路径不要包路径
go_mod_of() {
    local s="$1"
    s="${s%/cmd/*}"            # .../cmd/<bin> → 截掉
    s="${s%/...}"
    echo "$s"
}

CRATES=(rust-script cargo-zigbuild cargo-audit fnm ast-grep just rustscan feroxbuster bore-cli rathole coffee-ldr)

PYPI_PKGS=(
    impacket kerbrute wafw00f arjun bloodhound-python coercer mitm6 objection apkleaks
    certipy-ad bloodyad bofhound semgrep bloodhound-ce frida-tools ruff
    flare-floss oletools
    capstone keystone-engine unicorn lief yara-python
    polars pyarrow chdb duckdb ldap3 dnspython pyasn1
    pycryptodome cryptography gmpy2 sympy z3-solver construct pefile pyelftools dnfile pypykatz
    malduck volatility3 r2pipe httpx beautifulsoup4 lxml pyjwt dpkt xortool
)

GEMS=(evil-winrm nokogiri mime mime-types mini_exiftool rubyzip)

# npm 全局件与 js-lab 固化件
NPM_PKGS=(typescript prettier eslint dotnetjs
    node-forge pkijs asn1js pvtsutils pvutils crypto-js jsonwebtoken
    @babel/parser @babel/traverse @babel/generator @babel/types
    webcrack cheerio fast-xml-parser ws express jszip sql.js
    protobufjs js-yaml iconv-lite libsodium-wrappers pdf-lib postject)

# PSGallery 固化模块(libcache pwsh 组)
PSGALLERY_PKGS=(Posh-SSH powershell-yaml ImportExcel PowerHTML Pester PSScriptAnalyzer
    Microsoft.PowerShell.SecretManagement Microsoft.PowerShell.SecretStore)

# nuget 包(libcache dotnet 预热件 + ilspycmd;id 全小写走 flatcontainer)
NUGET_PKGS=(dnlib asmresolver asmresolver.pe asmresolver.dotnet iced mono.cecil
    icsharpcode.decompiler commandlineparser yamldotnet newtonsoft.json
    bouncycastle.cryptography system.directoryservices.protocols
    microsoft.netframework.referenceassemblies microsoft.data.sqlite sharpziplib
    system.commandline ilspycmd)

GIT_REPOS=(
    # re/p0/pentest/pivot 操作面
    rizinorg/rizin rizinorg/rz-ghidra rizinorg/sigdb DidierStevens/DidierStevensSuite
    mandiant/capa-rules Yara-Rules/rules danielmiessler/SecLists lgandx/Responder
    projectdiscovery/nuclei-templates onekey-sec/sasquatch ticarpi/jwt_tool GerbenJavado/LinkFinder
    dirkjanm/krbrelayx cddmp/enum4linux-ng digiNinja/CeWL r0oth3x49/ghauri pwndbg/pwndbg
    g0h4n/RustHound-CE Pennyw0rth/NetExec erebe/wstunnel rathole-org/rathole
    microsoft/vcpkg RsaCtfTool/RsaCtfTool
    # c2 参考
    bishopfox/sliver Ne0nd0g/merlin BC-SECURITY/Empire cobbr/Covenant
    its-a-feature/mythic byt3bl33d3r/SILENTTRINITY Adaptix-Framework/AdaptixC2
    # bof
    trustedsec/COFFLoader rasta-mouse/atomic-bofs trustedsec/CS-Situational-Awareness-BOF
    trustedsec/CS-Remote-OPs-BOF The-Z-Labs/bof-launcher
    # pz
    googleprojectzero/sandbox-attacksurface-analysis-tools tyranid/DotNetToJScript
    tyranid/windows-logical-eop-workshop tyranid/oleviewdotnet
    # maldev 41
    CX330Blake/Black-Hat-Zig darkr4y/OffensiveZig trickster0/OffensiveRust skerkour/black-hat-rust
    byt3bl33d3r/OffensiveNim Enelg52/OffensiveGo g0h4n/IsWebClientRunning-rs g0h4n/HasSession-rs
    g0h4n/LocalGroups-rs g0h4n/PassTheCert-rs icedracon/dcerpc icedracon/adhammer
    GhostPack/Rubeus SpecterOps/skills praetorian-inc/goffloader g0h4n/dende-rs
    carlospolop/PEASS-ng mzet-/linux-exploit-suggester wabzsy/gonut Zuigetzu/Donut-CustomHost
    n1xbyte/donutCS Binject/go-donut monoxgas/sRDI hasherezade/pe_to_shellcode phra/PEzor
    frohoff/ysoserial pwntester/ysoserial.net blinkenl1ghts/donloader optiv/ScareCrow
    boku7/BokuLoader benheise/TitanLdr xuanxuan0/DripLoader icyguider/Shhhloader
    fortra/No-Consolation fancycode/MemoryModule DarthTon/Blackbone mgeeky/ShellcodeFluctuation
    Cracked5pider/Stardust Maldev-Academy/ApiHashing Maldev-Academy/HellHall volexity/donut-decryptor
    # recon
    runZeroInc/mac-tracker rapid7/recog hickory-dns/hickory-dns nomi-sec/PoC-in-GitHub
)

# 标量:名|解析器(函数:参数)
SCALARS=(
    UV_VERSION:git_latest_tag:astral-sh/uv
    NU_VERSION:git_latest_tag:nushell/nushell
    DUCKDB_VERSION:git_latest_tag:duckdb/duckdb
    FRP_VERSION:git_latest_tag:fatedier/frp
    TRUFFLEHOG_VERSION:git_latest_tag:trufflesecurity/trufflehog
    CYBERCHEF_VERSION:git_latest_tag:gchq/CyberChef
    TRIVY_VERSION:git_latest_tag:aquasecurity/trivy
    NIM_VERSION:git_latest_tag:nim-lang/Nim
    KUBECTL_VERSION:kubectl_stable:
    BUN_VERSION:bun_latest:
    FRIDA_VERSION:git_latest_tag:frida/frida
    FRIDA_TOOLS_VERSION:pypi_latest:frida-tools
    AWSCLI_VERSION:awscli_soft:
    MSF_VERSION:msf_soft:
)
kubectl_stable() { curl -fsSL -m 15 "https://dl.k8s.io/release/stable.txt" 2>/dev/null || true; }
bun_latest() { curl -fsSL -m 15 "https://registry.npmmirror.com/bun/latest" 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || true; }
# 无干净索引面:软钉留空,消费点回退最新并警告(known-issues 留痕)
awscli_soft() { :; }
msf_soft() { :; }

main() {
    local out; out="$(mktemp)"
    {
        echo '# lib/pins.sh — 版本钉(由 scripts/resolve-pins.sh 生成,勿手改;升级跑解析器再审 diff)'
        echo "PINS_DATE=\"$(date +%F)\""
        echo
        echo 'declare -A GO_PIN=('
        local spec mod v
        for spec in "${GO_SPECS[@]}"; do
            mod="$(go_mod_of "$spec")"; v="$(go_latest "$mod")"
            [ -n "$v" ] || say "!! go 解析失败: $spec ($mod)"
            printf '    ["%s"]="%s"\n' "$spec" "$v"
        done
        echo ')'
        echo 'declare -A CRATE_PIN=('
        local c
        for c in "${CRATES[@]}"; do
            v="$(crate_latest "$c")"; [ -n "$v" ] || say "!! crate 解析失败: $c"
            printf '    ["%s"]="%s"\n' "$c" "$v"
        done
        echo ')'
        echo 'declare -A PYPI_PIN=('
        local p
        for p in "${PYPI_PKGS[@]}"; do
            v="$(pypi_latest "$p")"; [ -n "$v" ] || say "!! pypi 解析失败: $p"
            printf '    ["%s"]="%s"\n' "$p" "$v"
        done
        echo ')'
        echo 'declare -A GEM_PIN=('
        local g
        for g in "${GEMS[@]}"; do
            v="$(gem_latest "$g")"; [ -n "$v" ] || say "!! gem 解析失败: $g"
            printf '    ["%s"]="%s"\n' "$g" "$v"
        done
        echo ')'
        echo 'declare -A NUGET_PIN=('
        local nq
        for nq in "${NUGET_PKGS[@]}"; do
            v="$(nuget_latest "$nq")"; [ -n "$v" ] || say "!! nuget 解析失败: $nq"
            printf '    ["%s"]="%s"\n' "$nq" "$v"
        done
        echo ')'
        echo 'declare -A GIT_PIN=('
        local r
        for r in "${GIT_REPOS[@]}"; do
            v="$(git_head "$r")"; [ -n "$v" ] || say "!! git 解析失败: $r"
            printf '    ["%s"]="%s"\n' "$r" "$v"
        done
        echo ')'
        echo 'declare -A NPM_PIN=('
        local nm
        for nm in "${NPM_PKGS[@]}"; do
            v="$(npm_latest "$nm")"; [ -n "$v" ] || say "!! npm 解析失败: $nm"
            printf '    ["%s"]="%s"\n' "$nm" "$v"
        done
        echo ')'
        echo 'declare -A PSGALLERY_PIN=('
        local ps
        for ps in "${PSGALLERY_PKGS[@]}"; do
            v="$(psgallery_latest "$ps")"; [ -n "$v" ] || say "!! psgallery 解析失败: $ps"
            printf '    ["%s"]="%s"\n' "$ps" "$v"
        done
        echo ')'
        echo '# 标量钉(空串 = 软钉:无干净索引面,消费点回退最新并警告)'
        local s name fn arg
        for s in "${SCALARS[@]}"; do
            name="${s%%:*}"; fn="$(echo "$s" | cut -d: -f2)"; arg="$(echo "$s" | cut -d: -f3)"
            v="$("$fn" $arg 2>/dev/null)" || v=""
            printf '%s="%s"\n' "$name" "$v"
        done
        echo '# temurin 主版本钉(tuna Adoptium 目录解析;空 = 回退目录最新)'
        local mj
        for mj in 8 11 17 21 25; do
            v="$(temurin_latest "$mj")"
            printf 'TEMURIN_PIN_%s="%s"\n' "$mj" "$v"
        done
    } > "$out"
    if [ "${1:-}" = "--check" ]; then
        diff -u "$PINS" "$out" || true
        rm -f "$out"
    else
        mv "$out" "$PINS"
        local missing
        missing="$(grep -E '\]=""$|^[A-Z_]+=""$' "$PINS" | grep -cE 'AWSCLI_VERSION|MSF_VERSION' -v || true)"
        local total; total="$(grep -cE '\]="[^"]+"$|^[A-Z_]+="[^"]+"$' "$PINS" || true)"
        say "pins.sh 已生成:非空钉 $total;空钉(除软钉) $missing"
        [ "$missing" -eq 0 ] || { say "!! 有空钉,消费点会响;重跑解析器补齐"; exit 1; }
    fi
}
main "$@"

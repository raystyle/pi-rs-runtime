export DEBIAN_FRONTEND=noninteractive

# ---- 镜像源(可覆盖)-------------------------------------------------
# 原则:有国内更快的走更快源;实测 2026-10-09:apt 阿里云(原 tuna 慢)、pypi 阿里云、
# rustup/crates 阿里云(crate 文件本体也镜像,优于 tuna 回源 static.crates.io)、
# maven 发行包阿里云;Adoptium 阿里云无镜像仍走 tuna;golang 发行包南大(华为 401);
# npm 即淘宝(npmmirror 为淘宝 npm 镜像新域名)
TUNA="${TUNA:-https://mirrors.tuna.tsinghua.edu.cn}"
ALIYUN="${ALIYUN:-https://mirrors.aliyun.com}"
export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://rsproxy.cn}"
export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}"
CRATES_INDEX="${CRATES_INDEX:-https://rsproxy.cn/index}"   # sparse 索引;config.json 的 dl 指 rsproxy 本体
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"   # tuna 无 golang 模块代理,用七牛 goproxy;export 给子进程 go install
export GOSUMDB="${GOSUMDB:-sum.golang.google.cn}"       # 国内可连的校验和库
GO_DOWNLOAD="${GO_DOWNLOAD:-https://mirror.nju.edu.cn/golang}" # tuna 无 golang;南大镜像同为高校源,也可用 golang.google.cn
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"            # 淘宝 npm 镜像
NODE_MIRROR="${NODE_MIRROR:-https://registry.npmmirror.com/-/binary/node}" # 淘宝 node 二进制
PIP_INDEX="${PIP_INDEX:-$ALIYUN/pypi/simple}" # 写 /etc/pip.conf 与 /etc/uv/uv.toml,uv 索引用同一个变量

# 离线优先默认(纯离线镜像):运行期配置把 go/cargo/npm/uv/pip 钉成快失败(go env 文件、
# cargo config.toml [net] offline、npmrc offline+fetch-retries=0、uv.toml offline、pip.conf no-index);
# 构建脚本在此显式拿回在线面——env 优先级恒高于上述配置文件,全链路 source 本文件即在线。
# uv 特例(实证 uv 0.12.15):UV_OFFLINE=0 压不过配置文件的 offline=true,只有 UV_CONFIG_FILE
# 指到无 offline 的文件才整面替换,故构建期改用 uv-online.toml
export CARGO_NET_OFFLINE=false PIP_NO_INDEX=false
export NPM_CONFIG_OFFLINE=false NPM_CONFIG_FETCH_RETRIES=3 NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=10000 NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=60000
[ -f /etc/uv/uv-online.toml ] && export UV_CONFIG_FILE=/etc/uv/uv-online.toml
ADOPTIUM_MIRROR="${ADOPTIUM_MIRROR:-$TUNA/Adoptium}"  # 阿里云无 Adoptium 镜像
MAVEN_MIRROR="${MAVEN_MIRROR:-$ALIYUN/apache/maven}"

# ---- 版本钉 -------------------------------------------------------
GOLANG_VERSION="${GOLANG_VERSION:-1.27.1}"   # 两个维护线内取最新;sha256 钉在 install_golang
NODE_VERSION="${NODE_VERSION:-24.21.0}"   # 当前 Active LTS(Krypton)
FNM_NODE_VERSIONS="${FNM_NODE_VERSIONS:-18 20 22 24}"   # fnm 预装的流行 node 历史版本(大版本号)
DOTNET_SDK="${DOTNET_SDK:-dotnet-sdk-10.0}"  # noble 自带源(即 tuna);8.0 将于 2026-11 停止支持
NUGET_MIRROR="${NUGET_MIRROR:-https://repo.huaweicloud.com/repository/nuget/v3/index.json}"
PD_VERSION="${PD_VERSION:-latest}"          # 已弃用:pd/secgo 逐件钉 pins.sh(保留变量防外部引用炸)
ZIG_VERSION="${ZIG_VERSION:-0.16.0}"
MAVEN_VERSION="${MAVEN_VERSION:-3.9.16}"
GRADLE_VERSION="${GRADLE_VERSION:-8.14.3}"
MAVEN_DEP_MIRROR="${MAVEN_DEP_MIRROR:-https://maven.aliyun.com/repository/public}"
JAVA_VERSIONS="${JAVA_VERSIONS:-8 11 17 21 25}"  # sdkman 预装的开源 JDK 主版本(temurin,tuna Adoptium;25 为新 LTS)
PY2_VERSION="${PY2_VERSION:-2.7.18}"             # 逆向分析用;noble 官方源无 python2,源码编译
PY2_MIRROR="${PY2_MIRROR:-https://mirrors.huaweicloud.com/python}"
PHP_VERSIONS="${PHP_VERSIONS:-7.4 8.1 8.3}"   # webshell 逆向:7.4 兼容老样本,8.x 对现代样本
GHIDRA_VERSION="${GHIDRA_VERSION:-12.1.3}"        # 官方 releases 无国内镜像,GitHub 直下
GHIDRA_DATE="${GHIDRA_DATE:-20260817}"
GHIDRA_SHA256="${GHIDRA_SHA256:-93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54}"
RE_VENV="${RE_VENV:-/opt/re-venv}"                # 逆向 Python 独立环境(uv venv)
VENV_ANALYTICS="${VENV_ANALYTICS:-/opt/analytics}"   # 数据分析栈 uv venv(不碰系统 python3)
GITHUB_MIRROR="${GITHUB_MIRROR:-https://proxy.ohmygh.com/}"  # GitHub 前置代理,置空则直连
SURY_MIRROR="${SURY_MIRROR:-https://mirror.nju.edu.cn/sury}"  # tuna 无 sury;南大/中科大有
HERDR_VERSION="${HERDR_VERSION:-0.9.3}"   # herdr.dev stable 频道;release 资产在 GitHub,无国内镜像
HERDR_SHA256="${HERDR_SHA256:-18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7}"  # linux-x86_64 资产;换版本重算

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---- 版本钉消费面(用户裁定:幂等部署+pin+升级;钉由 scripts/resolve-pins.sh 生成) ----
COMMON_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$COMMON_HERE/pins.sh"

# go 钉值取出(循环消费用);缺钉即响
go_pin_ver() { # go_pin_ver <完整 spec> → 版本/tag/sha 到 stdout
    local v="${GO_PIN[$1]:-}"
    [ -n "$v" ] || { echo "!! pins.sh 缺 go 钉: $1(跑 scripts/resolve-pins.sh)" >&2; return 1; }
    printf '%s' "$v"
}
# go install 钉:缺钉即响(不允许漂回 @latest)
go_install_pin() { # go_install_pin <完整 spec> → go install spec@钉
    local v; v="$(go_pin_ver "$1")" || return 1
    go install "$1@${v}"
}
# cargo install 钉:同理,带 --locked
cargo_install_pin() { # cargo_install_pin <crate> [额外参数]
    local c="$1"; shift
    local v="${CRATE_PIN[$c]:-}"
    [ -n "$v" ] || { echo "!! pins.sh 缺 crate 钉: $c(跑 scripts/resolve-pins.sh)" >&2; return 1; }
    cargo install "$c" --locked --version "$v" "$@"
}
# pypi 钉值取出(给 uv tool/uv pip 拼接 ==)
pypi_pin() { # pypi_pin <pkg> → 版本到 stdout;缺钉返回 1
    local v="${PYPI_PIN[$1]:-}"
    [ -n "$v" ] || { echo "!! pins.sh 缺 pypi 钉: $1(跑 scripts/resolve-pins.sh)" >&2; return 1; }
    printf '%s' "$v"
}
# 钉版克隆:有钉 fetch 该 commit 深 1;幂等(HEAD 已是钉即跳过);无钉回退 depth 1 并警告
# 第三参数 submodules 时顺带浅子模块初始化
clone_pin() { # clone_pin <owner/repo> <dest> [submodules]
    local repo="$1" dest="$2" sub="${3:-}"
    local sha="${GIT_PIN[$repo]:-}" url="${GITHUB_MIRROR}https://github.com/${repo}"
    if [ -z "$sha" ]; then
        echo "!! pins.sh 缺 git 钉: $repo——回退 depth 1 漂 HEAD(跑 scripts/resolve-pins.sh 补钉)" >&2
        if [ -d "$dest/.git" ]; then return 0; fi
        git clone --depth 1 $([ "$sub" = submodules ] && echo --recurse-submodules --shallow-submodules) "$url" "$dest"
        return
    fi
    if [ -d "$dest/.git" ] && [ "$(git -C "$dest" rev-parse HEAD 2>/dev/null)" = "$sha" ]; then
        return 0   # 已在钉上
    fi
    rm -rf "$dest" && install -d "$dest"
    git -C "$dest" init -q && git -C "$dest" remote add origin "$url"
    git -C "$dest" fetch -q --depth 1 origin "$sha" && git -C "$dest" checkout -q FETCH_HEAD
    [ "$sub" = submodules ] && git -C "$dest" submodule update --init --depth 1
    true
}

# 共享可写缓存(zig/gradle/cargo-zigbuild 的家目录软链目标):必须可写但不可 1777——
# 任意用户可写就能换掉 root 下次用的缓存(grok F1)。共同组 piopt + 默认 ACL:
# 实证 setgid 只继承组不继承写位(umask 022 下新目录 g=r-x,ubuntu 写不进),
# 默认 ACL 才压得住 umask;依赖 acl 包(install-all 前置批装)。
shared_writable_cache() {
    [ -d "$1" ] || install -d "$1"
    groupadd -f piopt
    local u
    for u in root ubuntu; do id "$u" >/dev/null 2>&1 && usermod -aG piopt "$u"; done
    chgrp -R piopt "$1" && chmod -R g+rwX "$1" && find "$1" -type d -exec chmod g+s {} +
    if have setfacl; then
        setfacl -R -m g:piopt:rwX "$1" && setfacl -R -d -m g:piopt:rwX "$1"
    else
        # 没 setfacl 只剩 setgid,压不住 umask(实证 ubuntu 写不进新子目录)——不响就是假绿
        echo "!! setfacl 缺失(acl 包未装):$1 共享写不成立,先 apt-get install acl" >&2
        return 1
    fi
}

# 按名单跑安装函数:不带参数装全部
run_category() {
    local -n _all=$1; shift
    local targets=("$@")
    [ ${#targets[@]} -eq 0 ] && targets=("${_all[@]}")
    for t in "${targets[@]}"; do
        case " ${_all[*]} " in
            *" $t "*) "install_$t" ;;
            *) echo "未知项: $t(可选: ${_all[*]})"; exit 1 ;;
        esac
    done
    log "全部完成: $0"
}

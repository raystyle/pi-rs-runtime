export DEBIAN_FRONTEND=noninteractive

# ---- 镜像源(可覆盖)-------------------------------------------------
# 原则:有 tuna 走 tuna;tuna 没有的走该生态自己的国内镜像
TUNA="${TUNA:-https://mirrors.tuna.tsinghua.edu.cn}"
export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-$TUNA/rustup}"
export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-$TUNA/rustup/rustup}"
CRATES_INDEX="${CRATES_INDEX:-$TUNA/crates.io-index}"
export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"   # tuna 无 golang 模块代理,用七牛 goproxy;export 给子进程 go install
export GOSUMDB="${GOSUMDB:-sum.golang.google.cn}"       # 国内可连的校验和库
GO_DOWNLOAD="${GO_DOWNLOAD:-https://mirror.nju.edu.cn/golang}" # tuna 无 golang;南大镜像同为高校源,也可用 golang.google.cn
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"            # tuna 无 npm registry
NODE_MIRROR="${NODE_MIRROR:-https://registry.npmmirror.com/-/binary/node}" # tuna 无 node 二进制
PIP_INDEX="${PIP_INDEX:-https://pypi.tuna.tsinghua.edu.cn/simple}" # tuna pypi 独立 vhost;mirrors.tuna.../pypi/ 是 404
ADOPTIUM_MIRROR="${ADOPTIUM_MIRROR:-$TUNA/Adoptium}"
MAVEN_MIRROR="${MAVEN_MIRROR:-$TUNA/apache/maven}"

# ---- 版本钉 -------------------------------------------------------
GOLANG_VERSION="${GOLANG_VERSION:-1.27.1}"   # 两个维护线内取最新;sha256 钉在 install_golang
NODE_VERSION="${NODE_VERSION:-24.21.0}"   # 当前 Active LTS(Krypton)
FNM_NODE_VERSIONS="${FNM_NODE_VERSIONS:-18 20 22 24}"   # fnm 预装的流行 node 历史版本(大版本号)
DOTNET_SDK="${DOTNET_SDK:-dotnet-sdk-10.0}"  # noble 自带源(即 tuna);8.0 将于 2026-11 停止支持
NUGET_MIRROR="${NUGET_MIRROR:-https://repo.huaweicloud.com/repository/nuget/v3/index.json}"
PD_VERSION="${PD_VERSION:-latest}"          # projectdiscovery 工具编译版本
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
GITHUB_MIRROR="${GITHUB_MIRROR:-}"                # 可选,如 https://ghfast.top/
SURY_MIRROR="${SURY_MIRROR:-https://mirror.nju.edu.cn/sury}"  # tuna 无 sury;南大/中科大有
HERDR_VERSION="${HERDR_VERSION:-0.9.3}"   # herdr.dev stable 频道;release 资产在 GitHub,无国内镜像
HERDR_SHA256="${HERDR_SHA256:-18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7}"  # linux-x86_64 资产;换版本重算

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

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

#!/usr/bin/env bash
# 闭集族漂移守卫:镜像族成员 vs catalog 行双向对账(容器内跑,发布门禁件)
# 用法(容器内): bash /root/scripts/check-family-closure.sh [catalog.tsv]
#   宿主典型: incus exec <实例> -- bash /root/scripts/check-family-closure.sh
#   正控试验: 拷一份 catalog 删一行族成员再跑,必须报 FAIL(证守卫会咬)
# 族域(镜像侧真源;升级若改安装布局,同步改这里):
#   impacket  /opt/uv-tools/impacket/bin/*.py(排除 uv 自带 activate_this.py)
#   frida     /usr/local/bin/frida 本尊 + /usr/local/bin/frida-*
#   re        /usr/local/bin/rizin 本尊 + /usr/local/bin/rz-*(rz-ghidra 是插件行,path 在插件域,不属本族 bin 面)
#   nim       /opt/nim/toolchains/*/bin/*(choosenim 形,current 是文件不是链接,吃通配抗版本漂)
# 判据: 族成员缺 catalog 行、或其 catalog path 不在镜像 = FAIL;族册来源行 path 声明却缺少安装路径 = FAIL
# 退出码: 0=零漂移;1=有漂移(门禁败态)
set -u
CATALOG="${1:-$(cd "$(dirname "$0")" && pwd)/ctl/data/catalog.tsv}"
[ -r "$CATALOG" ] || { echo "FAIL catalog 不可读:$CATALOG"; exit 1; }

FAIL=0; CHECKS=0
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
ok()  { printf '  ok   %s\n' "$1"; }

# catalog 索引:id -> path;册来源 -> 行集
declare -A C_PATH=()
CAND="$(mktemp)"
awk -F'\t' '/^#/ {next} $1 != "" {print $1 "\t" $7 "\t" $9}' "$CATALOG" > "$CAND"
while IFS=$'\t' read -r cid cpath csrc; do C_PATH["$cid"]="$cpath"; done < "$CAND"

# check_family <族名> <册路径> <成员...>(成员参数为 id;镜像域由调用侧枚举)
check_family() {
    local fam="$1" src="$2"; shift 2
    local n=0
    for id in "$@"; do
        n=$((n+1)); CHECKS=$((CHECKS+1))
        local p="${C_PATH[$id]:-}"
        if [ -z "$p" ]; then bad "[$fam] 镜像成员缺 catalog 行:$id"; continue; fi
        [ -e "$p" ] || bad "[$fam] $id 的 catalog path 缺少安装路径:$p"
    done
    # 反向:该册来源的行,path 非空即须在镜像
    while IFS=$'\t' read -r cid cpath csrc; do
        [ "$csrc" = "$src" ] || continue
        [ -n "$cpath" ] || continue
        CHECKS=$((CHECKS+1))
        [ -e "$cpath" ] || bad "[$fam] 册行 $cid 声明 path 缺少安装路径:$cpath"
    done < "$CAND"
    ok "[$fam] 前向 $n 成员对账完"
}

echo "== 闭集族漂移守卫:catalog=$CATALOG =="

mapfile -t IMPACKET < <(cd /opt/uv-tools/impacket/bin 2>/dev/null && ls *.py 2>/dev/null | grep -vx 'activate_this.py' || true)
check_family impacket docs/items/analysis/impacket.md "${IMPACKET[@]}"

FRIDA_LIST=(frida)
for f in /usr/local/bin/frida-*; do [ -e "$f" ] && FRIDA_LIST+=("$(basename "$f")"); done
check_family frida docs/items/tools-pentest/frida.md "${FRIDA_LIST[@]}"

RE_LIST=(rizin)
for f in /usr/local/bin/rz-*; do [ -e "$f" ] && RE_LIST+=("$(basename "$f")"); done
check_family re docs/items/tools-reverse/reverse.md "${RE_LIST[@]}"

NIM_LIST=()
for f in /opt/nim/toolchains/*/bin/*; do [ -e "$f" ] && NIM_LIST+=("$(basename "$f")"); done
check_family nim docs/items/compilers/nim.md "${NIM_LIST[@]}"

printf '===_closure checks=%d fail=%d===\n' "$CHECKS" "$FAIL"
[ "$FAIL" = 0 ]

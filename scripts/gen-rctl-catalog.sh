#!/usr/bin/env bash
# gen-rctl-catalog.sh:docs/items/ 册蒸馏成 rctl 能力表(scripts/ctl/data/catalog.tsv)
# 投影可再生成不手改;--check 为漂移守卫(再生成后 diff,非零即漂移)进门禁
# 册结构约定:1 行标题;3 行 blockquote「> 描述 ｜ 状态:xx ｜ 组:xx」;- **版本钉/落点/离线行为** 各一节
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="scripts/ctl/data/catalog.tsv"
TMP="$(mktemp)"

env_of() {  # 归档域(七域草判,prt-09 定稿中):id 级覆盖(数据分析栈);组默认;kind 规则由主流程与机器行覆盖
    if [ -n "$2" ]; then
        case "$2" in
            duckdb|clickhouse|nu) echo "数据分析"; return 0;;
            frida|jadx|apktool|capa|pwndbg) echo "逆向环境"; return 0;;  # prt-09 改判:册不在逆向目录的逆向入口
        esac
    fi
    case "$1" in
        compilers) echo "编程环境" ;;
        runtimes)  echo "运行时环境" ;;
        libcache)  echo "编程环境" ;;
        tools-ghidra|tools-rea|tools-re) echo "逆向环境" ;;
        tools-c2|tools-maldev|tools-pz|tools-recon) echo "代码样板参考" ;;
        *) echo "工具环境" ;;
    esac
}

kind_of() {
    case "$1" in
        compilers) echo compiler ;;
        runtimes)  echo runtime ;;
        libcache)  echo cache ;;
        tools-*)   echo tool ;;
        *) echo other ;;
    esac
}

clean() { # tsv 字段禁 tab/换行
    printf '%s' "$1" | tr '\t\n' '  ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-200
}

{
    echo "# rctl catalog(生成物勿手改;源 docs/items/,再跑 gen-rctl-catalog.sh)"
    echo "# id	kind	group	status	desc	pin	path	offline	book"
    for f in docs/items/*/*.md; do
        [ -f "$f" ] || continue
        id="$(basename "$f" .md)"
        dir="$(basename "$(dirname "$f")")"
        kind="$(kind_of "$dir")"
        # blockquote 头:> 描述 ｜ 状态:已装 ｜ 组:xxx
        quote="$(grep -m1 '^> ' "$f" | sed 's/^> //')"
        desc="$(printf '%s' "$quote" | awk -F'｜' '{print $1}')"
        status="$(printf '%s' "$quote" | grep -oP '状态:\K[^｜]*' || true)"
        group="$(printf '%s' "$quote" | grep -oP '组:\K[^｜]*' || true)"
        pin="$(grep -m1 '^- \*\*版本钉\*\*' "$f" | sed 's/^- \*\*版本钉\*\*:*//' || true)"
        path="$(grep -m1 '^- \*\*落点\*\*' "$f" | grep -oP '/(opt|usr|etc|var|root|home)[A-Za-z0-9_./-]*' | head -1 || true)"
        offline="$(grep -m1 '^- \*\*离线行为\*\*' "$f" | sed 's/^- \*\*离线行为\*\*:*//' || true)"
        # 机器小表(prt-07 件2):一册可发多行多 kind,声明即册内真相,不另维护全局例外文件
        # 形式:- rctl: <id> kind=<kind> path=<path> [alias=<bin>] [note=<一句话>]
        grep -E '^- rctl: ' "$f" | while IFS= read -r line; do   # grep 无匹配在 pipefail 下退 1,由末行 || true 兜底
            rid=$(printf '%s' "$line" | sed -E 's/^- rctl: ([^ ]+).*/\1/')
            rkind=$(printf '%s' "$line" | grep -oP 'kind=\K[^ ]+' || true)
            rpath=$(printf '%s' "$line" | grep -oP 'path=\K[^ ]+' || true)
            ralias=$(printf '%s' "$line" | grep -oP 'alias=\K[^ ]+' || true)
            rnote=$(printf '%s' "$line" | grep -oP 'note=\K.*' || true)
            renv=$(printf '%s' "$line" | grep -oP 'env=\K[^ ]+' || true)
            : "${renv:=$(env_of "$dir" "$rid")}"
            [ "${rkind:-tool}" = data ] && [ -z "$(printf '%s' "$line" | grep -oP 'env=\K[^ ]+')" ] && renv=数据信息搜索
            printf '%s\t%s\t%s\t%s\t%s\t\t%s\t\t%s\t%s\t%s\n' \
                "$(clean "$rid")" "$(clean "${rkind:-tool}")" "$(clean "$group")" "已烘焙" \
                "$(clean "${rnote:-$(clean "$desc")}")" "$(clean "$rpath")" "$f" "$(clean "$ralias")" "$renv"
        done || true
        # 参考克隆是角色不是生命周期:status 原文以「参考克隆」起头时 kind 改 ref(prt-07 分面)
        case "$status" in 参考克隆*) kind=ref;; esac
        renv="$(env_of "$dir" "$id")"
        [ "$kind" = ref ] && renv=代码样板参考
        [ "$kind" = data ] && renv=数据信息搜索
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\t%s\n' \
            "$(clean "$id")" "$(clean "$kind")" "$(clean "$group")" "$(clean "$status")" \
            "$(clean "$desc")" "$(clean "$pin")" "$(clean "$path")" "$(clean "$offline")" "$(clean "$f")" "$renv"
        # 成员表蒸馏:组册表行第一列(或编号表的第二列)是 ascii 件名,成员继承册的组/状态/书
        # 落点蒸馏(pathq-01 裁定 2026-10-12):表头有「入口」「落点」列时派生 path——
        #   落点单元格绝对路径,目录形(尾段 bin/sbin)拼入口单命令名、文件形直取;
        #   无落点列时,册落点节写明 apt 落 /usr/bin 的组按 /usr/bin/<入口> 兜;
        #   入口格多名/带说明(dig/nslookup、import scapy、binfmt_misc 注册)不猜,path 留空
        aptusr=0; grep -m1 '^- \*\*落点' "$f" | grep -q '/usr/bin' && aptusr=1
        awk -F'|' '
            function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
            function strip(s){ gsub(/^[ \t`]+|[ \t`]+$/,"",s); return s }
            ! /^[ \t]*\|/ { intab=0; CENT=0; CLOC=0; next }
            NF>=4 {
                if (!intab) {          # 本表首行=表头:记入口/落点列号
                    for (i=2;i<NF;i++) { h=strip($i)
                        if (h=="入口") CENT=i
                        if (h=="落点") CLOC=i
                    }
                    intab=1; next
                }
                c1=trim($2); d=trim($(NF-1))
                # 编号表:第一列纯数字时件名在第二列
                if (c1 ~ /^[0-9]+$/) c1=trim($3)
                if (c1 ~ /^[a-zA-Z0-9_.-]+$/ && c1 ~ /[a-zA-Z]/ && c1 !~ /^:?-/) {
                    ent=""; loc=""; p=""
                    if (CENT) ent=strip($CENT)
                    if (CLOC) loc=strip($CLOC)
                    # 落点格可带尾注(/usr/bin/batcat + 软链句):取头部绝对路径段;
                    # 文件形直取(pathq-01 规则 a,入口格多名不挡);目录形拼入口、apt 兜底才要单命令名
                    if (match(loc, /^\/[a-zA-Z0-9._\/-]+/)) {
                        lp=substr(loc, RSTART, RLENGTH)
                        if (lp ~ /\/(bin|sbin)$/) { if (ent ~ /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/) p=lp "/" ent }
                        else p=lp
                    } else if (APTUSR && ent ~ /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/) p="/usr/bin/" ent
                    if (length(d)>2) printf "%s\t%s\t%s\t%s\t%s\t\t%s\t\t%s\t\t%s\n", c1, K, G, S, substr(d,1,120), p, B, ENV
                }
            }' K="$kind" G="$(clean "$group")" S="$(clean "$status")" B="$f" ENV="$(env_of "$dir" "")" APTUSR="$aptusr" "$f"
    done | sort -t$'\t' -k1,1 | awk -F'\t' '
        {
            if (!(($1) in seen)) { seen[$1]=1; for (i=1;i<=NF;i++) best[$1,i]=$i }
            else { for (i=2;i<=NF;i++) if ($i!="" && best[$1,i]=="") best[$1,i]=$i }
        }
        END { for (k in seen) { line=k; for (i=2;i<=11;i++) line=line "\t" (best[k,i]==""?"":best[k,i]); print line } }' | sort -t$'\t' -k1,1
} > "$TMP"

mkdir -p "$(dirname "$OUT")"
if [ "${1:-}" = "--check" ]; then
    if diff -u "$OUT" "$TMP" >/dev/null 2>&1; then
        echo "catalog 零漂移($(wc -l < "$OUT") 行)"
        rm -f "$TMP"
    else
        diff -u "$OUT" "$TMP" | head -20 || true
        echo "!! catalog 漂移:重跑 scripts/gen-rctl-catalog.sh 并提交" >&2
        rm -f "$TMP"
        exit 1
    fi
else
    mv "$TMP" "$OUT"
    echo "catalog 生成:$OUT($(grep -vc '^#' "$OUT") 件)"
fi

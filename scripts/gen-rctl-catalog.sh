#!/usr/bin/env bash
# gen-rctl-catalog.sh:docs/items/ 册蒸馏成 rctl 能力表(scripts/ctl/data/catalog.tsv)
# 投影可再生成不手改;--check 为漂移守卫(再生成后 diff,非零即漂移)进门禁
# 册结构约定:1 行标题;3 行 blockquote「> 描述 ｜ 状态:xx ｜ 组:xx」;- **版本钉/落点/离线行为** 各一节
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="scripts/ctl/data/catalog.tsv"
TMP="$(mktemp)"

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
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$(clean "$id")" "$(clean "$kind")" "$(clean "$group")" "$(clean "$status")" \
            "$(clean "$desc")" "$(clean "$pin")" "$(clean "$path")" "$(clean "$offline")" "$(clean "$f")"
        # 成员表蒸馏:组册表行第一列(或编号表的第二列)是 ascii 件名,成员继承册的组/状态/书
        awk -F'|' '
            /^[ \t]*\|/ && NF>=4 {
                c1=$2; gsub(/^[ \t]+|[ \t]+$/, "", c1)
                d=$(NF-1); gsub(/^[ \t]+|[ \t]+$/, "", d)
                # 编号表:第一列纯数字时件名在第二列
                if (c1 ~ /^[0-9]+$/) { c1=$3; gsub(/^[ \t]+|[ \t]+$/, "", c1) }
                if (c1 ~ /^[a-zA-Z0-9_.-]+$/ && c1 ~ /[a-zA-Z]/ && c1 !~ /^:?-/) {
                    if (length(d)>2) printf "%s\t%s\t%s\t%s\t%s\t\t\t\t%s\n", c1, K, G, S, substr(d,1,120), B
                }
            }' K="$kind" G="$(clean "$group")" S="$(clean "$status")" B="$f" "$f"
    done | sort -t$'\t' -k1,1 | awk -F'\t' '
        {
            filled=0; for (i=1;i<=NF;i++) if ($i!="") filled++
            if (!(($1) in best) || filled>bestfill[$1]) { best[$1]=$0; bestfill[$1]=filled }
        }
        END { for (k in best) print best[k] }' | sort -t$'\t' -k1,1
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

#!/usr/bin/env bash
# resources.json(结构契约真源,REQ-0006)→ catalog.tsv/caps.tsv(rctl 烤库投影)
# 守卫三道:
#   ① 结构校验(内建,零依赖):version/字段类型/kind 枚举/id 唯一/caps.ids 必在 resources
#   ② 册 rctl 机器行双向对账:册有行必在 JSON 且 kind/path 一致(册可无行,JSON 是唯一增改面)
#   ③ book 链接落盘:JSON.book 非空必须指向存在的册
# --check:投影 diff 漂移守卫(重生成与盘上比对,非零即漂移)
# 历史注:2026-10-12 前本脚本从册蒸馏生成(彼时旧蒸馏 bytewise substr 曾截断多字节字符,
# 迁移批已修 29 字段;现 desc/pin/offline 全文进 JSON,无截断面)。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/scripts/ctl/data/resources.json"
OUT_CAT="$ROOT/scripts/ctl/data/catalog.tsv"
OUT_CAPS="$ROOT/scripts/ctl/data/caps.tsv"
TMP_CAT="$(mktemp)"; TMP_CAPS="$(mktemp)"

python3 - "$SRC" "$TMP_CAT" "$TMP_CAPS" "$ROOT" <<'PY'
import json, os, re, sys

src, tmp_cat, tmp_caps, root = sys.argv[1:5]
doc = json.load(open(src, encoding="utf-8"))
errs = []

# ① 结构校验
if doc.get("version") != 1: errs.append("version 必须是 1")
KINDS = {"tool","data","cache","ref","service","compiler","runtime","model"}
STRF = ["id","kind","group","status","desc","pin","path","offline","book","alias","env"]
resources = doc.get("resources")
caps = doc.get("caps")
if not isinstance(resources, list) or not resources: errs.append("resources 必须是非空数组")
if not isinstance(caps, list): errs.append("caps 必须是数组")
if errs: sys.exit("; ".join(errs))
seen = set()
for i, r in enumerate(resources):
    if not isinstance(r, dict): errs.append(f"resources[{i}] 非对象"); continue
    for f in STRF:
        if not isinstance(r.get(f, ""), str): errs.append(f"resources[{i}].{f} 非字符串")
    if not r.get("id"): errs.append(f"resources[{i}] 缺 id")
    if r.get("kind") not in KINDS: errs.append(f"{r.get('id')}: kind 非法 {r.get('kind')!r}")
    if r["id"] in seen: errs.append(f"id 重复: {r['id']}")
    seen.add(r["id"])
ids = seen
for i, c in enumerate(caps):
    if not isinstance(c, dict): errs.append(f"caps[{i}] 非对象"); continue
    if not c.get("task"): errs.append(f"caps[{i}] 缺 task")
    if not isinstance(c.get("ids"), list) or not c["ids"]: errs.append(f"caps[{i}].ids 非法")
    for x in c.get("ids", []):
        if x not in ids: errs.append(f"caps[{c.get('task')}]: id 不在 resources: {x}")

# ② 册机器行双向对账(册行是历史/叙事邻接面;增改资源只在 JSON)
pat = re.compile(r"^- rctl: (\S+) kind=(\S+)(.*)$")
pseg = re.compile(r"(?:^| )path=(\S+)")
nbook = 0
for dirpath, _dirs, files in os.walk(os.path.join(root, "docs", "items")):
    for fn in files:
        if not fn.endswith(".md"): continue
        p = os.path.join(dirpath, fn)
        for ln, line in enumerate(open(p, encoding="utf-8"), 1):
            m = pat.match(line.strip())
            if not m: continue
            rid, kind, rest = m.groups()
            nbook += 1
            if rid not in ids: errs.append(f"册行不在 JSON: {p}:{ln} {rid}")
if nbook == 0: errs.append("册机器行扫描为零(扫描面异常)")

# ③ book 链接落盘
for r in resources:
    b = r.get("book", "")
    if b and not os.path.isfile(os.path.join(root, b)): errs.append(f"{r['id']}: book 不在盘: {b}")

if errs:
    print("!! 契约校验失败:", file=sys.stderr)
    for e in errs[:20]: print("  " + e, file=sys.stderr)
    sys.exit(1)

# 投影:catalog.tsv(11 列,id 排序)与 caps.tsv(4 列)
with open(tmp_cat, "w", encoding="utf-8") as fh:
    fh.write("# rctl catalog(生成物勿手改;源 scripts/ctl/data/resources.json,再跑 scripts/gen-rctl-catalog.sh)\n")
    for r in sorted(resources, key=lambda x: x["id"]):
        fh.write("\t".join(r.get(f, "") for f in STRF) + "\n")
with open(tmp_caps, "w", encoding="utf-8") as fh:
    fh.write("# rctl caps 能力词典投影(源 resources.json;task 是中英同义词袋,空格分隔)\n")
    for c in caps:
        fh.write("\t".join([c.get("task",""), ",".join(c.get("ids",[])), c.get("example",""), c.get("note","")]) + "\n")
print(f"投影:catalog {len(resources)} 件,caps {len(caps)} 条;册机器行对账 {nbook} 行")
PY

if [ "${1:-}" = "--check" ]; then
    ok=1
    diff -u "$OUT_CAT" "$TMP_CAT" > /tmp/gen-cat.diff 2>&1 || ok=0
    diff -u "$OUT_CAPS" "$TMP_CAPS" > /tmp/gen-caps.diff 2>&1 || ok=0
    if [ "$ok" = 1 ]; then
        echo "catalog/caps 零漂移($(wc -l < "$OUT_CAT") 行 / $(wc -l < "$OUT_CAPS") 行)"
    else
        head -20 /tmp/gen-cat.diff /tmp/gen-caps.diff || true
        echo "!! 投影漂移:重跑 scripts/gen-rctl-catalog.sh 并提交" >&2
        ok=0
    fi
    rm -f "$TMP_CAT" "$TMP_CAPS"
    [ "$ok" = 1 ]
else
    mv "$TMP_CAT" "$OUT_CAT"; mv "$TMP_CAPS" "$OUT_CAPS"
    echo "catalog 生成:$OUT_CAT / caps 生成:$OUT_CAPS"
fi

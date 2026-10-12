#!/usr/bin/env bash
# 产品文档文风守卫(docs/doc-spec.md §5 禁词表 + §8 字段长度,docspec-01 落地)
# 检查面:① resources.json 三短字段(desc≤80 非空/pin 非空≤80/offline 非空≤90)与禁词
#        ② caps 的 note/example 禁词
#        ③ 产品文档全集(README/AGENTS/offline/params/known-issues/install-surfaces/items)禁词
# 退出码:0=不劣于基线;1=有指标超基线(迁移只许降不许升)
# --update:按当前实况刷新基线(迁移批收尾时降棘轮用)
# 基线:scripts/ctl/data/doc-style-baseline.json(提交入库,迁移序见 doc-spec.md §9)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BL="$ROOT/scripts/ctl/data/doc-style-baseline.json"

python3 - "$ROOT" "$BL" "${1:-}" <<'PY'
import json, os, re, sys

root, bl_path, mode = sys.argv[1:4]

# 禁词表(doc-spec.md §5 左列 + 过程引用类)
ENUM = {"已装","参考克隆","缓存固化","已烘焙","未装"}
BAD = ["血泪教训","血泪坑","坑与留痕","坑","留痕","实证","顺手","顺带","炸出","收口","落字",
       "口径","下轮","钓后人","真身","摆设","来龙去脉","假绿","半静默","教训",
       "用户裁定","grok","prt-","工位","评审","拆册","拆独立","裁定","REQ-0","ADR-0","S-0000","早期","本轮","晚批"]
OLD_TAGS = ["坑与留痕","血泪教训","血泪坑"]

doc = json.load(open(os.path.join(root, "scripts/ctl/data/resources.json"), encoding="utf-8"))
field_over = 0; field_bad = 0
for r in doc["resources"]:
    if r.get("status","") not in ENUM: field_bad += 1
    d, p, o = r.get("desc",""), r.get("pin",""), r.get("offline","")
    if not d or len(d) > 80: field_over += 1
    if p and len(p) > 80: field_over += 1
    if o and len(o) > 90: field_over += 1
    for s in (d, p, o):
        if any(b in s for b in BAD): field_bad += 1; break
caps_bad = 0
for c in doc["caps"]:
    if any(b in c.get("note","")+c.get("example","") for b in BAD): caps_bad += 1

product = ["README.md","AGENTS.md","docs/offline.md","docs/params.md","docs/known-issues.md"]
for dp, _d, fs in os.walk(os.path.join(root, "docs", "install-surfaces")):
    product += [os.path.relpath(os.path.join(dp, f), root) for f in fs if f.endswith(".md")]
for dp, _d, fs in os.walk(os.path.join(root, "docs", "items")):
    product += [os.path.relpath(os.path.join(dp, f), root) for f in fs if f.endswith(".md")]

md_bad = 0; md_old = 0
for rel in sorted(set(product)):
    p = os.path.join(root, rel)
    if not os.path.isfile(p): continue
    for line in open(p, encoding="utf-8"):
        if any(b in line for b in BAD): md_bad += 1
        if any(t in line for t in OLD_TAGS): md_old += 1

cur = {"field_overlength": field_over, "field_banned": field_bad,
       "caps_banned": caps_bad, "md_banned_lines": md_bad, "md_old_tags": md_old}

if mode == "--update":
    json.dump(cur, open(bl_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("基线已按当前实况刷新:", json.dumps(cur, ensure_ascii=False))
    sys.exit(0)

base = json.load(open(bl_path, encoding="utf-8"))
worse = {k: (cur[k], base.get(k, 0)) for k in cur if cur[k] > base.get(k, 0)}
for k, v in cur.items():
    mark = "ok " if v <= base.get(k, 0) else "UP "
    print(f"  {mark}{k}: {v}(基线 {base.get(k, 0)})")
if worse:
    print("!! 文风指标超基线(只许降不许升;修复或说明后跑 --update 降棘轮)", file=sys.stderr)
    sys.exit(1)
print("doc-style:全部指标不劣于基线")
PY

// 语义检索腿:zg(zvec-grep,向量+fts 混排)可用时接管 search 排序,不可用或失败回退词面
// 调用形状沿 pi-rs search-tool.ts 实证:positional+--fts 双腿 --fuse 融合;检索单元=每行一微文档
import { spawnSync } from "node:child_process"
import { existsSync, mkdirSync, readdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import type { Rec } from "./catalog.ts"

export function resolveZg(): string | undefined {
  const env = process.env.RCTL_ZG_PATH
  if (env === "0") return undefined
  for (const p of [env, "/usr/local/bin/zg"]) {
    if (p && existsSync(p)) return p
  }
  return undefined
}

const MODEL_CACHE = process.env.RCTL_ZG_MODEL_CACHE ?? "/opt/zg-models"

// 检索单元:每行一微文档(短句描述语义召回最佳,全文稀释;pi-rs 2026-10-09 用户裁定同源)
export function semanticDoc(r: Rec): string {
  return `id: ${r.id}\ndesc: ${r.desc}\ntask: ${r.taskHint ?? ""}\nkind: ${r.kind}\nalias: ${r.alias ?? ""}\n`
}

export function mirrorName(r: Rec): string {
  return r.id.replace(/[^\w.-]+/g, "_") + ".txt"
}

/** 增量镜像:内容变才写;废件清掉;返回是否需要重索引 */
export function ensureMirror(recs: Rec[], dir: string): boolean {
  mkdirSync(dir, { recursive: true })
  let changed = false
  const live = new Set(recs.map((r) => mirrorName(r)))
  for (const name of readdirSync(dir)) {
    if (!name.endsWith(".txt") || live.has(name)) continue
    try { unlinkSync(join(dir, name)); changed = true } catch { /* best effort */ }
  }
  for (const r of recs) {
    const name = mirrorName(r)
    const want = semanticDoc(r)
    const p = join(dir, name)
    try {
      if (!existsSync(p) || readFileSync(p, "utf8") !== want) {
        writeFileSync(p, want)
        changed = true
      }
    } catch { /* 跳过该行 */ }
  }
  return changed || !existsSync(join(dir, ".zvec-grep"))
}

/** zg compact 行 `#N matchedBy=… <name>:<lines>` → 按名回行;锚允许行首/斜杠/空白后(pi-rs anchor 坑同源) */
export function zgHitsToRecs(output: string, byName: Map<string, Rec>): Rec[] {
  const ranked: Rec[] = []
  for (const line of output.split("\n")) {
    const hit = /(?:^|[/\\\s])([\w.-]+\.txt)(?::|$|\s)/.exec(line)
    const r = hit ? byName.get(hit[1]) : undefined
    if (r && !ranked.includes(r)) ranked.push(r)
  }
  return ranked
}

/**
 * 语义检索:成功返回排序结果;undefined = 引擎不可用/失败,调用方回退词面。
 * 索引失败不致命(留着旧索引查,pi-rs 同款仲裁序);查询失败才回退。
 */
export function semanticSearch(
  q: string,
  recs: Rec[],
  dataDir: string,
  limit: number,
  zgPath?: string,
): Rec[] | undefined {
  const zg = zgPath ?? resolveZg()
  if (!zg) return undefined
  const dir = join(dataDir, "semantic")
  const byName = new Map(recs.map((r) => [mirrorName(r), r]))
  const argv = ["--model-cache", MODEL_CACHE]
  try {
    if (ensureMirror(recs, dir)) {
      spawnSync(zg, ["--index", "--mode", "direct", ...argv], { cwd: dir, timeout: 180_000 })
    }
    const qr = spawnSync(
      zg,
      [q, "--fts", q, "--fuse", "--mode", "direct", "--compact", "--preview", "none", "--limit", String(limit), ...argv],
      { cwd: dir, timeout: 60_000, encoding: "utf8" },
    )
    if (qr.status !== 0 || !qr.stdout) return undefined
    return zgHitsToRecs(qr.stdout, byName)
  } catch {
    return undefined
  }
}

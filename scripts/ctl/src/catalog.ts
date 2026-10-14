// 能力表(catalog.tsv 册投影)+ 能力词典(caps.tsv):烤库只读消费,真相在 docs/items/
import { join, dirname } from "node:path"
import { existsSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { resolveZg, semanticSearch } from "./semantic.ts"

export interface Rec {
  id: string; kind: string; group: string; status: string
  desc: string; pin: string; path: string; offline: string; book: string
  alias?: string
  env?: string
  taskHint?: string
  capPrimary?: boolean // 能力词典 ids 首位=样例工具(与 example 列同源)
}

export interface Cap {
  task: string; ids: string; example: string; note: string
}

export function dataDir(): string {
  const env = process.env.RCTL_HOME
  if (env && existsSync(join(env, "catalog.tsv"))) return env
  const dev = join(dirname(dirname(fileURLToPath(import.meta.url))), "data")
  if (existsSync(join(dev, "catalog.tsv"))) return dev
  return "/var/lib/rctl"
}

function loadTsv(name: string): string[][] {
  const p = join(dataDir(), name)
  if (!existsSync(p)) return []
  return readFileSync(p, "utf-8").split("\n")
    .map((l) => l.trimEnd())
    .filter((l) => l.length > 0 && !l.startsWith("#"))
    .map((l) => l.split("\t").map((f) => f.trim()))
}

export function catalog(): Rec[] {
  return loadTsv("catalog.tsv").map((f) => ({
    id: f[0] ?? "", kind: f[1] ?? "tool", group: f[2] ?? "", status: f[3] ?? "",
    desc: f[4] ?? "", pin: f[5] ?? "", path: f[6] ?? "", offline: f[7] ?? "", book: f[8] ?? "",
    alias: f[9] ?? "",
    env: f[10] ?? "",
  }))
}

export function caps(): Cap[] {
  return loadTsv("caps.tsv").map((f) => ({
    task: f[0] ?? "", ids: f[1] ?? "", example: f[2] ?? "", note: f[3] ?? "",
  }))
}

function scoreOne(r: Rec, t: string): number {
  let hit = 0
  if (r.id.toLowerCase().includes(t)) hit += 10
  if (r.alias && r.alias.toLowerCase().includes(t)) hit += 9
  if (r.desc.toLowerCase().includes(t)) hit += 6
  if (r.group.toLowerCase().includes(t)) hit += 3
  if (r.taskHint && r.taskHint.includes(t)) hit += 8
  return hit
}

export function score(r: Rec, q: string): number {
  const terms = q.toLowerCase().split(/\s+/).filter(Boolean)
  if (terms.length === 0) return 0
  let s = 0
  for (const t of terms) {
    const hit = scoreOne(r, t)
    if (hit === 0) return 0 // 全词件命中才算结果
    s += hit
  }
  // 整句任务词加成:能力词典 task 覆盖完整问句时,该族应排到词面命中之上;词典样例再抬一手
  if (r.taskHint && r.taskHint.includes(q.toLowerCase())) {
    s += 4
    if (r.capPrimary) s += 2
  }
  return s
}

// caps 词典任务词参与 search 命中(能力问句);ids 首位标为词典样例
export function withTaskHints(recs: Rec[], capList: Cap[]): Rec[] {
  const byId = new Map(recs.map((r) => [r.id, r]))
  for (const c of capList) {
    const ids = c.ids.split(",").map((x) => x.trim()).filter(Boolean)
    ids.forEach((id, i) => {
      const r = byId.get(id)
      if (!r) return
      r.taskHint = (r.taskHint ? r.taskHint + " " : "") + c.task.toLowerCase()
      if (i === 0) r.capPrimary = true
    })
  }
  return recs
}

export function search(q: string, kind: string | undefined, limit: number, env?: string): Rec[] {
  return searchWithEngine(q, kind, limit, env).hits
}

/** 语义腿优先(zg 在则接管排序,kind/env 过滤在排序后),失败或无 zg 回退词面;engine 供输出面标注 */
export function searchWithEngine(
  q: string,
  kind: string | undefined,
  limit: number,
  env?: string,
): { hits: Rec[]; engine: "zvec" | "lexical" } {
  const all = withTaskHints(catalog(), caps())
  const zgPath = resolveZg()
  const pool = all.filter((r) => (!kind || r.kind === kind) && (!env || r.env === env))
  const lexScored = pool.map((r) => ({ r, s: score(r, q) })).filter((x) => x.s > 0).sort((a, b) => b.s - a.s)
  if (zgPath) {
    const sem = semanticSearch(q, all, dataDir(), limit, zgPath)
    if (sem) {
      // 外层 RRF 融合(2026-10-14):zg 内部融 vec+fts,但词面腿的 id 精确/词权重信号
      // 仍会在语义裸排里被同 desc 家族淹没(frida 12 兄弟挤掉裸名)或主题漂移
      // (隧道族掉出转发语义 top-8);两腿名次倒数融合,再叠 id 精确锚
      const K = 60
      const rrf = new Map<string, number>()
      sem.forEach((r, i) => rrf.set(r.id, (rrf.get(r.id) ?? 0) + 1 / (K + i)))
      lexScored.forEach((x, i) => rrf.set(x.r.id, (rrf.get(x.r.id) ?? 0) + 1 / (K + i)))
      const byId = new Map(all.map((r) => [r.id, r]))
      const merged = [...rrf.keys()].map((id) => byId.get(id)).filter((r): r is Rec => !!r)
      const k = q.trim().toLowerCase()
      const exact = merged.find((r) => r.id.toLowerCase() === k)
      const ordered = exact ? [exact, ...merged.filter((r) => r !== exact)] : merged
      const hits = ordered.slice(0, limit)
      if (hits.length > 0) return { hits, engine: "zvec" }
      // 语义命中被 kind/env 过滤光时仍回退词面,保过滤语义与词面一致
    }
  }
  return {
    hits: pool
      .map((r) => ({ r, s: score(r, q) }))
      .filter((x) => x.s > 0)
      .sort((a, b) => b.s - a.s)
      .slice(0, limit)
      .map((x) => x.r),
    engine: "lexical",
  }
}

export function show(id: string): Rec | undefined {
  const k = id.toLowerCase()
  return catalog().find((r) => r.id.toLowerCase() === k)
}

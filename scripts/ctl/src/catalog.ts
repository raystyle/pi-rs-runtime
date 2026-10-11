// 能力表(catalog.tsv 册投影)+ 能力词典(caps.tsv):烤库只读消费,真相在 docs/items/
import { join, dirname } from "node:path"
import { existsSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

export interface Rec {
  id: string; kind: string; group: string; status: string
  desc: string; pin: string; path: string; offline: string; book: string
  alias?: string
  env?: string
  taskHint?: string
}

export interface Cap {
  task: string; ids: string; example: string; note: string
}

function dataDir(): string {
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
  return s
}

// caps 词典任务词参与 search 命中(能力问句)
export function withTaskHints(recs: Rec[], capList: Cap[]): Rec[] {
  const byId = new Map(recs.map((r) => [r.id, r]))
  for (const c of capList) {
    for (const id of c.ids.split(",").map((x) => x.trim()).filter(Boolean)) {
      const r = byId.get(id)
      if (r) r.taskHint = (r.taskHint ? r.taskHint + " " : "") + c.task.toLowerCase()
    }
  }
  return recs
}

export function search(q: string, kind: string | undefined, limit: number, env?: string): Rec[] {
  const all = withTaskHints(catalog(), caps())
  const pool = all.filter((r) => (!kind || r.kind === kind) && (!env || r.env === env))
  return pool
    .map((r) => ({ r, s: score(r, q) }))
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .slice(0, limit)
    .map((x) => x.r)
}

export function show(id: string): Rec | undefined {
  const k = id.toLowerCase()
  return catalog().find((r) => r.id.toLowerCase() === k)
}

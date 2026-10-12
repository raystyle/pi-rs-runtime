// audit:资源对账(prt-07 件2)。左集=/usr/local/bin 与 /opt 顶层;右集=catalog(id/path/alias)
// 只读不写;class 闭集 ok/alias/exempt/missing-id/missing-path/stale;退出码 0=干净 1=有未解释项
import { readdirSync, statSync, readlinkSync, existsSync } from "node:fs"
import { catalog, type Rec } from "./catalog.ts"

export interface AuditRow {
  name: string; side: "bin" | "opt"; class: string
  id?: string; book?: string; note: string
}

const CLASSES = ["ok", "alias", "exempt", "missing-id", "missing-path", "stale"] as const

export function audit(): { rows: AuditRow[]; summary: Record<string, number> } {
  const rows: AuditRow[] = []
  const cat = catalog()
  // id 匹配大小写折叠(bloodyAD/bloodyad、Coercer/coercer 同物)
  const byId = new Map<string, Rec>()
  for (const r of cat) { const k = r.id.toLowerCase(); if (!byId.has(k)) byId.set(k, r) }
  const byAlias = new Map<string, Rec>()
  for (const r of cat) if (r.alias) { const k = r.alias.toLowerCase(); if (!byAlias.has(k)) byAlias.set(k, r) }
  // 认领口径:册行任意字段里出现 /opt/<名>(册提及即认领;阶段 2 生成器补 path 列后收紧)
  const optClaimed = new Set<string>()
  for (const r of cat) {
    const joined = [r.path, r.desc, r.pin, r.offline, r.book].join(" ")
    for (const m of joined.matchAll(/\/opt\/([A-Za-z0-9_.-]+)/g)) optClaimed.add(m[1])
  }

  // 左集一:/usr/local/bin
  let ents: string[] = []
  try { ents = readdirSync("/usr/local/bin") } catch { ents = [] }
  for (const name of ents.sort()) {
    const abs = `/usr/local/bin/${name}`
    let target = ""
    try { target = readlinkSync(abs) } catch { target = "" }
    const r = byId.get(name.toLowerCase())
    if (r) { rows.push({ name, side: "bin", class: "ok", id: r.id, book: r.book, note: "册认领" }); continue }
    const a = byAlias.get(name.toLowerCase())
    if (a) { rows.push({ name, side: "bin", class: "alias", id: a.id, book: a.book, note: `改名→${a.id}` }); continue }
    // wrapper-body:*.real 真身,剥名后是登记入口
    if (name.endsWith(".real")) {
      const stem = name.slice(0, -5)
      if (byId.has(stem.toLowerCase())) { const b = byId.get(stem.toLowerCase())!; rows.push({ name, side: "bin", class: "exempt", id: b.id, book: b.book, note: "wrapper 真身" }); continue }
    }
    // shim:软链目标落在已登记本体下(uv-tools/dotnet-tools/re-venv 的入口)
    if (target) {
      const m = target.match(/^\/opt\/(uv-tools|dotnet-tools|re-venv|go)\/([^/]+)/)
      if (m && (byId.has(name.toLowerCase()) || byId.has(m[2].toLowerCase()) || m[2] === "bin")) {
        const key = byId.has(name.toLowerCase()) ? name.toLowerCase() : m[2].toLowerCase()
        rows.push({ name, side: "bin", class: "ok", id: byId.get(key)?.id ?? name, book: byId.get(key)?.book, note: `shim→${target.slice(0, 60)}` })
        continue
      }
    }
    rows.push({ name, side: "bin", class: "missing-id", note: "无册认领" })
  }

  // 左集二:/opt 顶层(不递归)
  let opts: string[] = []
  try { opts = readdirSync("/opt") } catch { opts = [] }
  for (const name of opts.sort()) {
    if (optClaimed.has(name)) {
      rows.push({ name, side: "opt", class: "ok", note: "册内安装路径已登记" })
      continue
    }
    rows.push({ name, side: "opt", class: "missing-id", note: "/opt 顶层无册认领" })
  }

  // 右集补充:声明了 path 的行,盘上不在 → stale
  for (const r of cat) {
    if (!r.path) continue
    if (!existsSync(r.path) && !existsSync(r.path.replace(/\/[^/]+$/, ""))) {
      rows.push({ name: r.path, side: "opt", class: "stale", id: r.id, book: r.book, note: "声明的路径不在盘上" })
    }
  }

  const summary: Record<string, number> = {}
  for (const c of CLASSES) summary[c] = 0
  for (const r of rows) summary[r.class] = (summary[r.class] ?? 0) + 1
  return { rows, summary }
}

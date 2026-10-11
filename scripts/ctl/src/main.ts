// rctl:pi runtime 实例总 ctl(agent 第一入口)
// 裸调用 = 渐进提示面板 exit 0;退出码 0/1/2;错误 stderr 单行 JSON(结构化时)
import { COMMANDS, RCTL_VERSION, renderLlms, renderHelp, schemaFor } from "./commands.ts"
import { emitOk, die, type CtaItem } from "./envelope.ts"
import { catalog, caps, search, show, withTaskHints } from "./catalog.ts"
import { where, buildLib, loadLib } from "./paths.ts"
import { envFace } from "./envface.ts"
import { agentsFace } from "./agents.ts"
import { audit } from "./audit.ts"

const args = process.argv.slice(2)

// ---- 全局旗标解析(七件) ----
interface Opts {
  format: "toon" | "json" | "yaml" | "md"
  filter?: string[]
  full: boolean
  json: boolean
  llms: boolean
  schema: boolean
  help: boolean
  kind?: string
  limit: number
}
const o: Opts = { format: "toon", full: false, json: false, llms: false, schema: false, help: false, limit: 20 }
const positional: string[] = []
for (let i = 0; i < args.length; i++) {
  const a = args[i]
  if (a === "--json") o.json = true
  else if (a === "--full-output") o.full = true
  else if (a === "--llms" || a === "--llms-full") o.llms = true
  else if (a === "--schema") o.schema = true
  else if (a === "--help" || a === "-h") o.help = true
  else if (a === "--version" || a === "-V") { console.log(RCTL_VERSION); process.exit(0) }
  else if (a === "--format") o.format = (args[++i] ?? "toon") as Opts["format"]
  else if (a.startsWith("--format=")) o.format = a.slice(9) as Opts["format"]
  else if (a === "--filter-output") o.filter = (args[++i] ?? "").split(",").map((s) => s.trim()).filter(Boolean)
  else if (a.startsWith("--filter-output=")) o.filter = a.slice(16).split(",").map((s) => s.trim()).filter(Boolean)
  else if (a === "--kind") o.kind = args[++i]
  else if (a === "--class") (o as any).class = args[++i]
  else if (a.startsWith("--class=")) (o as any).class = a.slice(8)
  else if (a.startsWith("--kind=")) o.kind = a.slice(7)
  else if (a === "--limit") o.limit = Number(args[++i] ?? 20)
  else if (a.startsWith("--limit=")) o.limit = Number(a.slice(8))
  else if (a.startsWith("-")) die("usage", `未知旗标 ${a}`, o.json, 2, usageCta())
  else positional.push(a)
}
if (o.json) o.format = "json"
const structured = o.format === "json" || o.full

function usageCta(): CtaItem[] {
  return [{ command: "rctl --llms", description: "读手册(命令、旗标、信封、退出码)" }]
}

const t0 = Date.now()
const cmd = positional[0]
const rest = positional.slice(1)

function done(data: unknown, cta: CtaItem[], command: string): void {
  emitOk(data, { format: o.format, filter: o.filter, full: o.full, command, durationMs: Date.now() - t0 }, cta)
  process.exit(0)
}
function nohit(what: string, cta: CtaItem[]): void {
  if (structured) {
    process.stderr.write(JSON.stringify({ code: "no_match", message: `${what} 未命中` }) + "\n")
  } else {
    process.stderr.write(`rctl: ${what} 未命中\n`)
    if (cta.length) {
      console.log(cta.length > 1 ? "Suggested commands:" : "Suggested command:")
      for (const c of cta) console.log(`  ${c.command} - ${c.description}`)
    }
  }
  process.exit(1)
}

// ---- 面/help/llms/schema(无子命令) ----
if (!cmd || o.help) {
  if (o.llms) { console.log(renderLlms()); process.exit(0) }
  if (o.schema) { console.log(JSON.stringify(schemaFor(undefined), null, 0)); process.exit(0) }
  if (o.help || !cmd) {
    // 裸调用:渐进提示面板(实例态一行 + 分类计数 + CTA),exit 0 不交互
    const cat = withTaskHints(catalog(), caps())
    const byKind = new Map<string, number>()
    for (const r of cat) byKind.set(r.kind, (byKind.get(r.kind) ?? 0) + 1)
    const env = envFace()
    const lib = loadLib()
    const kinds = [...byKind.entries()].sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k}=${n}`).join("  ")
    const ag = agentsFace()
    const agLine = ag.map((a) => `${a.binary}:${a.cred_present || a.auth_env_present ? "挂载" : "未挂"}`).join("  ")
    const panel = {
      rctl: RCTL_VERSION,
      instance: { net_eth0: env.net.eth0, offline_default: env.net.offline_default },
      catalog: { records: cat.length, kinds, caps: caps().length },
      path_lib: lib ? `${lib.count} 条(${lib.generated_at})` : "未建(跑 rctl index)",
      next: [
        "rctl search <能力词>    找资源",
        "rctl caps [任务]        拿任务配方",
        "rctl show <id>          单件全息",
        "rctl env                实例态全息",
        "rctl --llms             agent 手册",
      ].join("\n"),
    }
    if (structured) {
      done({ ...panel, agents: ag.map((a) => ({ id: a.id, version: a.version, mounted: a.cred_present || a.auth_env_present })) }, usageCta(), "rctl")
      process.exit(0)
    }
    console.log(`rctl ${RCTL_VERSION} ｜ net.eth0=${env.net.eth0} ｜ 资源 ${cat.length} 件(${kinds}) ｜ 能力 ${caps().length} 条 ｜ agents ${agLine}`)
    console.log("")
    console.log("Next:")
    for (const c of usageCta().concat([
      { command: "rctl search <能力词>", description: "能力问句搜资源" },
      { command: "rctl caps", description: "能力词典(任务到资源组合)" },
      { command: "rctl env", description: "实例态(网络/端口/快失败面)" },
      { command: "rctl agents", description: "agent CLIs 挂载态" },
    ])) console.log(`  ${c.command} - ${c.description}`)
    if (!lib) console.log(`  rctl index - 路径库未建,where 将现场扫描`)
    process.exit(0)
  }
}
if (o.llms) { console.log(renderLlms()); process.exit(0) }

// ---- 子命令分派 ----
const known = COMMANDS.find((c) => c.name === cmd)
if (!known) {
  die("usage", `未知命令 ${cmd ?? ""}`, structured, 2, [
    { command: "rctl", description: "面板与下一步" },
    ...usageCta(),
  ])
}
if (o.help) { console.log(renderHelp()); process.exit(0) }
if (o.llms) { console.log(renderLlms()); process.exit(0) }
if (o.schema) { console.log(JSON.stringify(schemaFor(cmd))); process.exit(0) }

switch (cmd) {
  case "search": {
    const q = rest.join(" ")
    if (!q) die("usage", "search 需要查询词", structured, 2, [{ command: "rctl search hash", description: "示例" }])
    const hits = search(q, o.kind, o.limit)
    if (hits.length === 0) nohit(`search ${q}`, [
      { command: `rctl search ${q.split(/\s+/)[0]}`, description: "放宽到单词" },
      { command: "rctl caps", description: "改走能力词典" },
    ])
    done(hits.map((r) => ({ id: r.id, kind: r.kind, status: r.status, desc: r.desc.slice(0, 80), group: r.group })), [
      { command: `rctl show ${hits[0].id}`, description: "下钻第一名" },
    ], "search")
    break
  }
  case "where": {
    const q = rest.join(" ")
    if (!q) die("usage", "where 需要路径词", structured, 2, [{ command: "rctl where rockyou", description: "示例" }])
    const hits = where(q, o.limit)
    if (hits.length === 0) nohit(`where ${q}`, [
      { command: "rctl index", description: "刷路径库后再试" },
    ])
    done(hits, [{ command: `rctl show ${(hits[0].path.match(/([a-zA-Z0-9_-]+)/g) ?? [""])[0]}`, description: "看相关件" }], "where")
    break
  }
  case "show": {
    const id = rest[0]
    if (!id) die("usage", "show 需要 id", structured, 2, [{ command: "rctl show nuclei", description: "示例" }])
    const r = show(id)
    if (!r) nohit(`show ${id}`, [{ command: `rctl search ${id}`, description: "改搜" }])
    const capRefs = caps().filter((c) => c.ids.split(",").map((x) => x.trim()).includes(r!.id))
    done({ ...r, in_caps: capRefs.map((c) => c.task) }, [
      { command: `rctl docs ${r!.id}`, description: "册投影全文" },
    ], "show")
    break
  }
  case "caps": {
    const list = caps()
    const q = rest.join(" ")
    if (!q) {
      done(list.map((c) => ({ task: c.task, ids: c.ids, note: c.note.slice(0, 60) })), [
        { command: "rctl caps 破解hash", description: "示例:取一个配方" },
      ], "caps")
    }
    const hits = list.filter((c) => q.toLowerCase().split(/\s+/).every((t) =>
      (c.task + " " + c.ids + " " + c.note).toLowerCase().includes(t)))
    if (hits.length === 0) nohit(`caps ${q}`, [{ command: "rctl caps", description: "列全部任务词" }])
    const first = hits[0]
    const ids = first.ids.split(",").map((x) => x.trim())
    done({
      task: first.task,
      resources: ids.map((id) => {
        const r = show(id)
        return r ? { id, status: r.status, path: r.path } : { id, status: "catalog 缺此 id(词典漂移)" }
      }),
      example: first.example,
      note: first.note,
    }, [{ command: first.example.split("\n")[0], description: "配方首行命令" }], "caps")
    break
  }
  case "agents": {
    const ag = agentsFace()
    const mounted = ag.filter((a) => a.cred_present || a.auth_env_present).length
    done(ag, [
      { command: "rctl show rctl", description: "实例总控册" },
      ...(mounted === 0 ? [{ command: "rctl docs agents", description: "挂载法(凭证不进镜像)" }] : []),
    ], "agents")
    break
  }
  case "env":
    done(envFace(), [{ command: "rctl --llms", description: "手册" }], "env")
    break
  case "docs": {
    const q = rest.join(" ")
    if (!q) die("usage", "docs 需要 id/组/查询词", structured, 2, [{ command: "rctl docs zig", description: "示例" }])
    const all = catalog()
    const hits = all.filter((r) =>
      q.toLowerCase().split(/\s+/).every((t) =>
        (r.id + " " + r.group + " " + r.desc + " " + r.book).toLowerCase().includes(t)))
    if (hits.length === 0) nohit(`docs ${q}`, [{ command: `rctl search ${q}`, description: "改能力问句" }])
    done(hits.map((r) => ({ id: r.id, book: r.book, offline: r.offline.slice(0, 90), pin: r.pin.slice(0, 80) })), [
      { command: `rctl show ${hits[0].id}`, description: "单件全息" },
    ], "docs")
    break
  }
  case "audit": {
    const { rows, summary } = audit()
    const bad = rows.filter((r) => r.class !== "ok" && r.class !== "alias" && r.class !== "exempt").length
    const cls = o.kind // 复用解析槽位:--kind 未给时当 --class 用
    const shown = o.class ?? undefined
    const data = shown ? rows.filter((r) => r.class === shown) : rows
    if (o.format === "json") {
      emitOk({ summary, rows: data }, { format: "json", filter: o.filter, full: o.full, command: "audit", durationMs: Date.now() - t0 }, [])
      process.exit(bad > 0 ? 1 : 0)
    }
    console.log(`summary: ${Object.entries(summary).map(([k, v]) => `${k}=${v}`).join("  ")}`)
    for (const r of data) {
      if (r.class === "ok" && !shown) continue // 人读默认只看未解释项
      console.log(`${r.class.padEnd(11)} ${r.side.padEnd(3)} ${r.name}${r.id ? ` (${r.id})` : ""} - ${r.note}`)
    }
    if (bad > 0) {
      process.stderr.write(`rctl: ${bad} 个未解释项(missing-id/stale)
`)
      process.exit(1)
    }
    process.exit(0)
    break
  }
  case "index": {
    const lib = buildLib()
    done({ generated_at: lib.generated_at, count: lib.count, lib: loadLib !== undefined ? "paths.json" : "" }, [
      { command: "rctl where rockyou", description: "试路径问句" },
    ], "index")
    break
  }
}

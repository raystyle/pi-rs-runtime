// acpsup:ACP 监督进程(实例标准 agent 接入通道,S-0002)
// 形态:实例内常驻;ACP Client 经 stdio 拉起适配器子进程;平台面仅回环 HTTP + Bearer token
// 生命周期:不依赖信号(/shutdown 端点或 --selftest 自终止),适配宿主信号策略(known-issues)
import { AcpAgent } from "./acpclient.ts"
import { fsReadTextFile, fsWriteTextFile, Terminals } from "./fsimpl.ts"
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs"
import { join } from "node:path"
import { readFile } from "node:fs/promises"

const VERSION = "0.1.0"

// ---- 参数 ----
const args = process.argv.slice(2)
const opt: Record<string, string> = {}
for (let i = 0; i < args.length; i++) {
  const a = args[i]
  if (a.startsWith("--")) opt[a.slice(2)] = args[++i] ?? "true"
}
const PORT = Number(opt.port ?? 7663)
const DATA_DIR = opt["data-dir"] ?? "/var/lib/acpsup"
const SELFTEST = "selftest" in opt
const ADAPTER_ROOT = "/opt/node/lib/node_modules/@agentclientprotocol"

// ---- token(首启随机,0600,打印一次;不进镜像) ----
function ensureToken(): string {
  mkdirSync(DATA_DIR, { recursive: true })
  const p = join(DATA_DIR, "token")
  if (existsSync(p)) return readFileSync(p, "utf-8").trim()
  const tok = Array.from({ length: 24 }, () => Math.random().toString(36)[2] ?? "x").join("")
  writeFileSync(p, tok + "\n", { mode: 0o600 })
  console.log(`acpsup token(打印一次):${tok}`)
  return tok
}

// ---- 适配器注册表:从各包 package.json 的 bin 解析入口(对布局变化稳) ----
async function adapterEntry(pkg: string): Promise<string> {
  const pj = JSON.parse(await readFile(join(ADAPTER_ROOT, pkg, "package.json"), "utf-8"))
  const bin = typeof pj.bin === "string" ? pj.bin : (Object.values(pj.bin ?? {})[0] as string)
  return join(ADAPTER_ROOT, pkg, bin)
}

interface AgentDef { name: string; pkg: string; env: Record<string, string>; ready: boolean; entry?: string; err?: string }
const registry: AgentDef[] = [
  { name: "claude", pkg: "claude-agent-acp", env: { DISABLE_UPDATES: "1" }, ready: false },
  { name: "codex", pkg: "codex-acp", env: { CODEX_PATH: "/usr/local/bin/codex", NO_BROWSER: "1" }, ready: false },
]
for (const a of registry) {
  try { a.entry = await adapterEntry(a.pkg); a.ready = true } catch (e) { a.err = String(e) }
}

// ---- 会话与事件 ----
interface Session {
  id: string; agent: string; cwd: string
  agent_: AcpAgent
  events: unknown[]
  subs: Set<(ev: unknown) => void>
}
const sessions = new Map<string, Session>()
const terms = new Terminals()

function broadcast(s: Session, ev: unknown) {
  s.events.push(ev)
  if (s.events.length > 2000) s.events.shift()
  for (const sub of s.subs) sub(ev)
}

// ---- 权限应答簿(平台 120 秒不应答即 cancelled,禁 allow_always 空窗) ----
interface PermSlot { ok: (r: unknown) => void; err: (c: number, m: string) => void; done?: boolean }
const permissionReplies = new Map<string, PermSlot>()

// ---- ACP 装配:fs/terminal/permission 回调(实例内真实现) ----
function wire(agent: AcpAgent, s: Session) {
  agent.onUpdate = (sid, update) => { if (sid === s.id) broadcast(s, { kind: "session/update", update }) }
  agent.onServerRequest = (method, params, ok, err) => {
    try {
      switch (method) {
        case "fs/read_text_file": ok(fsReadTextFile(params)); break
        case "fs/write_text_file": ok(fsWriteTextFile(params)); break
        case "terminal/create": ok(terms.create(params)); break
        case "terminal/output": ok(terms.output(params)); break
        case "terminal/wait_for_exit": terms.waitForExit(params).then(ok, (e) => err(-32000, String(e))); break
        case "terminal/kill": {
          try { terms.kill(params); ok({}) } catch (e) { err(-32000, String(e)) }
          break
        }
        case "terminal/release": ok(terms.release(params)); break
        case "session/request_permission": {
          const reqId = `perm-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
          broadcast(s, { kind: "permission", requestId: reqId, request: params })
          const slot: PermSlot = { ok, err }
          permissionReplies.set(reqId, slot)
          setTimeout(() => {
            const pending = permissionReplies.get(reqId)
            if (pending && !pending.done) {
              pending.done = true
              permissionReplies.delete(reqId)
              try { ok({ outcome: { outcome: "cancelled" } }) } catch { /* 适配器可能已关 */ }
            }
          }, 120_000)
          break
        }
        default:
          err(-32601, `acpsup 未实现 ${method}`)
      }
    } catch (e) {
      err(-32000, String(e))
    }
  }
}

// ---- 平台 HTTP 面(仅回环 + Bearer,默认拒绝) ----
const token = ensureToken()

function json(code: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status: code, headers: { "content-type": "application/json" } })
}

const server = Bun.serve({
  port: PORT,
  hostname: "127.0.0.1",
  async fetch(req) {
    const url = new URL(req.url)
    if (req.headers.get("authorization") !== `Bearer ${token}`) return json(401, { error: "unauthorized" })
    const path = url.pathname

    if (path === "/health" && req.method === "GET") {
      return json(200, { ok: true, acpsup: VERSION, agents: registry.map((a) => ({ name: a.name, ready: a.ready, err: a.err ?? null })) })
    }

    if (path === "/session/new" && req.method === "POST") {
      const body = await req.json().catch(() => ({})) as { agent?: string; cwd?: string }
      const def = registry.find((a) => a.name === body.agent && a.ready)
      if (!def) return json(400, { error: `未知或未就绪 agent:${body.agent ?? ""}` })
      const cwd = body.cwd && body.cwd.startsWith("/") ? body.cwd : "/tmp"
      const agent = new AcpAgent(def.name, "node", [def.entry!], def.env, cwd)
      const s: Session = {
        id: `pending-${Date.now().toString(36)}`, agent: def.name, cwd, agent_: agent,
        events: [], subs: new Set(),
      }
      wire(agent, s)
      try {
        const init = await agent.request("initialize", {
          protocolVersion: 1,
          clientCapabilities: { fs: { readTextFile: true, writeTextFile: true }, terminal: true },
        }, 30_000)
        const sn = await agent.request<{ sessionId?: string }>("session/new", { cwd, mcpServers: [] }, 30_000)
        if (!sn?.sessionId) throw new Error("适配器未回 sessionId")
        s.id = sn.sessionId
        sessions.set(s.id, s)
        return json(200, { sessionId: s.id, agent: def.name, initialize: init })
      } catch (e) {
        return json(502, { error: String(e), adapterStderr: agent.stderrTail.slice(-5) })
      }
    }

    if (path === "/session/prompt" && req.method === "POST") {
      const body = await req.json().catch(() => ({})) as { sessionId?: string; text?: string }
      const s = sessions.get(body.sessionId ?? "")
      if (!s) return json(404, { error: "无此会话" })
      try {
        const r = await s.agent_.request("session/prompt", {
          sessionId: s.id,
          prompt: [{ type: "text", text: body.text ?? "" }],
        }, 600_000)
        return json(200, { stopReason: r })
      } catch (e) {
        return json(502, { error: String(e), adapterStderr: s.agent_.stderrTail.slice(-5) })
      }
    }

    if (path === "/session/cancel" && req.method === "POST") {
      const body = await req.json().catch(() => ({})) as { sessionId?: string }
      const s = sessions.get(body.sessionId ?? "")
      if (!s) return json(404, { error: "无此会话" })
      s.agent_.notify("session/cancel", { sessionId: s.id })
      return json(200, { ok: true })
    }

    if (path === "/events" && req.method === "GET") {
      const s = sessions.get(url.searchParams.get("sessionId") ?? "")
      if (!s) return json(404, { error: "无此会话" })
      const stream = new ReadableStream({
        start(controller) {
          const enc = new TextEncoder()
          for (const ev of s.events) controller.enqueue(enc.encode(`data: ${JSON.stringify(ev)}\n\n`))
          s.subs.add((ev) => { try { controller.enqueue(enc.encode(`data: ${JSON.stringify(ev)}\n\n`)) } catch { /* 已断 */ } })
        },
      })
      return new Response(stream, { headers: { "content-type": "text/event-stream" } })
    }

    if (path === "/permission" && req.method === "POST") {
      const body = await req.json().catch(() => ({})) as { requestId?: string; optionId?: string }
      const slot = permissionReplies.get(body.requestId ?? "")
      if (!slot || slot.done) return json(404, { error: "无待决权限请求" })
      slot.done = true
      permissionReplies.delete(body.requestId!)
      slot.ok({ outcome: { outcome: "selected", optionId: body.optionId ?? "" } })
      return json(200, { ok: true })
    }

    if (path === "/shutdown" && req.method === "POST") {
      setTimeout(() => { server.stop(true); process.exit(0) }, 50)
      return json(200, { ok: true })
    }

    return json(404, { error: `未知 ${path}` })
  },
})

process.stderr.write(`acpsup ${VERSION} 听 127.0.0.1:${PORT}(token 落 ${DATA_DIR}/token)\n`)

// ---- selftest:协议级 E2E,自终止(信号策略下不可依赖外部 kill) ----
if (SELFTEST) {
  const which = opt.selftest && opt.selftest !== "true" ? opt.selftest : "claude"
  const def = registry.find((a) => a.name === which && a.ready)
  if (!def) { console.error(`selftest FAIL: 适配器 ${which} 未就绪(${registry.find((a) => a.name === which)?.err ?? ""})`); process.exit(1) }
  const agent = new AcpAgent(def.name, "node", [def.entry!], def.env, "/tmp")
  const t0 = Date.now()
  try {
    const init = await agent.request<{ protocolVersion?: number }>("initialize", {
      protocolVersion: 1,
      clientCapabilities: { fs: { readTextFile: true, writeTextFile: true }, terminal: true },
    }, 30_000)
    console.log(`selftest initialize: protocolVersion=${init?.protocolVersion}(${Date.now() - t0}ms)`)
    const sn = await agent.request<{ sessionId: string }>("session/new", { cwd: "/tmp", mcpServers: [] }, 30_000)
    console.log(`selftest session/new: ${sn.sessionId}`)
    try {
      const r = await Promise.race([
        agent.request("session/prompt", { sessionId: sn.sessionId, prompt: [{ type: "text", text: "ping" }] }, 45_000),
        new Promise((_, rej) => setTimeout(() => rej(new Error("45s 超时(无凭证属预期边界)")), 46_000)),
      ])
      console.log(`selftest prompt 回:${JSON.stringify(r).slice(0, 200)}`)
    } catch (e) {
      console.log(`selftest prompt 失败面(无凭证边界,协议面证据):${String(e).slice(0, 200)}`)
    }
    console.log(`selftest PASS(${which})`)
    server.stop(true)
    process.exit(0)
  } catch (e) {
    console.error(`selftest FAIL:${String(e)}`)
    process.exit(1)
  }
}

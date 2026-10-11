// ACP v1 客户端:stdio JSON-RPC 2.0,行分帧(一行一消息)
// 约定:stdout 只有 ACP 消息;stderr 是日志(透传到监督进程 stderr)
import { spawn } from "node:child_process"

export interface JsonRpcMsg { jsonrpc: string; id?: number; method?: string; params?: unknown; result?: unknown; error?: { code: number; message: string } }

export type UpdateHandler = (sessionId: string, update: unknown) => void
export type ServerReqHandler = (method: string, params: any, respond: (result: unknown) => void, respondErr: (code: number, msg: string) => void) => void

export class AcpAgent {
  proc: ReturnType<typeof spawn>
  private nextId = 1
  private pending = new Map<number, { resolve: (v: unknown) => void; reject: (e: Error) => void; timer: ReturnType<typeof setTimeout> }>()
  onUpdate: UpdateHandler = () => {}
  onServerRequest: ServerReqHandler = () => {}
  stderrTail: string[] = []
  name: string

  constructor(name: string, cmd: string, args: string[], env: Record<string, string>, cwd: string) {
    this.name = name
    this.proc = spawn(cmd, args, {
      cwd,
      env: { ...process.env, ...env },
      stdio: ["pipe", "pipe", "pipe"],
    })
    let buf = ""
    this.proc.stdout!.on("data", (d: Buffer) => {
      buf += d.toString("utf-8")
      let nl: number
      while ((nl = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, nl).trim()
        buf = buf.slice(nl + 1)
        if (!line) continue
        try { this.handle(JSON.parse(line)) } catch { this.log(`!! 非 JSON 行:${line.slice(0, 120)}`) }
      }
    })
    this.proc.stderr!.on("data", (d: Buffer) => {
      const t = d.toString("utf-8").trim()
      if (t) { this.log(`[adapter-stderr] ${t.slice(0, 300)}`) }
    })
    this.proc.on("exit", (code) => this.log(`适配器退出 code=${code}`))
  }

  private log(m: string) {
    this.stderrTail.push(m)
    if (this.stderrTail.length > 50) this.stderrTail.shift()
    process.stderr.write(`[acp:${this.name}] ${m}\n`)
  }

  private handle(msg: JsonRpcMsg) {
    if (msg.method !== undefined) {
      // agent -> client:请求或通知
      if (msg.id !== undefined) {
        this.onServerRequest(msg.method, msg.params ?? {},
          (result) => this.send({ jsonrpc: "2.0", id: msg.id, result }),
          (code, message) => this.send({ jsonrpc: "2.0", id: msg.id, error: { code, message } }))
      } else if (msg.method === "session/update") {
        const p = msg.params as { sessionId: string; update: unknown }
        this.onUpdate(p?.sessionId ?? "", p?.update ?? {})
      }
      return
    }
    if (msg.id !== undefined && this.pending.has(msg.id)) {
      const p = this.pending.get(msg.id)!
      clearTimeout(p.timer)
      this.pending.delete(msg.id)
      if (msg.error) p.reject(new Error(`${msg.error.code}: ${msg.error.message}`))
      else p.resolve(msg.result)
    }
  }

  private send(m: JsonRpcMsg) {
    this.proc.stdin!.write(JSON.stringify(m).replace(/\n/g, " ") + "\n")
  }

  request<T = unknown>(method: string, params: unknown, timeoutMs = 120_000): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const id = this.nextId++
      const timer = setTimeout(() => {
        this.pending.delete(id)
        reject(new Error(`请求超时 ${method}`))
      }, timeoutMs)
      this.pending.set(id, { resolve: resolve as (v: unknown) => void, reject, timer })
      this.send({ jsonrpc: "2.0", id, method, params })
    })
  }

  notify(method: string, params: unknown) {
    this.send({ jsonrpc: "2.0", method, params })
  }

  get exited(): Promise<number | null> {
    return new Promise((resolve) => {
      if (this.proc.exitCode !== null) resolve(this.proc.exitCode)
      else this.proc.on("exit", (c) => resolve(c))
    })
  }
}

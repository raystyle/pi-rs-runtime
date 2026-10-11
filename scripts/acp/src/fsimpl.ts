// fs 与 terminal 回调:实例内真实现(这是 agent 吃到完整实例的那条腿)
// 边界:terminal/kill 在宿主信号策略(known-issues)下大概率 EACCES,如实回报
import { spawn } from "node:child_process"
import { readFileSync, writeFileSync, statSync } from "node:fs"
import { dirname } from "node:path"
import { mkdirSync } from "node:fs"

const MAX_READ = 4 * 1024 * 1024
const MAX_WRITE = 8 * 1024 * 1024

export function fsReadTextFile(params: { path: string }): string {
  if (!params.path.startsWith("/")) throw new Error("路径必须绝对路径")
  const st = statSync(params.path)
  if (st.size > MAX_READ) throw new Error(`文件过大 ${st.size}`)
  return readFileSync(params.path, "utf-8")
}

export function fsWriteTextFile(params: { path: string; content: string }): {} {
  if (!params.path.startsWith("/")) throw new Error("路径必须绝对路径")
  if (params.content.length > MAX_WRITE) throw new Error("写入过大")
  mkdirSync(dirname(params.path), { recursive: true })
  writeFileSync(params.path, params.content, "utf-8")
  return {}
}

interface Term {
  id: string; cmd: string[]; cwd: string
  output: string; exited: boolean; exitCode: number | null
  waiters: ((c: number | null) => void)[]
}

export class Terminals {
  private terms = new Map<string, Term>()
  private next = 1

  create(params: { command: string[]; cwd?: string }): { terminalId: string } {
    const id = `t${this.next++}`
    const t: Term = {
      id, cmd: params.command, cwd: params.cwd ?? "/",
      output: "", exited: false, exitCode: null, waiters: [],
    }
    this.terms.set(id, t)
    const child = spawn(params.command[0], params.command.slice(1), {
      cwd: t.cwd,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    })
    const chunk = (d: Buffer) => {
      t.output += d.toString("utf-8")
      if (t.output.length > 1024 * 1024) t.output = t.output.slice(-1024 * 1024)
    }
    child.stdout?.on("data", chunk)
    child.stderr?.on("data", chunk)
    child.on("exit", (c) => {
      t.exited = true; t.exitCode = c
      for (const w of t.waiters) w(c)
    })
    return { terminalId: id }
  }

  output(params: { terminalId: string }): { output: string } {
    const t = this.terms.get(params.terminalId)
    if (!t) throw new Error(`无终端 ${params.terminalId}`)
    return { output: t.output }
  }

  waitForExit(params: { terminalId: string }): Promise<{ exitCode: number | null }> {
    const t = this.terms.get(params.terminalId)
    if (!t) throw new Error(`无终端 ${params.terminalId}`)
    if (t.exited) return Promise.resolve({ exitCode: t.exitCode })
    return new Promise((resolve) => {
      t.waiters.push((c) => resolve({ exitCode: c }))
    })
  }

  async kill(params: { terminalId: string }): Promise<{}> {
    const t = this.terms.get(params.terminalId)
    if (!t) throw new Error(`无终端 ${params.terminalId}`)
    // 宿主信号策略下 kill(2) 恒 EACCES;如实回报,长命命令靠自退或 /shutdown 重启监督进程
    try {
      if (t.exited) return {}
      // 无法投递信号;返回边界说明而不是假装成功
      throw new Error("kill 被宿主信号策略拦(EACCES,known-issues);命令将运行至自然退出")
    } catch (e) {
      throw e
    }
  }

  release(params: { terminalId: string }): {} {
    this.terms.delete(params.terminalId)
    return {}
  }
}

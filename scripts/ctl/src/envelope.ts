// json/yaml/md 渲染与信封;字段序稳定(插入序),错误走 stderr 单行 JSON
export type CtaItem = { command: string; description: string }

function esc(s: string): string {
  return s
    .replace(/\\/g, "\\\\").replace(/"/g, '\\"')
    .replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\t/g, "\\t")
}

export function jstr(v: unknown): string {
  if (v === null || v === undefined) return "null"
  if (typeof v === "number" || typeof v === "boolean") return String(v)
  if (Array.isArray(v)) return "[" + v.map(jstr).join(",") + "]"
  if (typeof v === "object") {
    const ent = Object.entries(v as Record<string, unknown>)
      .map(([k, val]) => `"${esc(k)}":${jstr(val)}`)
    return "{" + ent.join(",") + "}"
  }
  return `"${esc(String(v))}"`
}

export interface EmitOpts {
  format: "toon" | "json" | "yaml" | "md"
  filter?: string[]
  full?: boolean
  command: string
  durationMs: number
  note?: string
}

function applyFilter(data: unknown, keys: string[] | undefined): unknown {
  if (!keys || keys.length === 0) return data
  if (Array.isArray(data)) return data.map((d) => pick(d, keys))
  return pick(data, keys)
}

function pick(obj: unknown, keys: string[]): unknown {
  if (typeof obj !== "object" || obj === null) return obj
  const out: Record<string, unknown> = {}
  const src = obj as Record<string, unknown>
  for (const k of keys) {
    const seg = k.split(".")
    let cur: unknown = src
    let ok = true
    for (const s of seg) {
      if (typeof cur === "object" && cur !== null && s in (cur as object)) {
        cur = (cur as Record<string, unknown>)[s]
      } else { ok = false; break }
    }
    if (ok) out[seg[seg.length - 1]] = cur
  }
  return out
}

function toYaml(v: unknown, indent = 0): string {
  const pad = "  ".repeat(indent)
  if (Array.isArray(v)) {
    if (v.length === 0) return pad + "[]\n"
    return v.map((e) => `${pad}- ${toYaml(e, 0).trimStart()}`).join("\n") + "\n"
  }
  if (typeof v === "object" && v !== null) {
    let s = ""
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
      if (typeof val === "object" && val !== null) {
        s += `${pad}${k}:\n` + toYaml(val, indent + 1)
      } else {
        s += `${pad}${k}: ${typeof val === "string" ? JSON.stringify(val) : String(val)}\n`
      }
    }
    return s
  }
  return pad + String(v) + "\n"
}

function toMd(v: unknown, depth = 0): string {
  if (Array.isArray(v)) {
    return v.map((e) => "- " + (typeof e === "object" && e !== null
      ? "\n" + toMd(e, depth + 1)
      : String(e))).join("\n") + "\n"
  }
  if (typeof v === "object" && v !== null) {
    const pad = "  ".repeat(depth)
    let s = ""
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
      if (typeof val === "object" && val !== null) {
        s += `${pad}- **${k}**:\n` + toMd(val, depth + 1)
      } else {
        s += `${pad}- **${k}**: ${String(val)}\n`
      }
    }
    return s
  }
  return String(v) + "\n"
}

export function humanData(data: unknown): string {
  if (Array.isArray(data)) {
    return data.map((e) => (typeof e === "object" && e !== null ? humanRow(e as Record<string, unknown>) : String(e))).join("\n")
  }
  if (typeof data === "object" && data !== null) return humanRow(data as Record<string, unknown>)
  return String(data)
}

function humanRow(r: Record<string, unknown>): string {
  const parts: string[] = []
  for (const [k, v] of Object.entries(r)) {
    if (v === null || v === undefined || v === "") continue
    parts.push(typeof v === "object" ? `${k}=${jstr(v)}` : `${k}=${String(v)}`)
  }
  return parts.join("  ")
}

export function emitOk(data: unknown, o: EmitOpts, cta: CtaItem[]): void {
  const filtered = applyFilter(data, o.filter)
  if (o.format === "json" || o.full) {
    // full 信封任何 format 下可用;--json 恒信封
    const env = {
      ok: true,
      data: filtered,
      meta: {
        command: o.command,
        duration_ms: o.durationMs,
        ...(o.note ? { note: o.note } : {}),
        cta: { description: cta.length > 1 ? "Suggested commands:" : "Suggested command:", commands: cta },
      },
    }
    console.log(jstr(env))
    return
  }
  if (o.format === "yaml") { process.stdout.write(toYaml(filtered)); return }
  if (o.format === "md") { process.stdout.write(toMd(filtered)); return }
  // toon:人机统一,数据行 + 注记 + CTA 尾
  if (o.note) console.log(o.note)
  const body = humanData(filtered)
  if (body) console.log(body)
  if (cta.length) {
    console.log(cta.length > 1 ? "Suggested commands:" : "Suggested command:")
    for (const c of cta) console.log(`  ${c.command} - ${c.description}`)
  }
}

export function emitErr(code: string, message: string, structured: boolean, cta: CtaItem[] = []): void {
  if (structured) {
    const e: Record<string, unknown> = { code, message }
    if (cta.length) e.cta = cta
    process.stderr.write(jstr(e) + "\n")
  } else {
    process.stderr.write(`rctl: ${message}\n`)
  }
}

export function die(code: string, message: string, structured: boolean, exitCode = 2, cta: CtaItem[] = []): never {
  emitErr(code, message, structured, cta)
  process.exit(exitCode)
}

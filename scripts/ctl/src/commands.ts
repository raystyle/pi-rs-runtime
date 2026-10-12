// rctl 命令表:help / --llms / 漂移测试三面共用的唯一真源
export interface Cmd {
  name: string
  args?: string
  desc: string
  examples?: { cmd: string; desc: string }[]
  flags?: string[]
}

export const RCTL_VERSION = "0.1.0"

export const COMMANDS: Cmd[] = [
  {
    name: "search",
    args: "<query>",
    desc: "能力问句:在能力表(册投影)里搜资源,按 id/描述/组/任务词命中",
    examples: [
      { cmd: "rctl search hash", desc: "搜破解/哈希相关资源" },
      { cmd: "rctl search subdomain --kind tool", desc: "只搜工具类" },
    ],
    flags: ["--kind <tool|data|cache|ref|service|compiler|runtime|model>", "--env <工具环境|运行时环境|编程环境|逆向环境|信息搜索|数据分析|代码样板参考>", "--limit <n>"],
  },
  {
    name: "where",
    args: "<path-query>",
    desc: "路径问句:在路径库找文件在哪(apt-file 语义;无索引时现场限根扫描)",
    examples: [{ cmd: "rctl where rockyou", desc: "rockyou 词表路径" }],
    flags: ["--limit <n>"],
  },
  {
    name: "show",
    args: "<id>",
    desc: "单件全息:kind、落点、版本钉、组、离线行为、册链接(explain 语义)",
    examples: [{ cmd: "rctl show nuclei", desc: "nuclei 的全息记录" }],
  },
  {
    name: "caps",
    args: "[task]",
    desc: "能力路由:任务词到资源组合与可抄命令(默认打印不执行)",
    examples: [
      { cmd: "rctl caps", desc: "列能力词典" },
      { cmd: "rctl caps 破解hash", desc: "哈希破解的资源组合" },
    ],
  },
  {
    name: "agents",
    desc: "agent CLIs 运行态:claude code 与 codex 的版本/配置目录/凭证在位布尔(不读内容)",
    examples: [
      { cmd: "rctl agents", desc: "看挂载态" },
      { cmd: "rctl agents --json", desc: "机读(平台集成面)" },
    ],
  },
  {
    name: "env",
    desc: "实例态:网络、五生态快失败面、端口监听、运行时版本面、已知边界",
    examples: [{ cmd: "rctl env --json", desc: "机读实例态" }],
  },
  {
    name: "docs",
    args: "<id|组|query>",
    desc: "册问句:件级册投影检索(真相在 docs/items/,此处只投影)",
    examples: [{ cmd: "rctl docs zig", desc: "zig 相关册" }],
  },
  {
    name: "audit",
    desc: "资源对账:/usr/local/bin 与 /opt 顶层 vs 能力表,输出 ok/alias/exempt/missing-id/stale;退出码 1=有未解释项",
    examples: [
      { cmd: "rctl audit", desc: "人读对账表" },
      { cmd: "rctl audit --json --filter-output summary", desc: "只看分类计数" },
    ],
    flags: ["--class <ok|alias|exempt|missing-id|stale>"],
  },
  {
    name: "index",
    desc: "建/刷路径库(/var/lib/rctl/paths.json;剪枝缓存树,未变根跳过)",
    examples: [{ cmd: "rctl index", desc: "重建路径库并打印统计" }],
  },
]

export const GLOBAL_FLAGS = [
  "--json", "--format <toon|json|yaml|md>", "--filter-output <keys>",
  "--full-output", "--llms", "--schema", "--help, -h",
]

export function renderLlms(): string {
  const L: string[] = []
  L.push(`# rctl@${RCTL_VERSION} — pi runtime 实例总 ctl(agent 第一入口)`)
  L.push("")
  L.push("读序:裸跑看面板;search 找能力;show 下钻单件;caps 拿任务配方;env 看实例态。")
  L.push("")
  L.push("## Commands")
  for (const c of COMMANDS) {
    L.push(`  rctl ${c.name}${c.args ? " " + c.args : ""} — ${c.desc}`)
    for (const f of c.flags ?? []) L.push(`    ${f}`)
    for (const e of c.examples ?? []) L.push(`    ${e.cmd} — ${e.desc}`)
  }
  L.push("")
  L.push("## Output contract")
  L.push("  全局旗标: " + GLOBAL_FLAGS.join(" "))
  L.push("  信封: {ok, data, meta:{command, duration_ms, cta:{description, commands[]}}}")
  L.push("  错误: stderr 单行 {code, message};人读前缀 rctl:")
  L.push("  退出码: 0 成功 / 1 未命中 / 2 用法与系统错误")
  L.push("")
  L.push("## Examples")
  L.push("  rctl                      # 面板:分类计数+下一步 CTA")
  L.push("  rctl search 逆向 --json   # 机读结果")
  return L.join("\n")
}

export function renderHelp(): string {
  const L: string[] = []
  L.push(`rctl@${RCTL_VERSION} — pi runtime 实例总 ctl`)
  L.push("")
  L.push("Usage: rctl [<command>] [args] [options]")
  L.push("")
  L.push("Commands:")
  const w = Math.max(...COMMANDS.map((c) => c.name.length))
  for (const c of COMMANDS) L.push(`  ${c.name.padEnd(w)}  ${c.desc}`)
  L.push("")
  L.push("Global Options:")
  for (const f of GLOBAL_FLAGS) L.push(`  ${f}`)
  L.push("")
  L.push("Examples:")
  L.push("  rctl env            # 实例态")
  L.push("  rctl --llms         # agent 手册")
  return L.join("\n")
}

export function schemaFor(name: string | undefined): object {
  const c = COMMANDS.find((x) => x.name === name)
  return {
    command: name ?? "rctl",
    args: c?.args ?? null,
    description: c?.desc ?? "pi runtime 实例总 ctl",
    options: GLOBAL_FLAGS.concat(c?.flags ?? []),
    output: {
      ok: "boolean",
      data: "object",
      "meta.command": "string",
      "meta.duration_ms": "number",
      "meta.cta.commands": "array of {command, description}",
    },
    exit_codes: { 0: "成功", 1: "未命中", 2: "用法或系统错误" },
  }
}

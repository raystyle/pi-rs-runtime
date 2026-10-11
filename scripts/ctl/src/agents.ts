// agents 面:挂载的 agent CLIs 运行态(二进制在镜像内;凭证与配置经挂载/env 注入)
// 纪律:只报「在不在」布尔,禁读凭证文件内容与 token 值
import { existsSync } from "node:fs"
import { execSync } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

function sh(cmd: string): string {
  try { return execSync(cmd, { timeout: 8000, encoding: "utf-8", stdio: ["ignore", "pipe", "ignore"] }).trim() }
  catch { return "" }
}

interface AgentDef {
  id: string
  bin: string
  configDir: () => string
  credFile: (d: string) => string
  authEnv: string
  note: string
}

const DEFS: AgentDef[] = [
  {
    id: "agent/claude-code",
    bin: "claude",
    configDir: () => process.env.CLAUDE_CONFIG_DIR || join(homedir(), ".claude"),
    credFile: (d) => join(d, ".credentials.json"),
    authEnv: "CLAUDE_CODE_OAUTH_TOKEN",
    note: "二进制在镜像内;推理/登录/自更新属使用期触网,不在离线承诺内",
  },
  {
    id: "agent/codex",
    bin: "codex",
    configDir: () => process.env.CODEX_HOME || join(homedir(), ".codex"),
    credFile: (d) => join(d, "auth.json"),
    authEnv: "CODEX_API_KEY",
    note: "二进制在镜像内;codex exec 可走 CODEX_API_KEY;刷新与推理使用期触网",
  },
]

export function agentsFace() {
  return DEFS.map((a) => {
    const dir = a.configDir()
    const version = sh(`${a.bin} --version`).split("\n")[0]
    return {
      id: a.id,
      binary: a.bin,
      version: version || "未装",
      config_dir: dir,
      config_present: existsSync(dir),
      cred_present: existsSync(a.credFile(dir)),
      auth_env_present: Boolean(process.env[a.authEnv]),
      note: a.note,
    }
  })
}

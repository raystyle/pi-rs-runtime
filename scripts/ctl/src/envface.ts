// 实例态面:网络、五生态快失败、端口监听、运行时版本、已知边界
import { readFileSync, existsSync } from "node:fs"
import { execSync } from "node:child_process"

function sh(cmd: string): string {
  try { return execSync(cmd, { timeout: 5000, encoding: "utf-8", stdio: ["ignore", "pipe", "ignore"] }).trim() }
  catch { return "" }
}

function netState(): { eth0: string; offline_default: boolean } {
  let eth0 = "unknown"
  try { eth0 = readFileSync("/sys/class/net/eth0/operstate", "utf-8").trim() } catch {}
  return { eth0, offline_default: eth0 !== "up" }
}

// /proc/net/tcp{,6} LISTEN 解析(零依赖,回环判定)
function hexToV6(addr: string): string {
  // /proc/net/tcp6 的每 32 位字(8 hex)是字节序反转的:按字交换字节后还原
  const groups: string[] = []
  for (let i = 0; i < 32; i += 8) {
    const w = addr.slice(i, i + 8)
    const swapped = w.slice(6, 8) + w.slice(4, 6) + w.slice(2, 4) + w.slice(0, 2)
    groups.push(swapped.slice(0, 4).replace(/^0+/, "") || "0")
    groups.push(swapped.slice(4, 8).replace(/^0+/, "") || "0")
  }
  // v4-mapped ::ffff:a.b.c.d 渲染成可读点分(还原后的末 8 hex 是大端点分)
  const flat = groups.map((g) => g.padStart(4, "0")).join("")
  if (flat.startsWith("00000000000000000000FFFF")) {
    const h = flat.slice(24)
    return `::ffff:${parseInt(h.slice(0, 2), 16)}.${parseInt(h.slice(2, 4), 16)}.${parseInt(h.slice(4, 6), 16)}.${parseInt(h.slice(6, 8), 16)}`
  }
  // 压缩最长零段
  let best = -1, bestLen = 0, cur = -1, curLen = 0
  groups.forEach((g, i) => {
    if (g === "0") { if (cur < 0) cur = i; curLen++; if (curLen > bestLen) { best = cur; bestLen = curLen } }
    else { cur = -1; curLen = 0 }
  })
  if (bestLen < 2) return groups.join(":")
  const head = groups.slice(0, best).join(":")
  const tail = groups.slice(best + bestLen).join(":")
  return `${head}::${tail}`
}

function v6Loopback(addr: string): boolean {
  return hexToV6(addr.toLowerCase()) === "::1"
}

function listeners(): { port: string; local: string; loopback: boolean }[] {
  const out: { port: string; local: string; loopback: boolean }[] = []
  const seen = new Set<string>()
  for (const f of ["/proc/net/tcp", "/proc/net/tcp6"]) {
    if (!existsSync(f)) continue
    const lines = readFileSync(f, "utf-8").split("\n").slice(1)
    for (const l of lines) {
      const m = l.trim().split(/\s+/)
      if (m.length < 4 || m[3] !== "0A") continue // LISTEN
      const [addr, portHex] = m[1].split(":")
      const port = String(parseInt(portHex, 16))
      const isV6 = addr.length > 8
      const loopback = isV6 ? v6Loopback(addr) : addr.toUpperCase().endsWith("7F") // 127.0.0.0/8 或 ::1
      const local = isV6
        ? `[${hexToV6(addr.toLowerCase())}]:${port}`
        : `${parseInt(addr.slice(6, 8), 16)}.${parseInt(addr.slice(4, 6), 16)}.${parseInt(addr.slice(2, 4), 16)}.${parseInt(addr.slice(0, 2), 16)}:${port}`
      const key = local + "|" + port
      if (seen.has(key)) continue
      seen.add(key)
      out.push({ port, local, loopback })
    }
  }
  return out.sort((a, b) => Number(a.port) - Number(b.port))
}

function ecoFastFail(): Record<string, string> {
  const go: Record<string, string> = {}
  go.goproxy = sh("go env GOPROXY") || "go(不在 PATH)"
  go.uv = existsSync("/etc/uv/uv.toml") && readFileSync("/etc/uv/uv.toml", "utf-8").includes("offline = true")
    ? "offline=true(/etc/uv/uv.toml)" : "未钉"
  go.pip = existsSync("/etc/pip.conf") && readFileSync("/etc/pip.conf", "utf-8").includes("no-index = true")
    ? "no-index(/etc/pip.conf)" : "未钉"
  go.npm = sh("npm config get offline") || "npm(不在 PATH)"
  go.cargo = existsSync("/opt/cargo/config.toml") && readFileSync("/opt/cargo/config.toml", "utf-8").includes("offline")
    ? "offline(/opt/cargo/config.toml)" : "未钉"
  return go
}

function runtimeVersions(): Record<string, string> {
  const v: Record<string, string> = {}
  v.node = sh("node --version")
  v.bun = sh("bun --version")
  v.go = sh("go version").split(" ").slice(2).join(" ")
  v.rustc = sh("rustc --version").split(" ")[1] ?? ""
  v.java = sh("java -version 2>&1").split('"')[1] ?? ""
  v.dotnet = sh("dotnet --version")
  v.python3 = sh("python3 --version").split(" ")[1] ?? ""
  return v
}

export function envFace() {
  const net = netState()
  return {
    net,
    eco_fast_fail: ecoFastFail(),
    listeners: listeners(),
    runtimes: runtimeVersions(),
    boundaries: [
      "宿主信号策略:容器内非 pid1 进程 kill 族恒 EACCES,进程管理移宿主侧或等自然退出",
      "apt lists 已清:离线新装快失败属设计;五生态拉新件亚秒报错",
      "非登录 shell(incus exec)不读 profile.d:行为修正看 wrapper(env 接线如 rctl/rea/trivy)",
    ],
  }
}

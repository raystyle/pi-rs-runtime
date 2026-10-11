// 路径库:镜像内 install 期生成 /var/lib/rctl/paths.json;未建时现场限根扫描兜底
import { readdirSync, statSync, existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { join } from "node:path"

export const ROOTS = ["/opt", "/usr/local/bin", "/root/scripts", "/usr/share/wordlists"]
const PRUNE = new Set([
  "node_modules", ".git", "pkg", "registry", "m2", "nuget-packages", "zig-cache/h",
  "zig-cache/o", "zig-cache/p", ".cache", "target", "gradle-home/caches",
  "trivy-db/metadata", "fnm", "cargo/registry",
])

function pruned(rel: string): boolean {
  return PRUNE.has(rel) || rel.split("/").some((s) => s === "node_modules" || s === ".git")
}

export function walk(maxEntries = 200_000): { paths: string[]; pruned: string[] } {
  const out: string[] = []
  const prunedRoots: string[] = []
  const rec = (root: string, rel: string) => {
    if (out.length >= maxEntries) return
    const abs = join(root, rel)
    let st
    try { st = statSync(abs) } catch { return }
    if (!st.isDirectory()) { out.push(abs); return }
    if (rel !== "" && pruned(rel)) { prunedRoots.push(abs); return }
    let ents: string[]
    try { ents = readdirSync(abs) } catch { return }
    // 目录本体也进库(资源树语义);子项限深防爆炸:SecLists 等 3 层内最有价值
    if (rel.split("/").length >= 3) { out.push(abs + "/"); return }
    for (const e of ents.sort()) rec(root, rel === "" ? e : rel + "/" + e)
  }
  for (const r of ROOTS) {
    if (!existsSync(r)) continue
    rec(r, "")
  }
  return { paths: out, pruned: prunedRoots }
}

export interface PathsLib { generated_at: string; count: number; paths: string[] }

export function libPath(): string {
  return process.env.RCTL_HOME ? join(process.env.RCTL_HOME, "paths.json") : "/var/lib/rctl/paths.json"
}

export function loadLib(): PathsLib | undefined {
  const p = libPath()
  if (!existsSync(p)) return undefined
  try { return JSON.parse(readFileSync(p, "utf-8")) as PathsLib } catch { return undefined }
}

export function buildLib(): PathsLib {
  const { paths, pruned } = walk()
  const lib: PathsLib & { pruned_roots: string[] } = {
    generated_at: new Date().toISOString(),
    count: paths.length,
    paths,
    pruned_roots: pruned,
  }
  const p = libPath()
  mkdirSync(join(p, ".."), { recursive: true })
  writeFileSync(p, JSON.stringify(lib))
  return lib
}

export function where(q: string, limit: number): { path: string; via: string }[] {
  const terms = q.toLowerCase().split(/\s+/).filter(Boolean)
  const hit = (s: string) => terms.every((t) => s.toLowerCase().includes(t))
  const fromLib = loadLib()
  if (fromLib) {
    return fromLib.paths.filter((p) => hit(p)).slice(0, limit).map((p) => ({ path: p, via: "paths.json" }))
  }
  // 兜底:现场扫描(同剪枝)
  const { paths } = walk()
  return paths.filter((p) => hit(p)).slice(0, limit).map((p) => ({ path: p, via: "live-walk" }))
}

// 三面同源漂移守卫:命令表是唯一真源,help 与 --llms 必须覆盖全部命令与旗标
import { test, expect } from "bun:test"
import { COMMANDS, GLOBAL_FLAGS, renderLlms, renderHelp, schemaFor } from "../src/commands.ts"
import { catalog, caps } from "../src/catalog.ts"
import { readFileSync, existsSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

test("--llms 覆盖全部命令", () => {
  const llms = renderLlms()
  for (const c of COMMANDS) expect(llms).toContain(`rctl ${c.name}`)
})

test("--llms 覆盖全局旗标", () => {
  const llms = renderLlms()
  for (const f of GLOBAL_FLAGS) expect(llms).toContain(f.split(" ")[0])
})

test("help 覆盖全部命令", () => {
  const help = renderHelp()
  for (const c of COMMANDS) expect(help).toContain(c.name)
})

test("schema 含退出码与旗标", () => {
  const s = JSON.stringify(schemaFor("search"))
  expect(s).toContain("exit_codes")
  expect(s).toContain("--json")
})

test("catalog.tsv 存在且列数合规(>=6 列)", () => {
  const p = join(dirname(fileURLToPath(import.meta.url)), "..", "data", "catalog.tsv")
  expect(existsSync(p)).toBe(true)
  const lines = readFileSync(p, "utf-8").split("\n").filter((l) => l.trim() && !l.startsWith("#"))
  expect(lines.length).toBeGreaterThan(20)
  for (const l of lines) expect(l.split("\t").length).toBeGreaterThanOrEqual(6)
})

test("caps.tsv 的 ids 全部存在于 catalog(词典漂移守卫)", () => {
  const ids = new Set(catalog().map((r) => r.id))
  const missing: string[] = []
  for (const c of caps()) {
    for (const id of c.ids.split(",").map((x) => x.trim()).filter(Boolean)) {
      if (!ids.has(id)) missing.push(`${c.task}:${id}`)
    }
  }
  expect(missing).toEqual([])
})

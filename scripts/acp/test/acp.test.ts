// acpsup 单元面:分帧、fs 回调边界、terminal 生命周期
import { test, expect } from "bun:test"
import { fsReadTextFile, fsWriteTextFile, Terminals } from "../src/fsimpl.ts"
import { writeFileSync, mkdtempSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

test("fs 回调读写往返 + 拒绝非绝对路径", () => {
  const d = mkdtempSync(join(tmpdir(), "acpsup-"))
  const p = join(d, "a.txt")
  fsWriteTextFile({ path: p, content: "hello acp" })
  expect(fsReadTextFile({ path: p })).toBe("hello acp")
  expect(() => fsReadTextFile({ path: "rel/path" })).toThrow()
  expect(() => fsWriteTextFile({ path: "rel", content: "x" })).toThrow()
})

test("terminal 创建/输出/等待退出", async () => {
  const t = new Terminals()
  const { terminalId } = t.create({ command: ["printf", "hi-acp-term"], cwd: "/tmp" })
  const r = await t.waitForExit({ terminalId })
  expect(r.exitCode).toBe(0)
  const out = t.output({ terminalId })
  expect(out.output).toContain("hi-acp-term")
})

test("terminal kill 在信号策略下如实报边界", () => {
  const t = new Terminals()
  const { terminalId } = t.create({ command: ["sleep", "60"], cwd: "/tmp" })
  expect(() => t.kill({ terminalId })).toThrow(/EACCES|信号/)
})

test("未知 terminal 报错", () => {
  const t = new Terminals()
  expect(() => t.output({ terminalId: "nope" })).toThrow()
})

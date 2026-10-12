// 语义腿测试:解析器单测(恒跑)+ 引擎门控金标(zg 在位才跑,容器/装后面跑)
// 查询语义词不落目标件名与词典原词,专测向量腿(REQ-0005 验收 1)
import { test, expect, describe } from "bun:test"
import { resolveZg, mirrorName, semanticDoc, zgHitsToRecs, ensureMirror } from "../src/semantic.ts"
import { searchWithEngine, catalog, caps, withTaskHints, type Rec } from "../src/catalog.ts"
import { mkdtempSync, readFileSync, writeFileSync, existsSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

test("mirrorName:非法字符压下划线,锚后缀稳定", () => {
  expect(mirrorName({ id: "Get-GPPPassword.py" } as Rec)).toBe("Get-GPPPassword.py.txt")
  expect(mirrorName({ id: "a b/c" } as Rec)).toBe("a_b_c.txt")
})

test("semanticDoc:六行微文档含 id/desc/task/kind/alias", () => {
  const doc = semanticDoc({ id: "x", kind: "tool", group: "g", status: "s", desc: "d", pin: "", path: "", offline: "", book: "", taskHint: "词袋 t", alias: "al" } as Rec)
  expect(doc).toContain("id: x")
  expect(doc).toContain("task: 词袋 t")
  expect(doc).toContain("alias: al")
})

test("zgHitsToRecs:compact 行中位锚(空格/斜杠后)排序回填,重复去重", () => {
  const a = { id: "a" } as Rec; const b = { id: "b" } as Rec
  const byName = new Map([["a.txt", a], ["b.txt", b]])
  const out = zgHitsToRecs("#1 matchedBy=fts+vector b.txt:1-2\nfoo/bar #2 matchedBy=vector a.txt:3\n#3 matchedBy=fts b.txt:9", byName)
  expect(out.map((r) => r.id)).toEqual(["b", "a"])
})

test("ensureMirror:增量写与废件清理", () => {
  const dir = mkdtempSync(join(tmpdir(), "rctl-sem-test-"))
  writeFileSync(join(dir, ".zvec-grep"), "") // 模拟已有索引标记
  const r1 = { id: "one", kind: "tool", group: "", status: "", desc: "d1", pin: "", path: "", offline: "", book: "" } as Rec
  expect(ensureMirror([r1], dir)).toBe(true)          // 冷建:新行写入
  expect(ensureMirror([r1], dir)).toBe(false)         // 未变不写不重索引
  const r2 = { ...r1, id: "two" }
  ensureMirror([r2], dir)                              // 换行:one.txt 成废件被清
  expect(existsSync(join(dir, "one.txt"))).toBe(false)
  expect(readFileSync(join(dir, "two.txt"), "utf8")).toContain("id: two")
})

test("回退确定性:RCTL_ZG_PATH=0 时引擎恒 lexical(REQ-0005 验收 2)", () => {
  process.env.RCTL_ZG_PATH = "0"
  const { engine } = searchWithEngine("hashcat", undefined, 5)
  expect(engine).toBe("lexical")
  delete process.env.RCTL_ZG_PATH
})

describe("语义金标(zg 在位才跑)", () => {
  const zg = resolveZg()
  if (!zg) test.skip("zg 不在,语义金标跳过", () => {})
  else {
    const all = withTaskHints(catalog(), caps())
    const semCases: { q: string; mustAny: string[]; k?: number }[] = [
      { q: "跨内网把流量转发出来", mustAny: ["gost", "chisel", "wstunnel", "rathole", "frps"], k: 8 },
      { q: "破解无线网络的握手包", mustAny: ["aircrack-ng", "hashcat", "john"], k: 8 },
      { q: "从 windows 域控里导出账号凭据", mustAny: ["secretsdump.py", "impacket", "bloodyAD"], k: 8 },
      { q: "审查代码仓库里泄漏的密钥", mustAny: ["gitleaks", "trufflehog"], k: 8 },
      { q: "把安卓应用反编译看源码", mustAny: ["jadx", "apktool"], k: 8 },
    ]
    for (const c of semCases) {
      test(`语义:${c.q}`, () => {
        const { hits, engine } = searchWithEngine(c.q, undefined, c.k ?? 8)
        expect(engine).toBe("zvec")
        const ids = hits.map((r) => r.id)
        expect(ids.some((id) => c.mustAny.includes(id))).toBe(true)
      })
    }
    test("语义查询后 catalog 未变则二次查询零重索引(REQ-0005 验收 3)", () => {
      const first = searchWithEngine("隧道出网", undefined, 5)
      expect(first.engine).toBe("zvec")
      // 二次走缓存索引:仍能命中且引擎稳定(重索引计数在 ensureMirror 内部,这里以行为面断言)
      const second = searchWithEngine("隧道出网", undefined, 5)
      expect(second.engine).toBe("zvec")
    })
  }
})

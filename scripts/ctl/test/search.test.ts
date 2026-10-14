// 搜索回归与召回:金标查询集,recall@10 门禁 + MRR 观察
// 案例分型:A 直名子串 / B caps 任务词中文 / C 中英混查 / D 英文任务词反桥 / E alias / F kind 过滤
import { test, expect } from "bun:test"
import { search, catalog } from "../src/catalog.ts"

const K = 10

interface Case {
  q: string
  kind?: string
  must: string[] // 每件都必须进 top-K(recall@K=1 是门禁)
  first?: string // MRR 观察锚(不进门禁,只报排名)
}

const CASES: Case[] = [
  // A 直名/子串
  { q: "secretsdump", must: ["secretsdump.py"], first: "secretsdump.py" },
  { q: "impacket", must: ["impacket", "secretsdump.py"], first: "impacket" },
  { q: "frida", must: ["frida"], first: "frida" }, // 族内同辈并列按字母序,契约=族代表进 top-k
  { q: "hashcat", must: ["hashcat"], first: "hashcat" },
  // B caps 任务词
  { q: "破解hash", must: ["hashcat", "john"], first: "hashcat" },
  { q: "子域枚举", must: ["subfinder", "amass"], first: "subfinder" },
  { q: "隧道出网", must: ["gost", "chisel"], first: "gost" },
  { q: "逆向安卓", must: ["jadx", "apktool"], first: "jadx" },
  { q: "抓包", must: ["tcpdump", "tshark"], first: "tcpdump" },
  { q: "固件解包", must: ["binwalk"], first: "binwalk" },
  // C 中英混查与语义词
  { q: "kerberos ticket", must: ["ticketer.py", "ticketConverter.py"], first: "ticketer.py" },
  { q: "票据", must: ["ticketer.py"], first: "ticketer.py" },
  { q: "密码爆破", must: ["hydra", "hashcat"], first: "hydra" },
  { q: "哈希", must: ["hashcat", "john"], first: "hashcat" },
  { q: "反序列化", must: ["phpggc"], first: "phpggc" },
  { q: "横向移动", must: ["bloodhound-python"], first: "bloodhound-python" },
  { q: "提权", must: ["windows-logical-eop-workshop"], first: "windows-logical-eop-workshop" },
  { q: "截图", must: ["gowitness"], first: "gowitness" },
  // D 英文任务词反桥
  { q: "subdomain", must: ["subfinder"], first: "subfinder" },
  { q: "tunnel", must: ["chisel", "gost"], first: "gost" },
  { q: "deserialization", must: ["phpggc"], first: "phpggc" },
  { q: "wordlist", must: ["SecLists"], first: "SecLists" },
  { q: "screenshot", must: ["gowitness"], first: "gowitness" },
  // E alias
  { q: "entc", must: ["entropia"], first: "entropia" },
  { q: "entropia", must: ["entropia"], first: "entropia" },
  // F kind 过滤
  { q: "词表", kind: "data", must: ["SecLists"], first: "SecLists" },
  { q: "subdomain", kind: "tool", must: ["subfinder"], first: "subfinder" },
]

test("金标集自检:must/first 的 id 都在 catalog", () => {
  const ids = new Set(catalog().map((r) => r.id))
  const miss: string[] = []
  for (const c of CASES) {
    for (const id of [...c.must, ...(c.first ? [c.first] : [])]) {
      if (!ids.has(id)) miss.push(`${c.q}:${id}`)
    }
  }
  expect(miss).toEqual([])
})

test("recall@10 门禁:must 全进 top-10", () => { // 27 案 × zvec ~1.3s/查,超时给 300s(2026-10-14:语料 498 件后默认 5s 必炸)
  const fails: string[] = []
  for (const c of CASES) {
    const got = search(c.q, c.kind, K).map((r) => r.id)
    for (const id of c.must) {
      if (!got.includes(id)) fails.push(`q="${c.q}"${c.kind ? ` kind=${c.kind}` : ""} 缺 ${id}(得:${got.slice(0, 5).join(",")})`)
    }
  }
  if (fails.length) console.log(fails.join("\n"))
  expect(fails).toEqual([])
}, 300_000)

test("MRR 观察(不进门禁,排名劣化时人看)", () => {
  let mrr = 0
  const rows: string[] = []
  for (const c of CASES) {
    if (!c.first) continue
    const got = search(c.q, c.kind, 50).map((r) => r.id)
    const rank = got.indexOf(c.first)
    const rr = rank >= 0 ? 1 / (rank + 1) : 0
    mrr += rr
    rows.push(`  ${rr.toFixed(2)} q="${c.q}" -> ${c.first}@${rank + 1}`)
  }
  console.log(`MRR=${(mrr / CASES.filter((c) => c.first).length).toFixed(3)}\n` + rows.join("\n"))
  expect(true).toBe(true)
}, 300_000)

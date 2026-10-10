# ADR-0002 参考克隆三轴归档(工件角色轴)

状态:accepted(2026-10-09,grok 评审裁定)｜ 关联:items/tools-maldev、tools-c2、tools-recon

## Context

攻击开发参考仓(BOF、C2 框架、加载器、规避技术、语言教材)数量大且持续增长,需要一个可扩展的归档分类法。早期按语言分(Nim/Zig/Rust)混入了角色错配:SILENTTRINITY 是 C2 不是 Nim 教材,ysoserial 是反序列化生成器不是 C2。

## Decision

参考克隆按**工件角色轴**归档,只克隆不编译不运行:

- `/opt/c2dev-ref/`:C2 框架(sliver/merlin/Empire/Covenant/mythic/SILENTTRINITY/AdaptixC2)
- `/opt/payload-ref/`:载荷开发——generators{deserialization,pe-to-shellcode}、loaders{droppers,inproc}、evasion、curricula{zig,rust,nim,go 教材系}、analysis
- `/opt/tradecraft-ref/`:ad/bof/opsec 技法
- `/opt/recon-ref/`:指纹与侦察库(mac-tracker/recog/hickory-dns/PoC-in-GitHub)

语言只做 curricula 叶下的教材次轴。新增仓先定角色再入轴。

## Consequences

- 分类争议有判据(角色 > 语言),grok 评审口径可复用
- 克隆未钉提交(--depth 1),升级靠重跑组
- 误归档历史(silver 类)在迁移轮一次性纠正

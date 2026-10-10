# ADR-0006 用户裁定留痕合集

状态:accepted(2026-10-09 至 10-10 多次裁定)｜ 关联:known-issues.md(现只剩真限制)

## Context

评审(grok/claude)多次建议移除或替换一批件,用户逐项裁定。这些裁定不可逆地影响清单形态,集中留痕防止复审时重复提议。

## Decision

- **保留不移除**:gospider、httprobe、assetfinder、waybackurls(攻击面测绘批);Covenant、SILENTTRINITY(c2dev-ref 参考克隆)
- **EOL 运行时全保留**:python2、PHP 7.4/8.1、JDK 11、Node 18/20——样本兼容与 CVE 复现场景必需,评审的「EOL 风险」意见已知悉不采纳
- impacket 用 uv 上游版,不用 noble apt 冻结版
- fff-mcp 不装二进制,fff-search 只进 rust 库预热
- 不进镜像(grok 库评审建议后裁定):BananaPhone、go-clr、garble、obfstr、boost、Detours、JsonSpirit、webshell 样本库、哥斯拉/冰蝎/蚁剑操作台
- VNC 屏幕不装官方 Chrome,等定制构建合入
- trufflehog 走 release 钉 tag(上游 go.mod 带 replace 拒 `go install @版本`);metasploit 走 omnibus 官方安装器;两者无校验和,留痕接受

## Consequences

- 复审轮先读本篇,已裁定项不再重复提议
- 新裁定追加进本篇 Decision 列表并标日期

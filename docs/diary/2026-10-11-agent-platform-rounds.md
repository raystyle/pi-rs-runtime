# 2026-10-11 agent 平台轮:回归、rctl、agents、ACP、七域归档、四 REQ

> 本日是仓史上最长单日:从「回归测试实例真实使用情况」起,经 grok 邻居十笺联席,落四张 REQ、十三个主题批。本文按批留痕;逐件事实在 items 册与 REQ trace,不在此重复。

## 批序:git 链可对账

1. **回归轮**:断网冒烟双视角重跑抓五缺口(amass/azurehound/cvemap/gost 装而未链、responder 硬查 aioquic、sasquatch 上游重构、zig 嵌套依赖层缺缓存、uv 软链穿 /root),全修;环境大发现:宿主 AppArmor 叠栈信号策略(容器内 kill 族恒 EACCES,grok prt-01 定性,实例级 raw.apparmor 修复选项表留裁定)。
2. **rea 批**:morluto/rea 6.3.0(Ghidra 无头封装)接入,四象限(在线/断网×root/ubuntu)实证;grok prt-02 配方吸收(JAVA_HOME 取 Ghidra 自钉 temurin21)。
3. **rctl 批**(REQ-0001):核心 CLI 落地(bun 零依赖,命令表单一真源,catalog 烤库,三问句三命令);S-0001 设计研究(grok prt-03:fff 定性不当总 ctl,烤小册主路径)。
4. **agents 批**:claude-code 2.1.296+codex 0.162.1 钉版(凭证不进 rootfs,挂载配方在 prt-04);rctl agents 面。
5. **acp 批**(REQ-0002):ACP v1+stdio 通道(S-0002 定调,prt-05 定调/prt-06 MCP 翻转证伪);acpsup 监督进程(回环 7663+token+selftest 自终止,适配信号策略);协议级 E2E。
6. **清点分类归档批**(prt-07 三阶段):两分法(kind×status)+机器小表声明制+rctl audit 面;未解释项 103 到 0;七域定稿(prt-09:数据分析独立成域,三处改判);全仓 md 禁字清零。
7. **物化预热批**(REQ-0003,prt-08):one_gadget(Ruby3.2 面)/seccomp-tools/qiling/angr 独立 venv;数据语料三仓起步。
8. **HackTricks/GTFOBins 批**:HackTricks 文本面 18M(用户裁定「文本没那么大」,310M=144M .git+150M 图+18M 文本);GTFOBins 走用户给出的 .github.io 源仓道(主仓三通道 403)。
9. **工作流补缺批**(REQ-0004,prt-10):kill-chain×品类矩阵驱动;交叉编译四套+i386(打包互斥坑)、stego 四件、web 泄漏三件、SSTImap、apkid、commix;九件+四架构断网全过。
10. **entropia 晚批**(用户点名加项目,prt-11):entropykit/entropia v0.1-experimental 进 bof 组(Windows PIC shellcode/BOF 编译语言,补 mingw 之外的高级语言道);源码 cargo 构建 entc+entc-win32gen,断网编译真 COFF/118 字节 shellcode 实证;顺带修生成器潜伏 bug(机器行 book/alias 两列写反,首个 alias 用例炸出,angr-venv 等纯机器行 id 的 book 列同批回填)。prt-11 回执(16:45)吸收:五问全过,先例稀薄(star 297=公告转发,动手文字两篇),维护者挂未修 resolver 崩溃且 main 自 2026-06-28 无新码,entc 根包零第三方依赖,win32gen 再生头要自备 winmd 离线做不了,跑面唯一候选 wine COFFLoader 且先试不带 --opsec=all 的对象(bof-launcher Linux 面是 ELF 例不接),README 两处与清单不符以 Cargo 书为准。

## 联席协议实践

grok 邻居十笺(prt-01 到 prt-10)全部按三件套走(brief/state/receipt),轮次档 /tmp/herdr-flywheel/2026-10-11-实例回归与rea/;本日验证了「研究全部给 grok、实现归总台」的分工:prt-06 证伪总台中途的 MCP 翻转判断、prt-09 改判总台三处域归类,联席质量高于单边。

## 本日血泪坑:新增

apt 打包互斥(gcc-multilib vs cross);交叉命令带 -13 代号;stegseek 资产名无 arch 段;/proc/net/tcp6 每 32 位字字节序反转;ugrep 皮吞 tsv 匹配(宿主侧 catalog 校验用 awk);aliyun 资产名无 v 前缀;生成器 dedup 按末行 NF 重建列宽(硬编码 11 列解);钉版升级未带断网冒烟即回镜像(responder 漂移整日才被抓);生成器机器行 book/alias 列写反(无 alias 用例时潜伏,首个 alias 行炸出);混合 workspace 根裸 cargo build 只建根包(辅件要 -p 点名);运行期 cargo 默认离线挡构建期取依赖(CARGO_NET_OFFLINE=false 拿回在线面,同 agents 批 npm 口径)。

## 里程碑数字

catalog 447 件(audit missing=0)、87 册对账、七域(kind×env 两分面)、12 数据语料库、5 agent 面(CLI×2+ACP 通道+rctl+acpsup)、四 REQ 全 implemented、发布链未动(实例保持开发态,用户裁定修到完美态再打包)。

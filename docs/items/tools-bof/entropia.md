# entropia(entc)

> Windows PIC x86-64 shellcode / BOF 编译语言(.etpy),bof 组高级语言道(mingw 是 C 道)｜ 状态:已装 ｜ 组:`install-tools.sh bof`

- **版本钉**:源码 pins.sh `GIT_PIN[entropykit/entropia]`=05acaba2a1a5fbde8cec3318319d053265ddb7ca(= v0.1-experimental tag,2026-10-11 解析;仓是单提交迁移面,HEAD 即 tag),clone_pin 幂等;升级跑 scripts/resolve-pins.sh 审 diff 重跑本组
- **来源与安装**:`scripts/install-tools.sh install_bof` 段:clone_pin 到 `/opt/entropia`,`cargo build --release --locked -p entropykit -p entc-win32gen`(经 tuna crates;rustc 1.99 过上游 MSRV 1.75;不裸 `--workspace`,那会把 Windows 跑面也编出来)到 `install -m755` 装 `entc`;release zip(entropia-bin-v0.1-experimental.zip,1.84MB,清单是四个 .exe+vsix+stdlib)是 Windows 预编,Linux 面不用;辅件 entc-win32gen 尽力装,entc-debug/bof-runner/bof-loader 是 Windows 跑面(非 Windows 的 load/run 直接返回错误)不装
- **落点**:`/usr/local/bin/entc`(+ `/usr/local/bin/entc-win32gen`);源码与构建树 `/opt/entropia`(stdlib/win32 头 + examples 20 例 .etpy 随仓);输出目标恒 Windows x86-64(`.bin` shellcode / `.x64.o` BOF)
- **配置与缓存**:无配置;编译只读仓内 stdlib(win32 头自 `stdlib/win32/*.h`,`use_c` 直引 Windows SDK 头),零外部数据面;**entc 根包零第三方依赖**(锁内 29 包全属辅件,grok prt-11 AC);win32gen 运行要 `--winmd` 自备 `Windows.Win32.winmd`(microsoft/win32metadata releases 的 nupkg `ref/netstandard2.0/` 内,仓与 zip 均不含),故**离线不能再生头**,日常编译用仓内 stdlib 即够,再生仅头升级时在线做
- **离线行为**:过,`entc --version` 与示例编译(bof_pslist.etpy 出真 COFF `.x64.o`)断网实证;编译是本地计算零网络(源码无网络面,grok prt-11 AC 同判);win32gen 的构建与再生两头都触网(构建期 `CARGO_NET_OFFLINE=false` 是给辅件开的在线面,不是给编译器的)
- **坑与留痕**:experimental 单提交迁移仓(2026-06-23),钉 tag 不追 HEAD,维护者 issue #1 挂着未修的 resolver 崩溃(unsafe branch relaxation 发过期短跳偏移,2026-06-28 评论,晚于钉的提交且此后 main 无新码),语言还缺嵌套结构/`--avoid=` 坏字节规避,是 C 道旁边的**实验编译道不是 C 道升级**;PR #2 测试合并在 GitHub 记录但不在钉的树里(迁移压史);README 两处与清单/Cargo 书不符(「一次 cargo 出三 exe」「每 tag 带 PDF」,zip 无 PDF),集成以清单与 Cargo 书为准,混合 workspace 根裸 `cargo build` 只建根包正是同一实证(总台实例复跑+grok AC 双证);社区先例稀薄:star 297 全是公告转发(SEKTOR7/5mukx/PT dbugs 等),动手文字仅两篇(brmk 上手,实证 `--opsec=all` 后 `__imp_*` 符号消失改走 PEB;CN-SEC 审查),无外部缺陷帖,star 不当生产采用;typecheck 空 branch(非 void 裸 `ret;` 不报)在钉的源码对上(grok AC);产物跑面契约:非 opsec 产物符号形状 `__imp_LIB$Func`(CS 动态函数解析形),实例内唯一候选加载器是 wine COFFLoader64(先试**不带** `--opsec=all` 的对象;opsec 产物 hashed imports 走 PEB,不要假定 COFFLoader 能跑),bof-launcher 的 Linux 面是 ELF 例不接此产物,coffee-ldr 未装上;实例内实证止于编译面(真 COFF/118 字节 shellcode),运行面留目标机/wine 后试;grok prt-11 回执已吸收(五问全过,FL/AC 级)

## rctl 面(机器行:catalog 投影声明,audit 豁免依据)

- rctl: entropia kind=tool path=/opt/entropia alias=entc note=Windows PIC shellcode/BOF 编译语言(entc,v0.1-experimental 源码构建;mingw 之外的高级语言道)
- rctl: entc-win32gen kind=tool path=/opt/entropia note=win32 头再生辅件(entropia 同仓构建,--winmd 再生 stdlib/win32)

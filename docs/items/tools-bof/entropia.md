# entropia:entc

> Windows PIC x86-64 shellcode / BOF 编译语言(.etpy);bof 组的高级语言道,mingw 是 C 道 ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- `GIT_PIN[entropykit/entropia]` = `05acaba2a1a5fbde8cec3318319d053265ddb7ca`,等于 tag `v0.1-experimental`(解析日 2026-10-11)。
- 仓库是单提交迁移面,HEAD 就是该 tag;`clone_pin` 在 HEAD 等于锁定提交时跳过;升级:执行 `scripts/resolve-pins.sh`,审阅差异,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_bof`;`clone_pin` 到 `/opt/entropia` 后,`cargo build --release --locked -p entropykit -p entc-win32gen` 构建并 `install -m755` 安装 `entc`。
- 不使用裸 `--workspace`(那会把 Windows 跑面也编出来);crate 来自 tuna;当前 rustc 1.99 满足 MSRV 1.75。
- 辅件 `entc-win32gen` 尽力安装;`entc-debug`、`bof-runner`、`bof-loader` 是 Windows 跑面(Linux 上 load 与 run 直接返回错误),不安装。

## 文件

- `/usr/local/bin/entc`、`/usr/local/bin/entc-win32gen`;源码与构建树在 `/opt/entropia`。
- 仓内带 `stdlib/win32` 头与 20 个 `.etpy` 示例。
- 输出目标始终是 Windows x86-64:`.bin` 是 shellcode,`.x64.o` 是 BOF。

## 配置

- 无配置文件。编译只读仓内 stdlib(`stdlib/win32/*.h`);`use_c` 直接引用 Windows SDK 头。
- `entc` 根包没有第三方依赖;锁文件里的 29 个包都属于辅件。
- `entc-win32gen` 运行时需要 `--winmd` 指向 `Windows.Win32.winmd`(由使用侧自备,microsoft/win32metadata releases 的 nupkg 内 `ref/netstandard2.0/` 目录;仓库与 zip 都不含)。因此离线不能重新生成头文件——日常编译用仓内 stdlib,头文件再生只在升级时进行且需要网络。

## 离线行为

- 支持:关闭 eth0 后 `entc --version` 退出码 0;`entc compile examples/bof_pslist.etpy --type=bof` 产出 COFF `.x64.o`。
- 编译是本地计算,源码没有网络调用。
- `entc-win32gen` 的构建与头文件再生访问网络;构建期 `CARGO_NET_OFFLINE=false` 是给辅件打开的在线面。

## 限制

- 锁定 tag 不跟随 HEAD。issue #1(resolver 崩溃,原因 unsafe branch relaxation 发出过期的短跳转偏移)仍未修复,该评论晚于锁定提交且此后 main 无新代码。
- 语言还没有嵌套结构与 `--avoid=` 坏字节规避;这是 C 道旁边的实验编译道,不是 C 道的升级;PR #2 的测试合并留在 GitHub 记录里,锁定的树里没有(迁移时历史被压平)。
- README 写一次 cargo 产出三个 exe、每个 tag 带一份 PDF;zip(1.84MB,四 exe + vsix + stdlib)里没有 PDF。集成以清单和 Cargo 为准。在混合 workspace 根目录执行不带包选择的 `cargo build` 只构建根包,与 README 的差异是同一件事。
- star 297 全是公告转发(SEKTOR7、5mukx、PT dbugs),动手文字仅 brmk 上手与 CN-SEC 审查两篇,无外部缺陷帖;star 数不是生产采用的信号。
- typecheck 对空 branch 与非 void 函数里的裸 `ret;` 不报错,与锁定源码一致。
- 非 opsec 产物符号形状是 `__imp_LIB$Func`(CS 动态函数解析形);`--opsec=all` 后 `__imp_*` 符号消失,解析改为经过 PEB(hashed imports)。实例内唯一候选加载器是 wine 上的 COFFLoader64,先试不带 `--opsec=all` 的对象;不能假定 COFFLoader 能运行 opsec 产物。bof-launcher 的 Linux 面是 ELF 示例,不接受本产物。coffee-ldr 未装上(见 [coffee-ldr.md](coffee-ldr.md))。实例内的验证停在编译(真 COFF 或 118 字节 shellcode);运行留在目标机,或之后用 wine 再试。

## 参见

- [bof.md](bof.md)
- [wine.md](wine.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: entropia kind=tool path=/opt/entropia alias=entc note=Windows PIC shellcode/BOF 编译语言(entc,v0.1-experimental 源码构建;mingw 之外的高级语言道)
- rctl: entc-win32gen kind=tool path=/opt/entropia note=win32 头再生辅件(entropia 同仓构建,--winmd 再生 stdlib/win32)

# entropia:entc

> Windows PIC x86-64 shellcode / BOF 编译语言(.etpy)。bof 组的高级语言道,mingw 是 C 道 ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- `GIT_PIN[entropykit/entropia]` = 05acaba2a1a5fbde8cec3318319d053265ddb7ca。
- 该提交等于 tag `v0.1-experimental`。
- 解析日 2026-10-11。
- 仓库是单提交迁移面。HEAD 就是这个 tag。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- 上游实验标记的日期是 2026-06-23。
- issue #1 的评论日期是 2026-06-28。
- 升级:执行 `scripts/resolve-pins.sh`,审阅差异,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_bof`。
- `clone_pin` 到 `/opt/entropia`。
- 构建命令是 `cargo build --release --locked -p entropykit -p entc-win32gen`。
- crate 来自 tuna。
- 当前 rustc 是 1.99。
- 上游 MSRV 是 1.75。
- 1.99 满足该 MSRV。
- 不使用裸 `--workspace`。那会把 Windows 跑面也编出来。
- 然后 `install -m755` 安装 `entc`。
- release zip 的文件名是 `entropia-bin-v0.1-experimental.zip`。
- zip 大小是 1.84MB。
- 清单是四个 `.exe`、vsix 和 stdlib。
- 这是 Windows 预编译包。Linux 面不使用它。
- 辅件 `entc-win32gen` 尽力安装。
- `entc-debug`、`bof-runner`、`bof-loader` 是 Windows 跑面。
- 非 Windows 上的 load 与 run 直接返回错误。
- 这三个程序不安装。

## 文件

- `/usr/local/bin/entc`。
- `/usr/local/bin/entc-win32gen`。
- 源码与构建树在 `/opt/entropia`。
- 仓内带 `stdlib/win32` 头。
- 仓内带 20 个 `.etpy` 示例。
- 输出目标始终是 Windows x86-64。
- `.bin` 是 shellcode。
- `.x64.o` 是 BOF。

## 配置

- 无配置文件。
- 编译只读仓内 stdlib。
- win32 头来自 `stdlib/win32/*.h`。
- `use_c` 直接引用 Windows SDK 头。
- 没有外部数据面。
- `entc` 根包没有第三方依赖。
- 锁文件里的 29 个包都属于辅件。
- `entc-win32gen` 运行时需要 `--winmd`。
- `Windows.Win32.winmd` 由使用侧自备。
- 该文件在 microsoft/win32metadata 的 releases 里。
- 位置是 nupkg 内的 `ref/netstandard2.0/`。
- 仓库与 zip 都不包含这个 winmd。
- 因此离线不能重新生成头文件。
- 日常编译使用仓内 stdlib。
- 重新生成只在升级头文件时进行,并且需要网络。

## 离线行为

- 支持 `entc --version`。
- 支持编译示例 `bof_pslist.etpy`,产出 COFF `.x64.o`。
- 编译是本地计算。
- 源码没有网络调用。
- `entc-win32gen` 的构建会访问网络。
- `entc-win32gen` 的头文件再生会访问网络。
- 构建期 `CARGO_NET_OFFLINE=false` 是给辅件打开的在线面。
- 这个变量不是给编译器的。
- 关闭 eth0 后,`entc --version` 退 0。
- 在 `/opt/entropia` 执行 `entc compile examples/bof_pslist.etpy --type=bof`,得到 `.x64.o`。

## 限制

- 锁定 tag,不跟随 HEAD。
- issue #1 仍未修复。
- 现象是 resolver 崩溃。
- 原因是 unsafe branch relaxation 发出过期的短跳转偏移。
- 该评论晚于锁定提交。
- 此后 main 没有新代码。
- 语言还没有嵌套结构。
- 语言还没有 `--avoid=` 这种坏字节规避。
- 这是 C 道旁边的实验编译道。
- 它不是 C 道的升级。
- PR #2 的测试合并留在 GitHub 记录里。
- 锁定的树里没有这次合并。
- 迁移时历史被压平。
- README 写一次 cargo 产出三个 exe。
- README 写每个 tag 带一份 PDF。
- zip 里没有 PDF。
- 集成以清单和 Cargo 为准。
- 在混合 workspace 的根目录执行不带包选择的 `cargo build`,只构建根包。
- 这与 README 和 Cargo 的差异是同一件事。
- star 数是 297。
- 这些 star 都是公告转发。
- 转发来源包括 SEKTOR7、5mukx、PT dbugs。
- 动手记录只有两篇。
- 一篇是 brmk 的上手记录。
- `--opsec=all` 之后,`__imp_*` 符号消失。
- 解析改为经过 PEB。
- 另一篇是 CN-SEC 的审查。
- 没有外部缺陷帖。
- star 数不是生产采用的信号。
- typecheck 对空 branch 不报错。
- 非 void 函数里的裸 `ret;` 不报错。
- 这与锁定的源码一致。
- 非 opsec 产物的符号形状是 `__imp_LIB$Func`。
- 这是 CS 动态函数解析的形式。
- 实例内唯一的候选加载器是 wine 上的 COFFLoader64。
- 先试不带 `--opsec=all` 的对象。
- opsec 产物使用 hashed imports,经过 PEB。
- 不能假定 COFFLoader 能运行这些产物。
- bof-launcher 的 Linux 面是 ELF 示例。
- 它不接受本产物。
- coffee-ldr 没有装上。见 [coffee-ldr.md](coffee-ldr.md)。
- 实例内的验证停在编译。
- 编译结果是真 COFF,或 118 字节的 shellcode。
- 运行留在目标机,或之后用 wine 再试。

## 参见

- [bof.md](bof.md)
- [bof-launcher.md](bof-launcher.md)
- [coffee-ldr.md](coffee-ldr.md)
- [wine.md](wine.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: entropia kind=tool path=/opt/entropia alias=entc note=Windows PIC shellcode/BOF 编译语言(entc,v0.1-experimental 源码构建;mingw 之外的高级语言道)
- rctl: entc-win32gen kind=tool path=/opt/entropia note=win32 头再生辅件(entropia 同仓构建,--winmd 再生 stdlib/win32)

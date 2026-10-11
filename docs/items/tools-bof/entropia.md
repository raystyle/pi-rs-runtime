# entropia(entc)

> Windows PIC x86-64 shellcode / BOF 编译语言(.etpy),bof 组高级语言道(mingw 是 C 道)｜ 状态:已装 ｜ 组:`install-tools.sh bof`

- **版本钉**:源码 pins.sh `GIT_PIN[entropykit/entropia]`=05acaba2a1a5fbde8cec3318319d053265ddb7ca(= v0.1-experimental tag,2026-10-11 解析;仓是单提交迁移面,HEAD 即 tag),clone_pin 幂等;升级跑 scripts/resolve-pins.sh 审 diff 重跑本组
- **来源与安装**:`scripts/install-tools.sh install_bof` 段:clone_pin 到 `/opt/entropia`,`cargo build --release --locked`(workspace,经 tuna crates;rustc 1.99 过上游 MSRV 1.75)到 `install -m755` 装 `entc`;release zip(entropia-bin-v0.1-experimental.zip,1.84MB)是 Windows 预编,Linux 面不用;辅件 entc-win32gen(win32 头再生)尽力装,entc-debug/bof-runner/bof-loader 是 Windows 跑面(DAP tracer/harness)不装
- **落点**:`/usr/local/bin/entc`(+ `/usr/local/bin/entc-win32gen`);源码与构建树 `/opt/entropia`(stdlib/win32 头 + examples 21 例随仓);输出目标恒 Windows x86-64(`.bin` shellcode / `.x64.o` BOF)
- **配置与缓存**:无配置;编译只读仓内 stdlib(win32 头自 `stdlib/win32/*.h`,`use_c` 直引 Windows SDK 头),零外部数据面
- **离线行为**:过,`entc --version` 与示例编译(bof_pslist.etpy 出真 COFF `.x64.o`)断网实证;编译是本地计算零网络
- **坑与留痕**:experimental 单提交迁移仓(2026-06-23),钉 tag 不追 HEAD(上游再动先审 diff);混合 workspace 根裸 `cargo build` 只建根包(实证只出 entc),辅件要 `-p entc-win32gen` 点名;win32gen 的 windows-metadata 不在烤缓存,构建期要 `CARGO_NET_OFFLINE=false` 拿回在线面(运行期 cargo 默认离线);产物 BOF/shellcode 面向 Windows 目标,运行面(目标机/wine COFFLoader64)未实证,实例内实证止于编译面(真 COFF/118 字节 shellcode);grok prt-11 研究在档

## rctl 面(机器行:catalog 投影声明,audit 豁免依据)

- rctl: entropia kind=tool path=/opt/entropia alias=entc note=Windows PIC shellcode/BOF 编译语言(entc,v0.1-experimental 源码构建;mingw 之外的高级语言道)
- rctl: entc-win32gen kind=tool path=/opt/entropia note=win32 头再生辅件(entropia 同仓构建,--winmd 再生 stdlib/win32)

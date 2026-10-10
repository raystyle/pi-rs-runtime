# coffee-ldr

> Rust 现代 COFF loader(hakaioffsec/coffee,crate 名 coffee-ldr) ｜ 状态:未装上(nightly 构建失败留档) ｜ 组:`install-tools.sh bof`

- **版本钉**:pins.sh 钉版(`CRATE_PIN[coffee-ldr]`=0.2.2,`cargo +nightly install coffee-ldr --locked --version`;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;失败只 echo 留档(不再退 `--git` 源);nightly 工具链随源最新(rustup 装,pins.sh 未收钉位)
- **来源与安装**:[hakaioffsec/coffee](https://github.com/hakaioffsec/coffee)(crate 名 coffee-ldr);`scripts/install-tools.sh install_bof` 段:export `RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo` → `rustup toolchain install nightly --profile minimal` → `cargo +nightly install coffee-ldr --locked --version <钉>`(钉版轮起无 --git 退路)‖ echo 留档;幂等判据 `have coffee-ldr`
- **落点**(设计):`/opt/cargo/bin/coffee-ldr` 或 `~/.cargo/bin/coffee-ldr` 软链 `/usr/local/bin/coffee-ldr`;实际未装上(上游 nightly 亦编不过)
- **配置与缓存**:nightly 工具链装 `/opt/rustup`(借 rust 组共享面);coffee 本体未落盘
- **离线行为**:件未装上,无运行期离线面;☐ [推断:] nightly 工具链本体随 rustup 固化离线可用
- **坑与留痕**:上游 lib.rs 用 `#![feature(c_variadic/core_intrinsics)]`,stable 编不过必须 nightly;nightly 亦失败,裁定「上游问题,留档」(脚本出口文案;[PROGRESS.md](../../../PROGRESS.md) 待办节跟踪);失败不阻塞——BOF 运行还有 [bof-launcher](bof-launcher.md) 与 mingw/wine([wine.md](wine.md))路径;coffee-ldr 曾走 root `~/.cargo` 再链出,残留面口径见 [known-issues](../../known-issues.md)

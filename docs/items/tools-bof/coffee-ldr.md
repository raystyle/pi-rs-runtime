# coffee-ldr

> Rust 现代 COFF loader(hakaioffsec/coffee,crate 名 coffee-ldr)。nightly 构建失败 ｜ 状态:未装 ｜ 组:`install-tools.sh bof`

## 版本

- `CRATE_PIN[coffee-ldr]` = 0.2.2(解析日 2026-10-10)。
- 安装命令是 `cargo +nightly install coffee-ldr --locked --version <版本>`。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 bof 组。
- 失败时只 echo。
- 锁定版本之后不再改用 `--git` 源。
- nightly 工具链取 rustup 的最新版。
- pins.sh 没有收录 nightly 的锁定项。

## 来源与安装

- 上游:[hakaioffsec/coffee](https://github.com/hakaioffsec/coffee)。crate 名是 coffee-ldr。
- 脚本:`scripts/install-tools.sh` 的 `install_bof`。
- 构建前导出 `RUSTUP_HOME=/opt/rustup`。
- 同时导出 `CARGO_HOME=/opt/cargo`。
- 然后执行 `rustup toolchain install nightly --profile minimal`。
- 再执行带锁定版本的 `cargo +nightly install`。
- 幂等判据是 `have coffee-ldr`。

## 文件

- 设计上的二进制是 `/opt/cargo/bin/coffee-ldr`,或 `~/.cargo/bin/coffee-ldr`。
- 设计上再软链到 `/usr/local/bin/coffee-ldr`。
- 实际没有装上。上游在 nightly 上同样编译失败。

## 配置

- nightly 工具链装在 `/opt/rustup`。
- 该目录与 rust 组共用。
- coffee 本体没有落盘。

## 离线行为

- 本件没有装上,没有运行期离线面。
- 未验证:nightly 工具链本身随 rustup 固化后,断网可用。

## 限制

- 上游 `lib.rs` 使用 `#![feature(c_variadic/core_intrinsics)]`。
- stable 编译不过,必须用 nightly。
- nightly 也同样失败。
- 脚本的出口文案是:上游问题,只 echo。
- 失败不阻塞本组。
- BOF 运行还有 [bof-launcher.md](bof-launcher.md) 与 mingw/wine。见 [wine.md](wine.md)。
- coffee-ldr 曾经从 root 的 `~/.cargo` 安装再链出。残留规则见 [known-issues.md](../../known-issues.md)。

## 参见

- [bof.md](bof.md)
- [bof-launcher.md](bof-launcher.md)
- [wine.md](wine.md)
- [known-issues.md](../../known-issues.md)
- [offline.md](../../offline.md)

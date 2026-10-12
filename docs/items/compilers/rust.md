# Rust 工具链

> rustup + stable 工具链 + llvm-tools/rustfmt/clippy/rust-analyzer + 十向交叉 target + rust-script/cargo-zigbuild/cargo-audit + 29 件 crate 预热 ｜ 状态:已装 ｜ 组:`install-compilers.sh rust`

## 版本

- rustup-init 与 stable toolchain 随源最新。pins.sh 未收这两项钉位,取构建日的版本。
- `CRATE_PIN[rust-script]` = 0.36.0(解析日 2026-10-10)。
- `CRATE_PIN[cargo-zigbuild]` = 0.23.4(解析日 2026-10-10)。
- `CRATE_PIN[cargo-audit]` = 0.22.2(解析日 2026-10-10)。
- 这三件经 `cargo_install_pin` 安装,带 `--locked`。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。
- 预热的 29 个 crate 版本全是 `*`,不钉版。`cargo fetch` 取构建日最新。

## 来源与安装

- 安装器来自 [rustup.rs](https://rustup.rs),实际下载 `${RUSTUP_UPDATE_ROOT}/dist/<triple>/rustup-init`。
- 默认镜像是 rsproxy.cn。triple 按架构取 `x86_64-unknown-linux-gnu` 或 `aarch64-unknown-linux-gnu`。
- 安装命令:`rustup-init -y --default-toolchain stable --profile minimal`。
- 组件:`rustup component add llvm-tools rustfmt clippy rust-analyzer`。
- 交叉 target 经 `rustup target add` 安装。宿主 triple 随 stable 自带。
- rust-script 来自 [rust-lang/rust-script](https://github.com/rust-lang/rust-script),经 cargo 安装。
- cargo-zigbuild 来自 [rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild),经 cargo 安装。
- cargo-audit 来自 [rustsec/rustsec](https://github.com/rustsec/rustsec),经 cargo 安装。

## 文件

- `RUSTUP_HOME=/opt/rustup`,`CARGO_HOME=/opt/cargo`。`/root` 是 0700,放在 `/opt` 下多个用户才能读。
- `/usr/local/bin` 链出 rustc、cargo、rustup、rust-script、cargo-zigbuild、cargo-audit。
- rust-lld 从 `/opt/rustup/toolchains/*/lib/rustlib/*/bin/rust-lld` 探出,链到 `/usr/local/bin/rust-lld`。pi-rs 的执行链直接把它当链接器使用。
- root 与 ubuntu 的 `~/.rustup` 指向 `/opt/rustup`,`~/.cargo` 指向 `/opt/cargo`。已有真目录先挪到 `.bak`。

| target |
| --- |
| x86_64-unknown-linux-gnu |
| aarch64-unknown-linux-gnu |
| x86_64-unknown-linux-musl |
| aarch64-unknown-linux-musl |
| armv7-unknown-linux-gnueabihf |
| riscv64gc-unknown-linux-gnu |
| x86_64-pc-windows-gnu |
| i686-pc-windows-gnu |
| x86_64-apple-darwin |
| aarch64-apple-darwin |

## 配置

- `/opt/cargo/config.toml` 把 crates-io 换成 sparse 索引。`CRATES_INDEX` 默认 `https://rsproxy.cn/index`。
- 同一文件设置 `git-fetch-with-cli=true`。
- 同一文件设置 `[net] offline=true`。这是离线优先默认面。
- 构建脚本经 common.sh 导出 `CARGO_NET_OFFLINE=false` 拿回在线。环境变量优先于配置文件。
- `/etc/profile.d/rustup.sh` 导出 `RUSTUP_HOME`、`CARGO_HOME`、`RUSTUP_DIST_SERVER`、`RUSTUP_UPDATE_ROOT`。
- 同一文件导出 `CARGO_ZIGBUILD_CACHE_DIR=/opt/cargo-zigbuild-cache`。该文件只在登录 shell 生效。
- cargo-zigbuild 的缓存目录是 `/opt/cargo-zigbuild-cache`。root 与 ubuntu 的 `~/.cache/cargo-zigbuild` 软链到这里。
- 该缓存属 piopt 组,并带默认 ACL,共享可写。权限模型见 [offline.md](../../offline.md) 第 5 节。
- 29 个 crate 经 `cargo fetch` 进入 `/opt/cargo` 的 registry。点名包含 ureq、tokio、rustls、reqwest、tungstenite、regex、grep-*、tokio-socks。
- `cj-*` 与 `cancel-this` 是仓内 vendor,不预热。
- libcache rust 组另有 31 个加密与解析向 crate,`cargo add` 钉版后再 fetch。脚本是 `install-libcache.sh` 的 rust 组。

## 离线行为

- 支持:已经缓存的工具链和依赖。
- `/opt/cargo/config.toml` 中 `[net] offline=true` 时,获取未缓存的 crate 立即返回 not found。
- 验证:关闭 eth0 后,在新工程执行 `cargo add <未缓存 crate>`,命令立即失败。
- `rustc --version` 不访问网络。
- 依赖已在 `/opt/cargo` registry 的工程,`cargo build` 不访问网络。
- 工具链与组件位于 `/opt/rustup`。
- 未验证:windows-gnu 经 mingw-w64 的交叉链接。
- 未验证:apple-darwin 经 zig 的交叉链接。
- 未验证:cargo-audit 第一次运行需要 rustsec advisory-db,断网时不可用。

## 限制

- `incus exec` 不读取 `/etc/profile.d`。
- `$HOME/.rustup` 不存在时,rustup 报告 no default。
- `~/.rustup` 与 `~/.cargo` 是指向 `/opt/rustup` 和 `/opt/cargo` 的符号链接。
- 配置里的索引段名是 `tuna-sparse`。
- 生效索引由 `CRATES_INDEX` 决定,默认 `https://rsproxy.cn/index`。
- rust-lld 的查找同时检查 `/opt/rustup` 与 `/root/.rustup`。
- 再次执行本组时,`rustc` 已存在则跳过 rustup-init。
- 配置、profile、符号链接和预热每次重写。
- nightly 不由本组安装。
- coffee-ldr 需要 nightly 时,由 bof 组执行 `rustup toolchain install nightly`。
- 由 root 的 `~/.cargo` 安装的程序只链接二进制。其余文件见 [known-issues.md](../../known-issues.md)。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [rust 库缓存](../libcache/rust.md)

## rctl 面,机器行

- rctl: rustc kind=compiler path=/usr/local/bin/rustc note=Rust 编译器本尊
- rctl: cargo kind=compiler path=/usr/local/bin/cargo
- rctl: rustup kind=compiler path=/usr/local/bin/rustup
- rctl: rust-script kind=tool path=/usr/local/bin/rust-script note=单文件 Rust 脚本(CRATE_PIN 独立钉)
- rctl: cargo-zigbuild kind=tool path=/usr/local/bin/cargo-zigbuild note=cargo 交叉编译 zig 后端(独立钉)
- rctl: cargo-audit kind=tool path=/usr/local/bin/cargo-audit note=依赖审计(独立钉)
- rctl: rust-lld kind=compiler path=/usr/local/bin/rust-lld
- rctl: rustup kind=compiler path=/opt/rustup note=工具链管理本体(已并入 rust 册 rctl 面)
- rctl: rustup-home kind=compiler path=/opt/rustup note=工具链本体树(/usr/local/bin/rustup 的家)

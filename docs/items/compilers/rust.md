# Rust 工具链

> rustup + stable 工具链 + llvm-tools/rustfmt/clippy/rust-analyzer + 十向交叉 target + rust-script/cargo-zigbuild/cargo-audit + 29 件 crate 预热 ｜ 状态:已装 ｜ 组:`install-compilers.sh rust`

- **版本钉**:rustup-init 与 stable toolchain 随源最新(pins.sh 未收钉位,构建日取);rust-script/cargo-zigbuild/cargo-audit pins.sh 钉版(`CRATE_PIN[rust-script]`=0.36.0、`CRATE_PIN[cargo-zigbuild]`=0.23.4、`CRATE_PIN[cargo-audit]`=0.22.2,cargo_install_pin 带 `--locked`;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;预热 29 crate 全 `*` 未钉(库缓存面非工具钉),`cargo fetch` 取构建日最新
- **来源与安装**:[rustup.rs](https://rustup.rs) 到 `${RUSTUP_UPDATE_ROOT}/dist/<triple>/rustup-init`(默认 rsproxy.cn 镜像,triple 按架构取 x86_64/aarch64-unknown-linux-gnu)到 `rustup-init -y --default-toolchain stable --profile minimal`;组件 `rustup component add llvm-tools rustfmt clippy rust-analyzer`;交叉 target 十向 `rustup target add`(gnu/musl 的 x86_64+aarch64、armv7-gnueabihf、riscv64gc、windows-gnu x86_64+i686、apple-darwin x86_64+aarch64;宿主 triple 随 stable 自带);三件 [rust-lang/rust-script](https://github.com/rust-lang/rust-script)、[rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)、[rustsec/rustsec](https://github.com/rustsec/rustsec)(cargo-audit)经 cargo 装
- **落点**:`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`(/root 是 0700,归 /opt 才多用户可读,);`/usr/local/bin` 链出 rustc、cargo、rustup、rust-script、cargo-zigbuild、cargo-audit;rust-lld 从 `/opt/rustup/toolchains/*/lib/rustlib/*/bin/rust-lld` 探出链 `/usr/local/bin/rust-lld`(pi-rs 件执行链直接当链接器用);家目录兼容链 `~/.rustup`到/opt/rustup、`~/.cargo`到/opt/cargo(root+ubuntu,已有真目录挪 `.bak`)
- **配置与缓存**:`/opt/cargo/config.toml`:crates-io 换 sparse 索引(`CRATES_INDEX` 默认 `https://rsproxy.cn/index`)+ `git-fetch-with-cli=true` + `[net] offline=true`(离线优先默认面,构建脚本经 common.sh export `CARGO_NET_OFFLINE=false` 拿回在线,env 优先于 config);`/etc/profile.d/rustup.sh` 导出 RUSTUP_HOME/CARGO_HOME/RUSTUP_DIST_SERVER/RUSTUP_UPDATE_ROOT 与 `CARGO_ZIGBUILD_CACHE_DIR=/opt/cargo-zigbuild-cache`(仅登录 shell 备份面);cargo-zigbuild 缓存共享:/opt/cargo-zigbuild-cache + `~/.cache/cargo-zigbuild` 软链(root+ubuntu),piopt 组 + 默认 ACL 共享可写([ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md));件 crate 预热 29 个(ureq/tokio/rustls/reqwest/tungstenite/regex/grep-*/tokio-socks 等,`cargo fetch` 进 /opt/cargo registry;cj-*/cancel-this 为仓内 vendor 不预热);libcache rust 组另有 31 个加密/解析向 crate `cargo add` 钉版后 fetch(`install-libcache.sh rust`)
- **离线行为**:支持已经缓存的工具链和依赖。`/opt/cargo/config.toml` 中 `[net] offline=true` 时,获取未缓存的 crate 立即返回 not found。验证:关闭 eth0 后在新工程执行 `cargo add <未缓存 crate>`,命令立即失败;`rustc --version` 不访问网络;依赖已在 `/opt/cargo` registry 的工程,`cargo build` 不访问网络。工具链与组件位于 /opt/rustup。未验证:windows-gnu 经 mingw-w64 的交叉链接,以及 apple-darwin 经 zig 的交叉链接。未验证:cargo-audit 第一次运行需要 rustsec advisory-db,断网时不可用。
## rctl 面,机器行:catalog 投影声明,audit 豁免依据

- rctl: rustc kind=compiler path=/usr/local/bin/rustc note=Rust 编译器本尊
- rctl: cargo kind=compiler path=/usr/local/bin/cargo
- rctl: rustup kind=compiler path=/usr/local/bin/rustup
- rctl: rust-script kind=tool path=/usr/local/bin/rust-script note=单文件 Rust 脚本(CRATE_PIN 独立钉)
- rctl: cargo-zigbuild kind=tool path=/usr/local/bin/cargo-zigbuild note=cargo 交叉编译 zig 后端(独立钉)
- rctl: cargo-audit kind=tool path=/usr/local/bin/cargo-audit note=依赖审计(独立钉)
- rctl: rust-lld kind=compiler path=/usr/local/bin/rust-lld
- rctl: rustup kind=compiler path=/opt/rustup note=工具链管理本体(已并入 rust 册 rctl 面)
- rctl: rustup-home kind=compiler path=/opt/rustup note=工具链本体树(/usr/local/bin/rustup 的家)

- **限制**:`incus exec` 不读取 `/etc/profile.d`。`$HOME/.rustup` 不存在时,rustup 报告 no default。`~/.rustup` 与 `~/.cargo` 是指向 /opt/rustup 和 /opt/cargo 的符号链接。配置里的索引段名是 `tuna-sparse`;生效索引由 `CRATES_INDEX` 决定,默认 `https://rsproxy.cn/index`。rust-lld 的查找同时检查 /opt/rustup 与 /root/.rustup。再次执行本组时,`rustc` 已存在则跳过 rustup-init;配置、profile、符号链接和预热每次重写。nightly 不由本组安装;coffee-ldr 需要 nightly 时,由 bof 组执行 `rustup toolchain install nightly`。由 root 的 `~/.cargo` 安装的程序只链接二进制,其余文件见 [known-issues.md](../../known-issues.md)。

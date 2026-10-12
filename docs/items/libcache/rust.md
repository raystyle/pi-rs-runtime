# Rust 库缓存:crate 预热

> 加密/证书/解析/协议向 31 个 crate 构建期 fetch 进 /opt/cargo registry,断网 cargo 编译直用 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh rust`

## 版本

- `cargo add <crate>` 在构建日解析精确版本,并写进预热工程的 Cargo.toml。
- `cargo fetch --locked` 按锁拉取字节。
- `cargo fetch --locked` 失败时退回 `cargo fetch`。
- 预热工程是 `/opt/rust-prewarm-libs`。
- 用完后 `rm -rf` 删除该工程。
- 预热工程删除后,Cargo.lock 不留在该目录。
- 钉版记录只在构建日志里,字节留在缓存。
- 锁已入库 `scripts/lock/rust/`(Cargo.toml 与 Cargo.lock)。
- 这套锁按 31 个 crate 的清单重建,并用 generate-lockfile 收割。
- 有锁时用 `cargo fetch --locked` 消费。
- 再生执行 `scripts/sync-locks.sh`。
- 升级:在有网阶段重跑本组。

## 来源与安装

- crates.io 经 tuna sparse 索引。
- 索引写在 `/opt/cargo/config.toml`,由 install-compilers.sh 的 rust 组写入。
- 脚本:`scripts/install-libcache.sh` 的 `install_rust`。
- 临时工程对 31 个 crate 逐个执行 `cargo add`。
- 单个 `cargo add` 失败只打印,不中断。
- 然后 `cargo fetch` 进入 registry 缓存。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/cargo | CARGO_HOME,registry 索引与字节 |
| /opt/rust-prewarm-libs | 预热工程,用后删除 |
| /usr/local/bin | 本组无入口;工具链与 rust-script 等命令属于 rust 组 |

## 配置

- 运行期靠家目录符号链接发现缓存。
- `~/.cargo` 指向 /opt/cargo。
- `~/.rustup` 指向 /opt/rustup。
- root 与 ubuntu 都有这两条链接。
- rust 组负责补上这些链接。
- 非登录 shell 也走这些链接。
- `/opt/cargo/config.toml` 的 `[net] offline=true` 使未缓存的拉取立即失败。
- 构建脚本经 common.sh 导出 `CARGO_NET_OFFLINE=false`,拿回在线面。
- 环境变量优先于配置文件。
- 机制见 [offline.md](../../offline.md) 第 1 节与第 4 节。

## 离线行为

- 支持:断网拉取未缓存的 crate 时,立即报 not found。
- 该行为与五生态的立即失败一致,见 [offline.md](../../offline.md) 第 4 节。
- 支持:依赖已在缓存中时,root 与 ubuntu 都可以断网编译。
- cargo-zigbuild 使用同一棵缓存树。
- 权限模型见 [offline.md](../../offline.md) 第 5 节。
- 验证:关闭 eth0 后,对含缓存依赖的工程执行 `cargo build --offline`。

## 限制

- install-compilers.sh 的 rust 组另有 29 个件级 crate 预热。
- 这 29 个用 `*` ,未钉版本。
- 清单见 [software-inventory](../../software-inventory.md) 的预缓存库节。
- 这 29 个与本批 31 个互补。
- fff-mcp 不安装二进制。
- fff-search 只入库。
- windows-sys 入库。
- 说明见 [known-issues.md](../../known-issues.md)。
- 预热工程删除后,Cargo.lock 不留在工程目录。
- 要精确版本时,查构建日志,或重跑本组。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [software-inventory](../../software-inventory.md)

## rctl 面,机器行

- rctl: cargo-zigbuild-cache kind=cache path=/opt/cargo-zigbuild-cache note=cargo-zigbuild 缓存树(共享 ACL)

## 成员清单

31 个 crate,以脚本 `install_rust` 为准。

| 类 | 成员 |
|---|---|
| 加密 | aes-gcm、chacha20poly1305、rsa、p256、x25519-dalek、md-5、pbkdf2、argon2、jsonwebtoken |
| 证书 | rcgen、x509-parser、pem、rasn |
| 二进制解析 | goblin、object、iced-x86、nom |
| 协议/网络 | ldap3、pnet、quinn、tokio-tungstenite |
| 骨架/序列化 | clap、serde、thiserror、tracing |
| 压缩/系统 | flate2、zip、memmap2、nix |
| 选定入库 | fff-search、windows-sys |

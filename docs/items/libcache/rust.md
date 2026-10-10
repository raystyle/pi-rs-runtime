# Rust 库缓存(crate 预热)

> 加密/证书/解析/协议向 31 个 crate 构建期 fetch 进 /opt/cargo registry,断网 cargo 编译直用 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh rust`

- **版本钉**:`cargo add <crate>` 构建日解析精确版本写进预热工程 Cargo.toml,`cargo fetch --locked` 钉版拉字节(失败退回 `cargo fetch`);预热工程 `/opt/rust-prewarm-libs` 用后 `rm -rf` 删除,Cargo.lock 不存盘——钉版记录只在构建日志,字节留在缓存;repo 侧锁文件回收是 PROGRESS.md 待办 3。升级=有网阶段重跑本组
- **来源与安装**:crates.io 经 tuna sparse 索引(`/opt/cargo/config.toml`,install-compilers.sh rust 组写);脚本面 `scripts/install-libcache.sh` `install_rust()`——临时工程逐个 `cargo add` 31 crate(单个失败只 echo 不中断)后 `cargo fetch` 进 registry 缓存
- **落点**:`/opt/cargo`(CARGO_HOME,registry 索引+字节);预热工程 `/opt/rust-prewarm-libs` 用后删除;无 `/usr/local/bin` 入口(纯库缓存,工具链与 rust-script 等命令件是 rust 组的面)
- **配置与缓存**:运行期发现靠家目录软链 `~/.cargo`→/opt/cargo、`~/.rustup`→/opt/rustup(root+ubuntu,rust 组兜底,非登录 shell 也生效);`/opt/cargo/config.toml` `[net] offline=true` 默认快失败,构建脚本经 common.sh `CARGO_NET_OFFLINE=false` 拿回在线面(env 优先于配置文件);机制见 [offline.md](../../offline.md) §1/§4
- **离线行为**:✅ 断网拉未缓存 crate 立即报 not found(五生态快失败轮,[offline.md](../../offline.md) §4 标实证);✅ 依赖缓存的断网编译 root/ubuntu 双视角实证(cargo-zigbuild 同缓存树,[ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md) 轮)。验证:`ip link set eth0 down` 后对含缓存依赖的工程 `cargo build --offline`
- **坑与留痕**:install-compilers.sh rust 组另有 29 个件 crate 预热(`*` 未钉,清单见 [software-inventory](../../software-inventory.md) 预缓存库节),与本批互补;fff-mcp 不装二进制、fff-search 只入库,windows-sys 是 grok 库评审唯一入库件(用户裁定,见 [known-issues](../../known-issues.md));预热工程删除后 Cargo.lock 不留存,要精确版本只能查构建日志或重跑本组

成员清单(31 crate,以脚本 `install_rust()` 为准):

| 类 | 成员 |
|---|---|
| 加密 | aes-gcm、chacha20poly1305、rsa、p256、x25519-dalek、md-5、pbkdf2、argon2、jsonwebtoken |
| 证书 | rcgen、x509-parser、pem、rasn |
| 二进制解析 | goblin、object、iced-x86、nom |
| 协议/网络 | ldap3、pnet、quinn、tokio-tungstenite |
| 骨架/序列化 | clap、serde、thiserror、tracing |
| 压缩/系统 | flate2、zip、memmap2、nix |
| 评审裁定入库 | fff-search、windows-sys |

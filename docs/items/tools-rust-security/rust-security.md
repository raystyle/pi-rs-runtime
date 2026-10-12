# Rust 安全工具集:rust-security 组

> rustscan(快扫)/ feroxbuster(内容发现)/ RustHound-CE(BloodHound CE 采集器) ｜ 状态:已装 ｜ 组:`install-tools.sh rust-security`

## 版本

- 解析日 2026-10-10。
- `CRATE_PIN[rustscan]` = 2.4.1。
- `CRATE_PIN[feroxbuster]` = 2.13.1。
- 这两件的命令是 `cargo install <crate> --locked --version <版本>`。
- `--locked` 使用该 crate 自带的 `Cargo.lock`。
- `GIT_PIN[g0h4n/RustHound-CE]` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- RustHound-CE 再执行 `cargo build --release --locked`。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- rustscan 上游:[rustscan/rustscan](https://github.com/rustscan/rustscan),包在 crates.io。
- feroxbuster 上游:[epi052/feroxbuster](https://github.com/epi052/feroxbuster),包在 crates.io。
- sparse index 经 `CRATES_INDEX`。
- RustHound-CE 上游:[g0h4n/RustHound-CE](https://github.com/g0h4n/RustHound-CE)。crates.io 没有这个包。
- 源码经 `GITHUB_MIRROR` 克隆后构建。
- 脚本:`scripts/install-tools.sh` 的 `install_rust-security`。
- 构建前先 apt 安装 `libkrb5-dev`。

## 文件

- rustscan 与 feroxbuster 安装到 `/opt/cargo/bin`。
- 构建时 `RUSTUP_HOME=/opt/rustup`,`CARGO_HOME=/opt/cargo`。
- 这两件再 `ln -sf` 到 `/usr/local/bin`。
- RustHound-CE 源码在 `/opt/tradecraft-ref/ad/RustHound-CE`。
- release 二进制用 `install -m755` 装到 `/usr/local/bin/rusthound-ce`。

## 配置

- cargo registry 缓存共用 `/opt/cargo`。
- `/opt/cargo/config.toml` 做源替换,并且 `[net] offline=true` 是运行期默认。
- 构建期 common.sh 导出 `CARGO_NET_OFFLINE=false`,换回在线面。见 [offline.md](../../offline.md)。
- 无组级配置。

## 离线行为

- 支持。三个二进制在断网时可以启动。规定见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`rustscan --version` 退 0。
- 未验证:断网扫描本机或内网目标。
- rustscan 的后端调用本机 nmap。
- feroxbuster 使用本地词表。`/usr/share/wordlists` 有 `rockyou.txt`,以及 SecLists 软链。
- 判定:断网后 `python3 -m http.server 8000 &`,再执行 `feroxbuster -u http://127.0.0.1:8000 -w /usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt -n`。
- 未验证:rusthound-ce 的采集。它走内网 LDAP 与 Kerberos,断外网不改变这条协议路径。
- 镜像里没有域环境,采集本身未验证。
- 判定入口:`rusthound-ce --help` 退 0。

## 限制

- RustHound-CE 依赖 libgssapi-sys,需要 `gssapi.h`。
- 缺少 `libkrb5-dev` 时,bindgen 报致命错误。脚本在构建前 apt 安装它。
- crates.io 没有 RustHound-CE,只能从源码构建。
- 源码放在 `tradecraft-ref/ad`。这是操作员 AD 工具。
- 归档位置与是否编译无关。
- findomain 不安装。它的依赖多,经常编译失败。
- 需要 findomain 时,使用 [Findomain releases](https://github.com/Findomain/Findomain/releases) 的预编译包。脚本注释与 [known-issues.md](../../known-issues.md) 都是这条。
- 组日志仍写「经 tuna crates」。这是旧称呼。
- 实际 `CRATES_INDEX` 默认 `https://rsproxy.cn/index`,定义在 `lib/common.sh`。
- `config.toml` 里的源名 `tuna-sparse` 与这个默认索引不一致。
- 三件各自以 `have` 为早退判据。
- RustHound-CE 构建失败时,本次不安装。再次执行该组时安装。
- 升级时删除 `/usr/local/bin/rusthound-ce` 后重跑本组,源码会更新到新的 HEAD。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [pentest.md](../tools-pentest/pentest.md)

## 成员清单

| 命令 | 安装路径 | 用途 |
|---|---|---|
| rustscan | cargo install(crates.io,--locked) | 快速端口扫描(批喂 nmap) |
| feroxbuster | cargo install(crates.io,--locked) | 强制目录/内容发现 |
| rusthound-ce | 源码构建(GitHub,--depth 1) | BloodHound CE 的 AD 采集器(Linux 直跑) |

# Rust 安全工具集(secrust 组)

> rustscan(快扫)/ feroxbuster(内容发现)/ RustHound-CE(BloodHound CE 采集器) ｜ 状态:已装 ｜ 组:`install-tools.sh secrust`

- **版本钉**:rustscan/feroxbuster `cargo install <crate> --locked`(crate 未钉版本=装当时 latest,`--locked` 用其自带 Cargo.lock 钉依赖);RustHound-CE 是 `git clone --depth 1` 未钉提交 + `cargo build --release --locked`([known-issues](../../known-issues.md) 未钉登记)
- **来源与安装**:[rustscan/rustscan](https://github.com/rustscan/rustscan)、[epi052/feroxbuster](https://github.com/epi052/feroxbuster)(crates.io,sparse index 经 `CRATES_INDEX`);[g0h4n/RustHound-CE](https://github.com/g0h4n/RustHound-CE)(crates.io 无包,源码经 GITHUB_MIRROR 克隆构建);安装面 `scripts/install-tools.sh` `install_secrust`,构建前先 apt 装 `libkrb5-dev`
- **落点**(批量机制):rustscan/feroxbuster 落 `/opt/cargo/bin`(`RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo`)并 `ln -sf` 到 `/usr/local/bin`;RustHound-CE 源码归档 `/opt/tradecraft-ref/ad/RustHound-CE`(三轴归档,[ADR-0002](../../adr/ADR-0002-reference-clone-three-axis.md)),release 二进制 `install -m755` 到 `/usr/local/bin/rusthound-ce`
- **配置与缓存**(批量机制):cargo registry 缓存共用 `/opt/cargo`;`/opt/cargo/config.toml` 源替换 + `[net] offline=true` 是运行期默认,构建期 common.sh export `CARGO_NET_OFFLINE=false` 拿回在线面([offline.md](../../offline.md) §1/§4);无组级配置
- **离线行为**:✅ 二进制断网可跑(渗透工具面断网冒烟口径见 [offline.md](../../offline.md) §验证)。验证:`ip link set eth0 down` 后 `rustscan --version` 退 0。☐ [推断:] 断网扫本机/内网目标可用——rustscan 后端调本机 nmap,feroxbuster 用本地词表(`/usr/share/wordlists` 有 rockyou.txt 与 SecLists 软链);验证:断网后 `python3 -m http.server 8000 &` 再 `feroxbuster -u http://127.0.0.1:8000 -w /usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt -n`。☐ [推断:] rusthound-ce 采集面是内网 LDAP/Kerberos 域控,断外网不伤其协议面,但镜像无域环境未实证;验证:`rusthound-ce --help` 退 0
- **坑与留痕**:RustHound-CE 依赖 libgssapi-sys 要 `gssapi.h`——缺 `libkrb5-dev` 则 bindgen 致命错,脚本构建前先 apt 装;crates.io 无此包只能源码构建,源码归 tradecraft-ref/ad 是 grok 裁定(操作员 AD 工具,归档位置与编不编译脱钩);findomain 不装:依赖多常编不过,要用走 [Findomain releases](https://github.com/Findomain/Findomain/releases) 预编译(脚本注释,[known-issues](../../known-issues.md) 登记);组日志文案「经 tuna crates」沿旧称,实际 `CRATES_INDEX` 默认 `https://rsproxy.cn/index`(lib/common.sh;config.toml 里源名 tuna-sparse 同漂移);幂等:三件各自 `have` 早退,RustHound-CE 构建失败留「下轮补」,升级删 `/usr/local/bin/rusthound-ce` 重跑会拉到新 HEAD

## 成员表(3)

| 命令 | 安装路径 | 用途 |
|---|---|---|
| rustscan | cargo install(crates.io,--locked) | 快速端口扫描(批喂 nmap) |
| feroxbuster | cargo install(crates.io,--locked) | 强制目录/内容发现 |
| rusthound-ce | 源码构建(GitHub,--depth 1) | BloodHound CE 的 AD 采集器(Linux 直跑) |

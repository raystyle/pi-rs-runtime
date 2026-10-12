# ast-grep:sg

> 结构化代码搜索与改写 CLI(入口 ast-grep 与 sg) ｜ 状态:已装 ｜ 组:`install-tools.sh astgrep`

## 版本

- `CRATE_PIN[ast-grep]`=0.50.0(解析日 2026-10-10)。cargo_install_pin 带 `--locked --version`,锁随 crate 发布自带的 Cargo.lock。
- 升级:运行 `scripts/resolve-pins.sh`。幂等判据 `have ast-grep`;重跑不升级,升级需删产物再重跑。

## 来源与安装

- 上游:[ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)。
- crates 稀疏索引:`CRATES_INDEX` 默认 rsproxy.cn(源规定见 [docs/params.md](../../params.md))。
- 脚本 `install_astgrep` 显式 `export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo` 并把 `/opt/cargo/bin` 挂上 PATH 后才 `cargo install`;产物归 /opt,不归 root 家目录。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/cargo/bin/ast-grep、/opt/cargo/bin/sg | 被包装的程序 |
| /usr/local/bin/ast-grep、/usr/local/bin/sg | 软链;ubuntu 可执行 |

## 配置

- 无本件专属。cargo registry 缓存与运行期 `[net] offline=true` 属 rust 组配置(/opt/cargo/config.toml);机制见 [docs/offline.md](../../offline.md)。

## 离线行为

- 未验证:扫描与改写本地代码不触网。
- 断网重跑本组幂等早退;断网新装会撞 cargo `offline=true` 亚秒快失败,属预期。
- 验证:关闭 eth0 后 `printf 'print(1)\n' > /tmp/sg-smoke.py && sg run -p 'print($A)' --lang python /tmp/sg-smoke.py` 退出码 0。

## 限制

- sg 撞名:noble 的 shadow 包自带 `/usr/bin/sg`(switch group)。按 `have sg` 判装恒真,ast-grep 会被永远跳过;判装与链接一律用全名 `ast-grep`,装完才把 `/opt/cargo/bin/sg` 链进 `/usr/local/bin`(PATH 前段压过 /usr/bin/sg)。要用 shadow 的切组命令请写全路径 `/usr/bin/sg`。
- install-surfaces 旧面写的 `ln -sf /root/.cargo/bin/sg` 是漂移前写法;现脚本产物落 /opt/cargo/bin,以本册为准(/root 0700 残留面史见 [known-issues.md](../../known-issues.md))。

## 参见

- [docs/params.md](../../params.md)
- [known-issues.md](../../known-issues.md)

## rctl 面,机器行

- rctl: ast-grep kind=tool path=/usr/local/bin/ast-grep note=入口名(带连字符)
- rctl: sg kind=tool path=/usr/local/bin/sg

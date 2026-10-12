# fnm:Node 版本管理器

> fnm 多版本 node 管理器,预装 18/20/22/24 四条线 ｜ 状态:已装 ｜ 组:`install-runtimes.sh fnm`

## 版本

- `CRATE_PIN[fnm]` = 1.39.0(解析日 2026-10-10)。`cargo_install_pin` 带 `--locked`。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。构建期 crates 索引走 rsproxy(`lib/common.sh` 的 `CRATES_INDEX`)。
- node 各线为 `FNM_NODE_VERSIONS="18 20 22 24"`(`lib/common.sh`)。大版本内取最新。

## 来源与安装

- 来源:[Schniz/fnm](https://github.com/Schniz/fnm),经 cargo 安装。
- 安装时 `RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`。依赖 rust 组先就位。
- node 二进制经 `fnm install --node-dist-mirror "$NODE_MIRROR"` 逐线安装。镜像是 npmmirror。
- 默认版本取 `fnm ls` 里 `sort -uV` 的最新一条(24 线),再 `fnm default`。该命令带 `|| true`,失败不致命。

## 文件

- fnm 本体在 `/opt/cargo/bin/fnm`。脚本不链 `/usr/local/bin`。
- 各版本 node 在 `~/.local/share/fnm/node-versions/<版本>/installation/`。构建期只填 root 的这份。
- `/etc/profile.d/fnm.sh` 是登录面:PATH 加上 `$HOME/.local/share/fnm`,并 `eval "$(fnm env)"`。
- 本组不改 `/usr/local/bin`。系统 node 仍是 `/opt/node` 的 24.21.0。全局 npmrc、bun、tsc 都挂在那个 prefix。
- 项目切换版本用 `fnm use` 或 `fnm exec`。

## 配置

- 组尾循环给 root 与 ubuntu 两侧的每个 fnm 版本写 prefix 级 `etc/npmrc`。
- 离线键与 `/opt/node` 同形:`offline=true`、`fetch-retries=0`、mintimeout 500、maxtimeout 1000。
- 先用 sed 清掉旧键,再追加。该写入幂等。

## 离线行为

- 未验证:fnm 各版本的 `npm install` 是否立即失败。prefix npmrc 与 `/opt/node` 逐键同形。机制见 [node 册](node.md)。没有 fnm 版本专属的断网记录。
- 判定:关闭 eth0 后,在该版本 prefix 下执行 `npm install lodash`。
- 支持:js-lab 固化包。libcache 组把包软链进 fnm 各版本 prefix 的 `lib/node`。脚本循环覆盖 `/root` 的 fnm 目录。
- 断网 require 与系统 node 相同。 [offline.md](../../offline.md) 第 1 节登记「各 node prefix」。断网冒烟覆盖 node 的 require。

## 限制

- 首次 install-all 时,[node 册](node.md) 里的 fnm npmrc 顺写落空。
- `RUNTIMES_ALL` 的顺序是 node 先于 fnm,当时版本目录还不存在。
- 本组尾部循环是这一步的补写,并且同时覆盖 ubuntu。
- [known-issues.md](../../known-issues.md) 的旧规定写的是「fnm 经 root `~/.cargo` 安装,再链 `/usr/local/bin`」。现行脚本不是这样。
- 现行 `CARGO_HOME=/opt/cargo`,并且不链 `/usr/local/bin`。以脚本为准。

## 参见

- [node 册](node.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

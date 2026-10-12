# Bun 运行时

> bun/bunx 一体化 JS 运行时与包管理器 ｜ 状态:已装 ｜ 组:`install-runtimes.sh bun`

## 版本

- `BUN_VERSION=1.4.3`(解析日 2026-10-10)。
- 安装命令:`npm install -g bun@$BUN_VERSION`。registry 是 npmmirror。
- 升级:运行 `scripts/resolve-pins.sh`,再按「限制」里的步骤重跑本组。

## 来源与安装

- 上游是 [bun.sh](https://bun.sh)。安装走 npmmirror 的 npm 全局安装。
- 装在 `/opt/node` 这个 prefix 下。依赖 [node 册](node.md) 先就位。
- 脚本:`scripts/install-runtimes.sh` 的 `install_bun`。

## 文件

- npm shim 位于 `/opt/node/bin/bun` 与 `/opt/node/bin/bunx`。
- 二者软链到 `/usr/local/bin/bun` 与 `/usr/local/bin/bunx`。
- 非交互 shell 的 PATH 不含 `/opt/node/bin`,所以用这条固定链接兜底。

## 配置

- bun 不读 npmrc,读 bunfig。
- root 与 ubuntu 各写 `~/.bunfig.toml`。
- 内容是 `[install] registry = "https://registry.npmmirror.com"`。这是官方推荐写法。
- 无固化缓存。
- bunfig 只写 registry,不写离线键。

## 离线行为

- 未验证:断网拉新件。bun 不吃 npmrc 的离线双保险,离线拉新按自身重试节奏走。
- 规定不钉默认离线,因为量级小。见 [offline.md](../../offline.md) 第 4 节。没有断网专项记录。
- 判定:关闭 eth0 后执行 `mkdir -p /tmp/bt && cd /tmp/bt && bun add lodash`,观察失败节奏。

## 限制

- 早退判据 `have bun` 写在 bunfig 写入之前。
- bun 已经存在时,重跑本组不刷新 bunfig。
- 该顺序与「配置写入放早退前」不一致。当前脚本仍是这个顺序。
- 已钉 `BUN_VERSION`,但 `have bun` 早退不重装。
- 升级步骤:运行 `scripts/resolve-pins.sh` 刷新钉值,然后 `npm uninstall -g bun`,再重跑本组。

## 参见

- [node 册](node.md)
- [offline.md](../../offline.md)

## rctl 面,机器行

- rctl: bunx kind=runtime path=/usr/local/bin/bunx

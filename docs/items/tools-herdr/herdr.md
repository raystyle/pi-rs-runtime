# herdr

> 终端 workspace 管理器(tmux 之外的 agent 编排面) ｜ 状态:已装 ｜ 组:`install-tools.sh herdr`

## 版本

- `HERDR_VERSION=0.9.3`(lib/common.sh;herdr.dev stable 频道)。
- `HERDR_SHA256=18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7` 锁定 linux-x86_64 资产;`sha256sum -c` 校验不过即 exit 1。

## 来源与安装

- 上游:[herdrdev/herdr](https://github.com/herdrdev/herdr) release 直下,无国内镜像,走 GITHUB_MIRROR 前置代理(规定见 [docs/params.md](../../params.md))。
- 官方安装通道是 herdr.dev/install.sh(解析 latest.json 下 GitHub release);脚本 `install_herdr` 等价实现并锁定版本。

## 文件

- `install -m755 /tmp/herdr /usr/local/bin/herdr`,全局可用;不走官方安装器的 `~/.local/bin`。

## 配置

- 无(脚本不写配置)。

## 离线行为

- 未验证:本体是本地终端编排器,起窗格不触网。
- 其编排的智能体后端连通性属各 agent 自身;断网失败不是缺陷(边界见 [docs/offline.md](../../offline.md))。
- 验证:关闭 eth0 后 `herdr --version` 退出码 0。

## 限制

- sha256 只锁定 x86_64 资产;arm64(aarch64)跳过校验,换版本时要重算补写锁定值(脚本注释;同类缺口见 [known-issues.md](../../known-issues.md))。
- 架构映射只认 amd64→x86_64 与 arm64→aarch64;其余架构返回 1。
- 幂等判据是 `have herdr`;升级要先删 `/usr/local/bin/herdr` 再重跑组才生效。

## 参见

- [docs/params.md](../../params.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: herdr kind=tool path=/usr/local/bin/herdr note=终端 workspace 管理器(agent 编排面)

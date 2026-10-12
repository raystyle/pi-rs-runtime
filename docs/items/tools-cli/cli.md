# 基础命令行工具

> git/jq/yq/shellcheck/gh/just/tmux/rclone/aria2/fzf/bat/htop/ncdu/moreutils/vim 一批 ｜ 状态:已装 ｜ 组:`install-tools.sh cli`

## 版本

- apt 批 13 包:noble 源冻结即锁定(源锁定记录见 [known-issues.md](../../known-issues.md))。
- yq:`GO_PIN[github.com/mikefarah/yq/v4]`=v4.54.1(解析日 2026-10-10)。
- gh:`GO_PIN[github.com/cli/cli/v2/cmd/gh]`=v2.102.0。
- just:优先 apt 随批;`have just` 不成立时 `CRATE_PIN[just]`=1.58.0 兜底(`--locked`)。
- 升级:运行 `scripts/resolve-pins.sh`。go/cargo 段有 `have && skip` 早退,升级需先删产物再重跑。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_cli`。
- apt 批带 `|| true`:批内单包失败不中断后续 go/cargo 段,复跑幂等补齐。
- yq:`go_install_pin github.com/mikefarah/yq/v4`(goproxy.cn)。
- gh:`go_install_pin github.com/cli/cli/v2/cmd/gh`(官方 apt 源国内无镜像,源码编译)。
- apt 镜像为阿里云;源规定见 [docs/params.md](../../params.md)。

## 文件

- apt 批落 `/usr/bin`。noble 的 bat 包二进制名是 `batcat`,链 `/usr/local/bin/bat` 回通用名。
- go 段显式 `export GOPATH=/opt/go`;产物落 `/opt/go/bin`,再链 `/usr/local/bin/yq` 与 `/usr/local/bin/gh`。
- just 兜底与 astgrep 同式:`export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo` 加 PATH;产物 `/opt/cargo/bin/just` 链 `/usr/local/bin/just`。

| 成员 | 入口 | 来源 | 路径 |
| --- | --- | --- | --- |
| git | `git` | apt noble | `/usr/bin` |
| jq | `jq` | apt noble | `/usr/bin` |
| shellcheck | `shellcheck` | apt noble | `/usr/bin` |
| just | `just` | apt noble(缺包时 cargo 兜底 1.58.0) | `/usr/bin`(兜底时 `/opt/cargo/bin` 链出) |
| tmux | `tmux` | apt noble | `/usr/bin` |
| rclone | `rclone` | apt noble | `/usr/bin` |
| aria2 | `aria2c` | apt noble | `/usr/bin` |
| fzf | `fzf` | apt noble | `/usr/bin` |
| bat | `bat`(包内二进制 `batcat`) | apt noble | `/usr/bin/batcat` + `/usr/local/bin/bat` 软链 |
| htop | `htop` | apt noble | `/usr/bin` |
| ncdu | `ncdu` | apt noble | `/usr/bin` |
| moreutils | `sponge`/`parallel` 等 | apt noble | `/usr/bin` |
| vim | `vim` | apt noble | `/usr/bin` |
| yq | `yq` | go_install_pin v4.54.1 | `/opt/go/bin` 链出 |
| gh | `gh` | go_install_pin v2.102.0 | `/opt/go/bin` 链出 |

## 配置

- 无(脚本不写配置文件,无缓存固化)。

## 离线行为

- 未验证:本地件不触网,含 jq、yq、shellcheck、just、tmux、fzf、bat、htop、ncdu、moreutils、vim、git 本地操作。
- 联网面(rclone/aria2c 下载、gh API、git remote)断网失败属设计边界(见 [docs/offline.md](../../offline.md) 边界节)。
- 验证:关闭 eth0 后 `yq --version >/dev/null && just --version >/dev/null && gh --version >/dev/null` 退出码 0。

## 限制

- go 产物必须 `GOPATH=/opt/go`。不设则 `go install` 落 `/root/go`(权限 0700),ubuntu 不可执行。现脚本 yq 与 gh 都设 GOPATH 并都链出。
- just 兜底必须显式指 /opt/cargo(与 [astgrep](../tools-astgrep/astgrep.md) 同式);否则 cargo 产物落 `/root/.cargo`(0700),ubuntu 同样不可执行。
- 离线期 yq/gh/just 的 go/cargo 重装会撞快失败默认,属预期。

## 参见

- [docs/params.md](../../params.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: eslint kind=runtime path=/usr/local/bin/eslint note=npm 全局件
- rctl: prettier kind=runtime path=/usr/local/bin/prettier note=npm 全局件
- rctl: typescript kind=runtime path=/usr/local/bin/tsc note=ts 编译器(npm 全局)
- rctl: tsserver kind=runtime path=/usr/local/bin/tsserver note=typescript LSP 服务面
- rctl: ruff kind=runtime path=/usr/local/bin/ruff env=编程环境 note=Python linter(uv-tool)

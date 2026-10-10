# 基础命令行工具(cli 组)

> git/jq/yq/shellcheck/gh/just/tmux/rclone/aria2/fzf/bat/htop/ncdu/moreutils/vim 一批 ｜ 状态:已装 ｜ 组:`install-tools.sh cli`

- **版本钉**:apt 批 noble 随源(13 包,版本随源冻结);yq/gh `go install …@latest` 未钉(`have && skip`,首次装到的那份);just 优先 apt 随批,`have just` 不成立时 `cargo install just --locked` 兜底(同未钉)
- **来源与安装**:脚本面 `install_cli`(`scripts/install-tools.sh`):apt 批带 `|| true`(批内单包失败不中断后续 go/cargo 段,复跑幂等补齐);yq `go install github.com/mikefarah/yq/v4@latest`([mikefarah/yq](https://github.com/mikefarah/yq)),gh `go install github.com/cli/cli/v2/cmd/gh@latest`([cli/cli](https://github.com/cli/cli);官方 apt 源国内无镜像,源码编译,GOPROXY=goproxy.cn);apt 镜像钉阿里云,源口径见 [docs/params.md](../../params.md)
- **落点与配置(批量机制)**:apt 批落 `/usr/bin`(noble 的 bat 包二进制名是 `batcat`,链 `/usr/local/bin/bat` 回通用名);go 段显式 `export GOPATH=/opt/go`,产物落 `/opt/go/bin` 再链 `/usr/local/bin/{yq,gh}`;just 兜底与 astgrep 同式(export `RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo` + PATH),产物 `/opt/cargo/bin/just` 链 `/usr/local/bin/just`。脚本不写任何配置文件,无缓存固化。

| 成员 | 入口 | 来源 | 落点 |
|---|---|---|---|
| git | `git` | apt noble | `/usr/bin` |
| jq | `jq` | apt noble | `/usr/bin` |
| shellcheck | `shellcheck` | apt noble | `/usr/bin` |
| just | `just` | apt noble(无包时 cargo `--locked` 兜底) | `/usr/bin`(兜底时 `/opt/cargo/bin` 链 `/usr/local/bin`) |
| tmux | `tmux` | apt noble | `/usr/bin` |
| rclone | `rclone` | apt noble | `/usr/bin` |
| aria2 | `aria2c` | apt noble | `/usr/bin` |
| fzf | `fzf` | apt noble | `/usr/bin` |
| bat | `bat`(包内二进制 `batcat`) | apt noble | `/usr/bin/batcat` + `/usr/local/bin/bat` 软链 |
| htop | `htop` | apt noble | `/usr/bin` |
| ncdu | `ncdu` | apt noble | `/usr/bin` |
| moreutils | `sponge`/`parallel` 等 | apt noble | `/usr/bin` |
| vim | `vim` | apt noble | `/usr/bin` |
| yq | `yq` | `go install …/yq/v4@latest`(goproxy.cn) | `/opt/go/bin` 链 `/usr/local/bin` |
| gh | `gh` | `go install …/cli/v2/cmd/gh@latest`(goproxy.cn) | `/opt/go/bin` 链 `/usr/local/bin` |

- **离线行为**:☐ [推断:]本地件(jq/yq/shellcheck/just/tmux/fzf/bat/htop/ncdu/moreutils/vim、git 本地操作)不触网;联网面(rclone/aria2c 下载、gh API、git remote)断网失败属设计边界,见 [docs/offline.md](../../offline.md) 边界节;断网冒烟 78/0 覆盖工具面但逐件名单未留档,本组未单独实证。验证:`ip link set eth0 down` 后 `yq --version >/dev/null && just --version >/dev/null && gh --version >/dev/null` 退 0
- **坑与留痕**:**go 产物必须 `GOPATH=/opt/go`**——不设则 `go install` 落 `/root/go`(0700),ubuntu 不可执行(脚本注释实证;旧镜像曾未设 GOPATH 且只链 yq,gh 对 ubuntu 不可执行,留痕 [known-issues](../../known-issues.md),现脚本 yq/gh 都设都链);**just 兜底必须显式指 /opt/cargo**(与 [astgrep](../tools-astgrep/astgrep.md) 同式 export RUSTUP_HOME/CARGO_HOME + PATH),否则 cargo 产物落 `/root/.cargo`(0700),ubuntu 同样不可执行;离线期 yq/gh/just 的 go/cargo 重装会撞快失败默认,属预期([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md))

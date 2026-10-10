# herdr

> 终端 workspace 管理器(tmux 之外的 agent 编排面) ｜ 状态:已装 ｜ 组:`install-tools.sh herdr`

- **版本钉**:`HERDR_VERSION=0.9.3`(lib/common.sh,herdr.dev stable 频道);`HERDR_SHA256=18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7` 钉 linux-x86_64 资产,`sha256sum -c` 校验不过即 `exit 1`
- **来源与安装**:官方安装通道是 herdr.dev/install.sh(解析 latest.json 下 GitHub release);脚本 `install_herdr` 等价实现并钉版——`curl -fSL "${GITHUB_MIRROR}https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-${harch}"`([herdrdev/herdr](https://github.com/herdrdev/herdr) release 直下,无国内镜像,走 GITHUB_MIRROR 前置代理,口径见 [docs/params.md](../../params.md))
- **落点**:`install -m755 /tmp/herdr /usr/local/bin/herdr` 全局可用,不走官方安装器的 `~/.local/bin`
- **配置与缓存**:无(脚本不写配置)
- **离线行为**:☐ [推断:]本体是本地终端编排器,起窗格不触网;其编排的智能体后端连通性属各 agent 自身,断网失败不是缺陷(边界见 [docs/offline.md](../../offline.md))。验证:`ip link set eth0 down` 后 `herdr --version` 退 0
- **坑与留痕**:sha256 只钉了 x86_64 资产,arm64(aarch64)跳过校验,换版本时要重算补钉(脚本注释,同类缺口登记见 [known-issues](../../known-issues.md));架构映射只认 amd64→x86_64 / arm64→aarch64,其余架构 `return 1`;幂等判据是 `have herdr`,升级要先删 `/usr/local/bin/herdr` 再重跑组才生效

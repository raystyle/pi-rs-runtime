# Bun 运行时

> bun/bunx 一体化 JS 运行时与包管理器 ｜ 状态:已装 ｜ 组:`install-runtimes.sh bun`

- **版本钉**:npm 全局未钉(`npm install -g bun`,registry=npmmirror 淘宝镜像)
- **来源与安装**:[bun.sh](https://bun.sh) 经 npmmirror 的 npm 全局安装(装在 /opt/node prefix 下,依赖 [node 册](node.md) 先就位);`scripts/install-runtimes.sh` `install_bun`
- **落点**:npm shim `/opt/node/bin/{bun,bunx}` → 软链 `/usr/local/bin/{bun,bunx}`(非交互 shell 的 PATH 不含 /opt/node/bin,固定链接兜底)
- **配置与缓存**:bun 不读 npmrc,要 bunfig:root 与 ubuntu 各写 `~/.bunfig.toml` 的 `[install] registry = "https://registry.npmmirror.com"`(官方推荐写法);无固化缓存
- **离线行为**:☐ 断网拉新件 [推断:bun 不吃 npmrc 离线双保险,离线拉新按自身重试节奏走;裁定不钉默认离线(量级小),见 [ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md) 与 [offline.md](../../offline.md) §4——无断网专项实证记录]。验证(待做):`ip link set eth0 down` 后 `mkdir -p /tmp/bt && cd /tmp/bt && bun add lodash` 观察失败节奏
- **坑与留痕**:早退判据 `have bun` 在 bunfig 写入**之前**——增量重跑(bun 已在)刷不上 bunfig,与 AGENTS.md「配置写入一律放早退之前」的判据相悖,留痕待修;版本未钉且重跑不升级(要升级先 `npm uninstall -g bun` 再重跑,或手工 `npm install -g bun@latest`);bunfig 只写 registry 不写离线键(ADR-0004 裁定:bun/corepack 生态不钉默认离线)

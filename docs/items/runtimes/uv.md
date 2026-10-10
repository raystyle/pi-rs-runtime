# uv

> 极速 Python 包/工具管理器,本镜像 Python 生态的装件主通道(uv venv / uv pip / uv tool) ｜ 状态:已装 ｜ 组:`install-runtimes.sh uv`

- **版本钉**:官方独立安装器最新(`astral.sh/uv/install.sh`,未钉);离线行为实证基于 uv 0.12.15
- **来源与安装**:[astral-sh/uv](https://github.com/astral-sh/uv)([文档](https://docs.astral.sh/uv/))官方独立安装器 `curl -LsSf https://astral.sh/uv/install.sh | sh`,不经系统 pip(用户裁定不碰系统 python3,见 [ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md));`scripts/install-runtimes.sh` `install_uv()`
- **落点**:真身 `$HOME/.local/bin/uv`(构建期为 `/root/.local/bin/uv`),软链 `/usr/local/bin/uv`;uv tool 面:工具体 `/opt/uv-tools/<工具>`、入口 shim `/usr/local/bin`(`UV_TOOL_DIR`/`UV_TOOL_BIN_DIR` 由 python 组与 tools 各组 export)
- **配置与缓存**:`/etc/uv/uv.toml` 系统级默认面:`offline = true` + `[[index]] url = "$PIP_INDEX" default = true`(默认阿里云 pypi simple);`/etc/uv/uv-online.toml` 构建期在线面(同索引、无 offline 行),`lib/common.sh` 检测到它即 `export UV_CONFIG_FILE=/etc/uv/uv-online.toml` 整面替换;两份配置都写在 uv 幂等早退之前(增量重跑刷得上);uv 缓存 `/root/.cache/uv`、`/home/ubuntu/.cache/uv` 被 `clean-image.sh` 清掉,运行期无本地缓存兜底
- **离线行为**:✅ 断网拉新包约 8ms 报 "network was disabled"(纯离线轮五生态快失败实证,机制见 [offline.md](../../offline.md) §4);在线面只能 `UV_CONFIG_FILE=/etc/uv/uv-online.toml` 整面替换——实证 `UV_OFFLINE=0` 压不过配置文件的 `offline = true`。验证:`ip link set eth0 down` 后 `uv pip install --dry-run --system cowsay` 立即报 "network was disabled" 退非 0
- **坑与留痕**:uv 不合并配置——用户级 `~/.config/uv/uv.toml` 一旦存在,系统级 `/etc/uv/uv.toml` **整份被忽略**,离线默认随之失效(offline.md 留痕,新用户/工具写用户级配置前要意识这一点);uv 0.4.23 起 `UV_INDEX_URL` 废弃,索引只写配置文件;uv 无 `pip download` 子命令,wheelhouse 烘焙须先给 venv 装 pip(见 [python](python.md));uv tool 件的 venv 外链必须白名单化,全目录软链曾把依赖 CLI 链进 /usr/local/bin 盖掉 pd 组 Go httpx、并把系统 python 劫持成环([ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md));快失败默认化裁定见 [ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md)

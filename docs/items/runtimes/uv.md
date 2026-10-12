# uv

> 极速 Python 包/工具管理器,本镜像 Python 生态的装件主通道(uv venv / uv pip / uv tool) ｜ 状态:已装 ｜ 组:`install-runtimes.sh uv`

## 版本

- `UV_VERSION=0.13.0`(解析日 2026-10-10)。
- 安装器按 `astral.sh/uv/0.13.0/install.sh` 的版本路径直下。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。
- 离线行为的测量版本是 uv 0.12.15。

## 来源与安装

- 上游:[astral-sh/uv](https://github.com/astral-sh/uv)。文档在 <https://docs.astral.sh/uv/>。
- 官方独立安装器:`curl -LsSf https://astral.sh/uv/install.sh | sh`。
- 不经系统 pip。
- 脚本:`scripts/install-runtimes.sh` 的 `install_uv`。

## 文件

- 被包装的程序是 `$HOME/.local/bin/uv`。构建期为 `/root/.local/bin/uv`。
- `/usr/local/bin/uv` 是实体拷贝(`install -m755`),不是软链。
- `/root` 是 0700。软链若穿 `/root`,ubuntu 执行即 `Permission denied`。
- uv tool 的工具体在 `/opt/uv-tools/<工具>`,入口 shim 在 `/usr/local/bin`。
- `UV_TOOL_DIR` 与 `UV_TOOL_BIN_DIR` 由 python 组与 tools 各组导出。

## 配置

- `/etc/uv/uv.toml` 是系统级默认面:`offline = true`,以及 `[[index]] url = "$PIP_INDEX" default = true`。默认索引是阿里云 pypi simple。
- `/etc/uv/uv-online.toml` 是构建期在线面:同一索引,没有 `offline` 行。
- `lib/common.sh` 检测到在线面文件后,导出 `UV_CONFIG_FILE=/etc/uv/uv-online.toml`,整份替换。
- 两份配置都写在 uv 的幂等早退之前。增量重跑会刷新它们。
- `/root/.cache/uv` 与 `/home/ubuntu/.cache/uv` 由 `clean-image.sh` 清掉。运行期没有本地缓存兜底。

## 离线行为

- 支持:断网拉新包约 8ms 报 `network was disabled`。机制见 [offline.md](../../offline.md) 第 4 节。
- 在线面只能用 `UV_CONFIG_FILE=/etc/uv/uv-online.toml` 整份替换。
- `UV_OFFLINE=0` 压不过配置文件里的 `offline = true`。
- 验证:关闭 eth0 后,`uv pip install --dry-run --system cowsay` 立即报 `network was disabled`,退出码非 0。

## 限制

- uv 不合并配置。用户级 `~/.config/uv/uv.toml` 一旦存在,系统级 `/etc/uv/uv.toml` 整份被忽略,离线默认随之失效。
- 新用户或工具在写用户级配置之前,需要知道上一条。说明见 [offline.md](../../offline.md)。
- uv 0.4.23 起 `UV_INDEX_URL` 废弃。索引只写配置文件。
- uv 没有 `pip download` 子命令。烘焙 wheelhouse 必须先给 venv 装 pip。见 [python 册](python.md)。
- uv tool 的 venv 外链必须走白名单。
- 全目录软链会把依赖 CLI 链进 `/usr/local/bin`,盖掉 discovery 组的 Go httpx,并把系统 python 劫持成环。
- 快失败默认面见 [offline.md](../../offline.md) 第 4 节。

## 参见

- [offline.md](../../offline.md)
- [python 册](python.md)

# Python 3 运行时

> 系统 python3 基座(保持干净) + /etc/pip.conf 离线面 + /opt/analytics 分析 venv + ruff ｜ 状态:已装 ｜ 组:`install-runtimes.sh python` + `install-libcache.sh python`(wheelhouse 固化)

## 版本

- python3、python3-pip、python3-venv、python3-dev 为 noble 源冻结,即 apt 软件源锁定。见 [known-issues.md](../../known-issues.md)。
- `PYPI_PIN[polars]` = 2.0.0(解析日 2026-10-10)。
- `PYPI_PIN[pyarrow]` = 26.0.0(解析日 2026-10-10)。
- `PYPI_PIN[chdb]` = 4.4.0(解析日 2026-10-10)。
- `PYPI_PIN[ruff]` = 0.17.0(解析日 2026-10-10)。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。

## 来源与安装

- Ubuntu noble 源,镜像是阿里云,由 `image-defs/ubuntu.yaml` 写入。
- 安装命令:`apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev`。
- 脚本:`scripts/install-runtimes.sh` 的 `install_python`。
- 不碰系统 python3 的 site-packages。第三方包进 venv,或经 uv tool 安装。

## 文件

- `/usr/bin/python3` 与 `/usr/bin/pip3` 来自 apt。
- 分析 venv 在 `/opt/analytics`(`bin/python` 等)。
- ruff 的 shim 是 `/usr/local/bin/ruff`,本体在 `/opt/uv-tools/ruff`。
- pwntools 只走 apt 包 `python3-pwntools`(p0 批),落在 dist-packages。

## 配置

- `/etc/pip.conf` 有两段。
- `[global] index-url = $PIP_INDEX`。默认是阿里云 pypi simple。不加 `extra-index-url`,以防依赖混淆。
- `[install]` 写入 `no-index = true` 与 `find-links = /opt/wheelhouse`。
- 运行期 `pip install` 默认只走 wheelhouse,未命中则立即失败。
- `pip download` 不受 `[install]` 节影响。wheelhouse 的烘焙不被这条离线面拦住。
- 构建脚本经 `lib/common.sh` 导出 `PIP_NO_INDEX=false`,拿回在线面。环境变量恒优先于配置文件。
- `/opt/wheelhouse` 由 `install-libcache.sh` 的 python 组烘焙:先给 re-venv 装 pip,再 `pip download`。
- 清单是下面 19 个逆向库及其依赖。
- 分析 venv 由 `uv venv /opt/analytics` 创建,再 `uv pip install polars pyarrow chdb`。
- duckdb 组随后以 `-U` 把 duckdb 装进同一 venv。见 `install-runtimes.sh` 的 `install_duckdb`。

| 包 |
| --- |
| pycryptodome |
| cryptography |
| gmpy2 |
| sympy |
| z3-solver |
| construct |
| pefile |
| pyelftools |
| dnfile |
| pypykatz |
| malduck |
| volatility3 |
| r2pipe |
| httpx |
| beautifulsoup4 |
| lxml |
| pyjwt |
| dpkt |
| xortool |

## 离线行为

- 支持:wheelhouse 内的包断网 `pip install` 免旗标直装。机制见 [offline.md](../../offline.md) 第 4 节。
- 支持:轮子外的包立即报 `No matching distribution`。
- 在线拉新件使用 `PIP_NO_INDEX=false pip install <包>`。
- 验证:关闭 eth0 后,`pip install pefile` 成功。pefile 在 wheelhouse 烘焙清单内。
- 验证:关闭 eth0 后,`pip install <未烘焙包>` 立即报 `No matching distribution`。
- 未验证:分析 venv 的断网 import。venv 是本地路径,import 不访问网络。断网冒烟未单独覆盖。

## 限制

- pwntools 若走 pip,会盖住 apt 的 dist-packages,造成双版本。规定只走 apt。
- ruff 用 `uv tool install` 隔离安装。
- `UV_TOOL_BIN_DIR=/usr/local/bin`,`UV_TOOL_DIR=/opt/uv-tools`。指到 `/opt` 后 ubuntu 可以执行。
- uv 自身的离线默认与用户级配置见 [uv 册](uv.md)。
- 快失败默认面见 [offline.md](../../offline.md) 第 4 节。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [uv 册](uv.md)

## rctl 收录行

- rctl: analytics-venv kind=runtime path=/opt/analytics env=数据分析 note=数据分析 venv(polars/pyarrow/chdb 物化)
- rctl: 2to3 kind=runtime path=/usr/local/bin/2to3
- rctl: idle kind=runtime path=/usr/local/bin/idle
- rctl: pydoc kind=runtime path=/usr/local/bin/pydoc
- rctl: smtpd.py kind=runtime path=/usr/local/bin/smtpd.py note=stdlib 邮件服务脚本(uv-tools 副件)

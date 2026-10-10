# DuckDB

> 本地列存分析引擎:python 绑定进分析 venv,CLI 单文件直查 parquet/csv ｜ 状态:已装 ｜ 组:`install-runtimes.sh duckdb`

- **版本钉**:pins.sh 钉版(解析日 2026-10-10),升级跑 scripts/resolve-pins.sh:python 绑定 `PYPI_PIN[duckdb]`=1.5.6(`uv pip install -U duckdb==<钉>`);CLI 标量 `DUCKDB_VERSION`=v1.5.6(空钉回退 api.github.com latest tag;zip 无校验和)
- **来源与安装**:[duckdb/duckdb](https://github.com/duckdb/duckdb);python 绑定经 uv 装进 `$VENV_ANALYTICS`(默认 `/opt/analytics`,索引进 `/etc/uv/uv.toml`,默认阿里云 pypi);CLI zip `duckdb_cli-linux-{amd64|aarch64}.zip` 从 github.com 直连下载(不走 GITHUB_MIRROR),unzip 后 `install -m755`(`scripts/install-runtimes.sh` `install_duckdb`)
- **落点**:`/usr/local/bin/duckdb`(CLI 真身,无 wrapper);python 绑定在 `/opt/analytics` venv 的 site-packages,经 `/opt/analytics/bin/python` 调用
- **配置与缓存**:无(不写配置、不固化缓存;venv 本体由 python 组建,见 `install-runtimes.sh python`)
- **离线行为**:☐ [推断:]本地引擎不触网,CLI 直查文件与 venv import 均纯本地;断网冒烟未单独覆盖本件。验证:`ip link set eth0 down` 后 `duckdb -c "SELECT 42"` 与 `/opt/analytics/bin/python -c "import duckdb; print(duckdb.__version__)"`
- **坑与留痕**:空钉回退 api.github.com 取 latest 时,限流 403 会让 tag 取空,脚本 `|| true` 兜底下轮补(有钉后不走这路)——首轮可能只有 python 绑定没有 CLI 是钉版前实证(见 [日记 2026-10-08](../../diary/2026-10-08-build-baseline.md));幂等判据 `have duckdb` 只看 CLI,python 绑定每轮 `-U` 照跑(钉值精确,无害)

# DuckDB

> 本地列存分析引擎:python 绑定进分析 venv,CLI 单文件直查 parquet/csv ｜ 状态:已装 ｜ 组:`install-runtimes.sh duckdb`

## 版本

- `PYPI_PIN[duckdb]` = 1.5.6(解析日 2026-10-10)。安装命令是 `uv pip install -U duckdb==<版本>`。
- `DUCKDB_VERSION` = v1.5.6(解析日 2026-10-10)。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。
- CLI 未写锁定版本时回退到 api.github.com 的 latest tag。
- zip 无校验和。

## 来源与安装

- 上游:[duckdb/duckdb](https://github.com/duckdb/duckdb)。
- python 绑定经 uv 装进 `$VENV_ANALYTICS`(默认 `/opt/analytics`)。
- 索引进 `/etc/uv/uv.toml`,默认阿里云 pypi。
- CLI zip 是 `duckdb_cli-linux-{amd64|aarch64}.zip`,从 github.com 直连下载,不走 `GITHUB_MIRROR`。
- unzip 之后 `install -m755`。
- 脚本:`scripts/install-runtimes.sh` 的 `install_duckdb`。

## 文件

- `/usr/local/bin/duckdb` 是 CLI 被包装的程序,无 wrapper。
- python 绑定在 `/opt/analytics` venv 的 site-packages。
- 调用入口是 `/opt/analytics/bin/python`。

## 配置

- 不写配置,不固化缓存。
- venv 本体由 python 组建。见 `install-runtimes.sh` 的 python 组。

## 离线行为

- 未验证:CLI 直查文件与 venv import。本地引擎不访问网络。断网冒烟未单独覆盖本件。
- 判定:关闭 eth0 后执行 `duckdb -c "SELECT 42"`。
- 判定:关闭 eth0 后执行 `/opt/analytics/bin/python -c "import duckdb; print(duckdb.__version__)"`。

## 限制

- 未写锁定版本回退 api.github.com 取 latest 时,限流 403 会让 tag 取空。
- 脚本以 `|| true` 兜底。该次执行不安装 CLI。再次执行该组时安装。
- 已经有锁定版本之后,不走这条回退。
- 锁定版本之前,镜像上可能只有 python 绑定,没有 CLI。
- 幂等判据 `have duckdb` 只看 CLI。
- python 绑定每次都以 `-U` 重跑。锁定值精确,这一步无害。

## 参见

- [python 册](python.md)

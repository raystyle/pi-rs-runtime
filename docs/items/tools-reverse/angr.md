# angr

> Python 符号执行与二进制分析框架,平台无关 ｜ 状态:已装 ｜ 组:`install-tools.sh reverse`

## 版本

- `PYPI_PIN[angr]` = 10.0.3(解析日 2026-10-11)。
- 升级:执行 `scripts/resolve-pins.sh`,审阅差异,再执行 reverse 组。

## 来源与安装

- 安装命令是 `uv pip install angr==<版本>`。
- 装入独立 venv `/opt/angr-venv`。
- 不安装 extra `llm`。该 extra 会拉入 mcp。
- 不安装 extra `unicorn`。
- 不安装 angr-management GUI。
- 与 `/opt/re-venv` 分开,避免 z3 与 capstone 各有两套版本。
- 脚本:`install-tools.sh` 的 `install_reverse`。

## 文件

- `/opt/angr-venv` 是安装根。
- 入口是 `/opt/angr-venv/bin/python`。
- 使用方式是 `/opt/angr-venv/bin/python -c "import angr"`。
- 不链进 PATH。这是库,不是 CLI。
- 没有 wrapper。

## 配置

- 无配置文件。
- 依赖闭包随 venv 物化,包括 pyvex、pypcode、cle、archinfo。
- 离线以该 venv 为准。
- angr 不进入 wheelhouse。
- 因此离线解析不会漂到另一套 z3。

## 离线行为

- 支持 `import angr`。
- 分析是本地计算,不访问网络。
- 运行期的主要成本是内存。
- 没有官方的磁盘用量下限。

## 限制

- 没有与 2.x gem 同名的冲突。安装只走 PyPI。
- 不要把 angr `pip` 进 re-venv。两套版本会同时存在。
- angr-management 不安装。它是 GUI。
- qiling 做模拟执行,装在 re-venv。
- angr 做符号执行,与 qiling 是不同的件。

## 参见

- [reverse.md](reverse.md)
- [offline.md](../../offline.md)

## rctl 面,机器行

- rctl: angr-venv kind=runtime path=/opt/angr-venv note=angr 独立 venv(符号执行;python -c import angr 消费)

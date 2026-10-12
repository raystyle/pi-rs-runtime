# angr

> Python 符号执行与二进制分析框架(platform-independent)｜ 状态:已装 ｜ 组:`install-tools.sh re`

- **版本钉**:pins.sh `PYPI_PIN[angr]`(当前 10.0.3,2026-10-11 解析);升级跑 resolve-pins.sh 审 diff 重跑本组
- **来源与安装**:PyPI `uv pip install angr==<钉>` 进**独立 venv** `/opt/angr-venv`(;禁 extra `llm`(拖 mcp)/`unicorn`/angr-management GUI;与 re-venv 分离防 z3/capstone 双版本纠缠)
- **落点**:`/opt/angr-venv`(bin/python 即入口;`/opt/angr-venv/bin/python -c "import angr"` 消费);不链 PATH(库框架非 CLI);wrapper 无
- **配置与缓存**:无配置;依赖闭包(pyvex/pypcode/cle/archinfo 等)随 venv 物化,离线以 venv 为准(wheelhouse 不混,:防离线解析漂到另一套 z3)
- **离线行为**:过,断网 `import angr`;分析为本地计算零网络;运行期内存是主要成本(无磁盘下限官方规定)
- **限制**:2.x gem 同名问题无(纯 PyPI);不要 pip 进 re-venv(双版本);angr-management 不装(GUI 面);qiling(模拟执行)在 re-venv,与 angr(符号执行)互补不同件

- rctl: angr-venv kind=runtime path=/opt/angr-venv note=angr 独立 venv(符号执行;python -c import angr 消费)

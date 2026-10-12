# bloodhound-ce

> BloodHound CE 采集器(bloodhound.py 系,与 Legacy bloodhound-python 并存) ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `PYPI_PIN[bloodhound-ce]` = 1.9.1(解析日 2026-10-10)。
- tuna 镜像没有这个包。
- 安装使用 `--index-url https://pypi.org/simple`,不走默认索引批。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[dirkjanm/BloodHound.py](https://github.com/dirkjanm/BloodHound.py)。
- PyPI 包名是 `bloodhound-ce`。
- 脚本:`install-tools.sh` 的 `install_redteam`。
- 它在 AD 现役批的最后一件单独安装。
- 组册:[redteam.md](redteam.md)。

## 文件

- venv 在 `/opt/uv-tools/bloodhound-ce`。
- 入口是 `/usr/local/bin/bloodhound-ce-python`。
- uv tool 经 `UV_TOOL_BIN_DIR` 直接链接该入口。

## 配置

- 无。

## 离线行为

- 未验证。
- 这是纯 Python uv tool,没有自更新。
- 关闭 eth0 后,`bloodhound-ce-python -h` 退 0,入口可用。
- 采集需要目标域控制器的 LDAP 可达。
- 断网只能验证入口,不能完成采集。

## 限制

- venv 内带有 dirkjanm 的 impacket 分支脚本,包括 `secretsdump.py` 与 `GetADUsers.py`。
- 这些 `*.py` 经白名单外链到 `/usr/local/bin`。
- 白名单循环里 bloodhound-ce 排在最后,同名脚本以它为准。
- `secretsdump.py` 解析到 `/opt/uv-tools/bloodhound-ce/`。
- `TOOLS_ALL` 里 analysis 组的 fortra impacket uv tool 先安装。
- redteam 白名单的 `ln -sf` 覆盖同名链接。
- 同名优先规则见 [redteam.md](redteam.md)。
- Legacy `bloodhound-python` 使用 re-venv wrapper,并且无条件重写。
- bloodhound-ce 与 Legacy `bloodhound-python` 并存。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)

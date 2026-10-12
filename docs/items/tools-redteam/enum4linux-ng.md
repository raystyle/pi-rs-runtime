# enum4linux-ng

> SMB/AD 枚举(enum4linux 现代重写) ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `GIT_PIN[cddmp/enum4linux-ng]` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- 克隆失败时重试 2 次。
- 解析日 2026-10-10。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng)。
- 克隆到 `/opt/enum4linux-ng`。
- `requirements.txt` 经 `uv pip` 装入 `/opt/re-venv`(`RE_VENV`)。
- 组册:[redteam.md](redteam.md)。

## 文件

- 入口是 `/usr/local/bin/enum4linux-ng`。
- wrapper 执行 `exec /opt/re-venv/bin/python /opt/enum4linux-ng/enum4linux-ng.py "$@"`。
- 仓内脚本没有 console script。
- wrapper 必须调用 re-venv 的 python。
- 依赖装在 re-venv。
- 系统 python3 没有这些依赖。

## 配置

- 无。

## 离线行为

- 支持入口。
- 关闭 eth0 后,`enum4linux-ng -h` 退 0。
- 枚举动作需要目标可达。
- wrapper 层机制见 [offline.md](../../offline.md)。

## 限制

- 运行依赖 `nmblookup` 与 `net`,来自包 `samba-common-bin`。
- 运行依赖 `smbclient`。
- 运行依赖 `ldapsearch`,来自包 `ldap-utils`。
- `install_redteam` 组头用 `apt-get install -y --no-install-recommends` 安装上述包。
- 缺少这些命令时,枚举进行到中段才报错。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)

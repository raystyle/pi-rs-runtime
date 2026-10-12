# pwndbg

> GDB 调试增强插件,用于 pwn 与逆向 ｜ 状态:已装 ｜ 组:`install-tools.sh p0` 装本体,`install-tools.sh pentest` 接线

## 版本

- pins.sh 键:`GIT_PIN[pwndbg/pwndbg]`。
- 当前值:3c627ae656b0959eb9de566f7f4129134924922e(解析日 2026-10-10)。
- 安装形:`uv tool install`,源是 `git+<GITHUB_MIRROR>github.com/pwndbg/pwndbg@<sha>`。
- 升级:运行 `scripts/resolve-pins.sh`,再执行对应组。

## 来源与安装

- 上游:[pwndbg/pwndbg](https://github.com/pwndbg/pwndbg)。
- 本体由 `install-tools.sh` 的 p0 组安装。
- 系统 gdbinit 由 pentest 组写入。
- `UV_TOOL_BIN_DIR=/usr/local/bin`。
- `UV_TOOL_DIR=/opt/uv-tools`。
- shim 与工具目录对 ubuntu 可读。
- 配套调试器是 p0 apt 批的 gdb-multiarch。

## 文件

| 路径 | 内容 |
| --- | --- |
| /usr/local/bin/pwndbg | uv shim |
| /opt/uv-tools/pwndbg | 本体 venv,内含 gdbinit.py |

## 配置

- pentest 组写 `/etc/gdb/gdbinit`。
- 该文件包含 `source <gdbinit.py 路径>`。
- 该文件包含 `set auto-load safe-path /`。
- 该文件包含 `set history save on`。
- 该文件包含 `set pagination off`。
- 每次重跑用 `find /opt/uv-tools -name gdbinit.py -path '*pwndbg*'` 定位路径,再整份重写该文件。
- 写完后执行 `gdb --batch -ex quit 2>&1 | grep -qi pwndbg`。

## 离线行为

- 未验证。
- 插件 Python 与 gdbinit 都在本地路径。gdb 加载它们不访问网络。
- 关闭 eth0 后,`gdb --batch -ex quit 2>&1 | grep -i pwndbg` 见到 banner 为判定命令。

## 限制

- 不写系统 gdbinit 时,gdb 不加载 pwndbg,作为未增强的 gdb 运行。
- gdbinit.py 的路径写进 `/etc/gdb/gdbinit`。
- pwndbg 升级使 venv 路径变化后,需重跑 pentest 组才会重新接线。

## 参见

- [p0.md](p0.md)
- [offline.md](../../offline.md)

## rctl 面,机器行

- rctl: pwndbg-lldb kind=tool path=/usr/local/bin/pwndbg-lldb note=pwndbg 的 lldb 面

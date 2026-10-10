# pwndbg

> GDB 调试增强插件(pwn/逆向) ｜ 状态:已装(系统 gdbinit 接线 + 冒烟) ｜ 组:`install-tools.sh p0` 装本体、`install-tools.sh pentest` 接线

- **版本钉**:pins.sh 钉版——uv tool 从 git 源按 `git+<GITHUB_MIRROR>github.com/pwndbg/pwndbg@<sha>` 装,`GIT_PIN[pwndbg/pwndbg]`=3c627ae656b0959eb9de566f7f4129134924922e(解析日 2026-10-10),升级跑 scripts/resolve-pins.sh
- **来源与安装**:[pwndbg/pwndbg](https://github.com/pwndbg/pwndbg) git 源经 `uv tool install`;`UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools` 指到 /opt,shim 与工具体对 ubuntu 可读(评审 F5)
- **落点**:uv shim `/usr/local/bin/pwndbg`;本体 venv 在 `/opt/uv-tools/pwndbg`(内含 gdbinit.py);配套调试器是 p0 apt 批的 gdb-multiarch
- **配置与缓存**:pentest 组写系统级 `/etc/gdb/gdbinit`:`source <gdbinit.py 路径>` + `set auto-load safe-path /` + `set history save on` + `set pagination off`;路径每次重跑都 `find /opt/uv-tools -name gdbinit.py -path '*pwndbg*'` 实时定位再整份重写;写完即冒烟 `gdb --batch -ex quit 2>&1 | grep -qi pwndbg`
- **离线行为**:☐ [推断:插件 python 与 gdbinit 全本地,gdb 加载不触网];构建期接线冒烟已实证(上条),断网逐件冒烟未单列登记。验证:`ip link set eth0 down` 后 `gdb --batch -ex quit 2>&1 | grep -i pwndbg` 见 banner
- **坑与留痕**:不接系统 gdbinit 则 gdb 静默降级为裸 gdb(脚本留痕);gdbinit.py 路径固化进 /etc/gdb/gdbinit,pwndbg 升级换 venv 路径后需重跑 pentest 组重新接线

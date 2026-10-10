# bloodhound-ce

> BloodHound CE 采集器(bloodhound.py 系,与 Legacy bloodhound-python 并存)｜ 状态:已装 ｜ 组:`install-tools.sh red`

- **版本钉**:uv tool 未钉(构建日 PyPI 最新);tuna 镜像缺包(实证),显式 `--index-url https://pypi.org/simple` 装,不走默认索引批
- **来源与安装**:[dirkjanm/BloodHound.py](https://github.com/dirkjanm/BloodHound.py) 的 PyPI 包 `bloodhound-ce`;`install_red` AD 现役批殿后单装([red 组册](red.md))
- **落点**:venv `/opt/uv-tools/bloodhound-ce`;入口 `/usr/local/bin/bloodhound-ce-python`(uv tool 经 `UV_TOOL_BIN_DIR` 直链)
- **配置与缓存**:无
- **离线行为**:☐ [推断:]纯 Python uv tool,无自更新机制,断网可起 help 面;采集动作本身需目标 DC/LDAP 可达,断全网只能验证入口面。验证:`ip link set eth0 down` 后 `bloodhound-ce-python -h` 退 0
- **坑与留痕**:venv 内捆绑 dirkjanm 的 impacket 叉整套脚本(secretsdump.py/GetADUsers.py 等),经白名单 `*.py` 外链进 `/usr/local/bin`;白名单循环里 bloodhound-ce 殿后保持同名优先,`secretsdump.py` 解析到 `/opt/uv-tools/bloodhound-ce/`(组序 `TOOLS_ALL` 里 p0 组的 fortra impacket uv tool 先装,red 白名单 `ln -sf` 覆盖同名片;机制与裁定见 [ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md));与 Legacy `bloodhound-python`(re-venv wrapper,无条件重写)并存,维护者明示可共存

# impacket

> Windows 网络协议工具库与示例脚本,协议含 SMB、Kerberos、MSRPC ｜ 状态:已装 ｜ 组:`install-tools.sh analysis`

## 版本

- pins.sh 键:`PYPI_PIN[impacket]`。
- 当前值:0.13.1(解析日 2026-10-10)。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。
- 在线索引的切换见 [offline.md](../../offline.md) 第 4 节。

## 来源与安装

- 上游:[fortra/impacket](https://github.com/fortra/impacket)。安装面是 PyPI 包。
- 脚本:`install-tools.sh` 的 `install_analysis`。
- 命令:`uv tool install "impacket==<版本>"`。
- 导出 `UV_TOOL_BIN_DIR=/usr/local/bin`。
- 导出 `UV_TOOL_DIR=/opt/uv-tools`。
- 构建期 uv 配置是 `/etc/uv/uv-online.toml`,索引为阿里云。
- 该命令失败时,改用 tuna 索引同一锁定值:`--index-url https://pypi.tuna.tsinghua.edu.cn/simple`。
- 不使用 noble apt 的冻结包。
- 镜像里已有 `python3-impacket` 时,先执行 `apt-get remove -y`。
- 无 `have` 早退。每次重跑都执行安装尝试。
- 该安装尝试的输出不保留。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/uv-tools/impacket | uv tool 的 venv |
| /usr/local/bin/*.py | uv 写出的示例脚本 shim,含 secretsdump.py |
| /opt/re-venv | 另一份 impacket,作库。redteam 组为 krbrelayx 装入 |

## 配置

- 无工具自身的配置文件。
- `/etc/uv/uv.toml` 在运行期设 `offline=true`。
- 该设置只约束 uv 的包管理动作。
- 已安装的入口不受该设置影响。

## 离线行为

- 支持本地启动入口。
- 关闭 eth0 后,`secretsdump.py -h` 退出码 0。
- 关闭 eth0 后,`describeTicket.py -h` 退出码 0。
- 关闭 eth0 后,`Get-GPPPassword.py -h` 退出码 0。
- 关闭 eth0 后,`wmipersist.py -h` 退出码 0。
- 对目标主机的动作需要到目标的网络。
- 外网断开且内网可达时,对目标的动作仍可用。
- eth0 关闭后,只剩本地处理。

## 限制

- redteam 组白名单会把同名 `*.py` 入口链到 bloodhound-ce venv 里的 dirkjanm impacket 叉。
- bloodhound-ce 在白名单循环中殿后,同名入口以它为准。
- 该规则写在脚本注释,并写在 [software-inventory.md](../../software-inventory.md)。
- PATH 上直接调用时,执行的是该叉。
- 要 fortra 上游原版时,调用 `/opt/uv-tools/impacket/bin/` 下的入口。
- 覆盖发生在 `install_redteam` 的链接循环。
- 无 `have` 早退。重跑是否跳过,取决于 uv 自己的行为。
- 未验证:uv 对已安装的 tool 是否报告 already installed。
- 重跑日志出现「impacket uv 安装失败」时,先核对该入口是否仍在。

## 参见

- [analysis.md](analysis.md)
- [offline.md](../../offline.md)
- [software-inventory.md](../../software-inventory.md)

## rctl 收录行
- rctl: secretsdump.py kind=tool path=/usr/local/bin/secretsdump.py
- rctl: GetNPUsers.py kind=tool path=/usr/local/bin/GetNPUsers.py
- rctl: GetUserSPNs.py kind=tool path=/usr/local/bin/GetUserSPNs.py
- rctl: getST.py kind=tool path=/usr/local/bin/getST.py
- rctl: getTGT.py kind=tool path=/usr/local/bin/getTGT.py
- rctl: psexec.py kind=tool path=/usr/local/bin/psexec.py
- rctl: wmiexec.py kind=tool path=/usr/local/bin/wmiexec.py
- rctl: smbexec.py kind=tool path=/usr/local/bin/smbexec.py
- rctl: atexec.py kind=tool path=/usr/local/bin/atexec.py
- rctl: dcomexec.py kind=tool path=/usr/local/bin/dcomexec.py
- rctl: ntlmrelayx.py kind=tool path=/usr/local/bin/ntlmrelayx.py
- rctl: smbclient.py kind=tool path=/usr/local/bin/smbclient.py
- rctl: ticketer.py kind=tool path=/usr/local/bin/ticketer.py
- rctl: rpcdump.py kind=tool path=/usr/local/bin/rpcdump.py
- rctl: lookupsid.py kind=tool path=/usr/local/bin/lookupsid.py
- rctl: netview.py kind=tool path=/usr/local/bin/netview.py
- rctl: mqtt_check.py kind=tool path=/usr/local/bin/mqtt_check.py
- rctl: mssqlclient.py kind=tool path=/usr/local/bin/mssqlclient.py
- rctl: raiseChild.py kind=tool path=/usr/local/bin/raiseChild.py
- rctl: goldenPac.py kind=tool path=/usr/local/bin/goldenPac.py
- rctl: karmaSMB.py kind=tool path=/usr/local/bin/karmaSMB.py
- rctl: reg.py kind=tool path=/usr/local/bin/reg.py
- rctl: samrdump.py kind=tool path=/usr/local/bin/samrdump.py
- rctl: services.py kind=tool path=/usr/local/bin/services.py
- rctl: CheckLDAPStatus.py kind=tool path=/usr/local/bin/CheckLDAPStatus.py
- rctl: DumpNTLMInfo.py kind=tool path=/usr/local/bin/DumpNTLMInfo.py
- rctl: Get-GPPPassword.py kind=tool path=/usr/local/bin/Get-GPPPassword.py
- rctl: GetADComputers.py kind=tool path=/usr/local/bin/GetADComputers.py
- rctl: GetADUsers.py kind=tool path=/usr/local/bin/GetADUsers.py
- rctl: GetLAPSPassword.py kind=tool path=/usr/local/bin/GetLAPSPassword.py
- rctl: addcomputer.py kind=tool path=/usr/local/bin/addcomputer.py
- rctl: attrib.py kind=tool path=/usr/local/bin/attrib.py
- rctl: badsuccessor.py kind=tool path=/usr/local/bin/badsuccessor.py
- rctl: changepasswd.py kind=tool path=/usr/local/bin/changepasswd.py
- rctl: checkMSSQLStatus.py kind=tool path=/usr/local/bin/checkMSSQLStatus.py
- rctl: dacledit.py kind=tool path=/usr/local/bin/dacledit.py
- rctl: describeTicket.py kind=tool path=/usr/local/bin/describeTicket.py
- rctl: dpapi.py kind=tool path=/usr/local/bin/dpapi.py
- rctl: dpapidump.py kind=tool path=/usr/local/bin/dpapidump.py
- rctl: esentutl.py kind=tool path=/usr/local/bin/esentutl.py
- rctl: exchanger.py kind=tool path=/usr/local/bin/exchanger.py
- rctl: filetime.py kind=tool path=/usr/local/bin/filetime.py
- rctl: findDelegation.py kind=tool path=/usr/local/bin/findDelegation.py
- rctl: getArch.py kind=tool path=/usr/local/bin/getArch.py
- rctl: getPac.py kind=tool path=/usr/local/bin/getPac.py
- rctl: keylistattack.py kind=tool path=/usr/local/bin/keylistattack.py
- rctl: kintercept.py kind=tool path=/usr/local/bin/kintercept.py
- rctl: machine_role.py kind=tool path=/usr/local/bin/machine_role.py
- rctl: mimikatz.py kind=tool path=/usr/local/bin/mimikatz.py
- rctl: mssqlinstance.py kind=tool path=/usr/local/bin/mssqlinstance.py
- rctl: net.py kind=tool path=/usr/local/bin/net.py
- rctl: ntfs-read.py kind=tool path=/usr/local/bin/ntfs-read.py
- rctl: owneredit.py kind=tool path=/usr/local/bin/owneredit.py
- rctl: ping.py kind=tool path=/usr/local/bin/ping.py
- rctl: ping6.py kind=tool path=/usr/local/bin/ping6.py
- rctl: rbcd.py kind=tool path=/usr/local/bin/rbcd.py
- rctl: rdp_check.py kind=tool path=/usr/local/bin/rdp_check.py
- rctl: registry-read.py kind=tool path=/usr/local/bin/registry-read.py
- rctl: regsecrets.py kind=tool path=/usr/local/bin/regsecrets.py
- rctl: rpcmap.py kind=tool path=/usr/local/bin/rpcmap.py
- rctl: sambaPipe.py kind=tool path=/usr/local/bin/sambaPipe.py
- rctl: samedit.py kind=tool path=/usr/local/bin/samedit.py
- rctl: smbserver.py kind=tool path=/usr/local/bin/smbserver.py
- rctl: sniff.py kind=tool path=/usr/local/bin/sniff.py
- rctl: sniffer.py kind=tool path=/usr/local/bin/sniffer.py
- rctl: split.py kind=tool path=/usr/local/bin/split.py
- rctl: ticketConverter.py kind=tool path=/usr/local/bin/ticketConverter.py
- rctl: tstool.py kind=tool path=/usr/local/bin/tstool.py
- rctl: wmipersist.py kind=tool path=/usr/local/bin/wmipersist.py
- rctl: wmiquery.py kind=tool path=/usr/local/bin/wmiquery.py

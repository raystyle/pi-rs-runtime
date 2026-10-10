# enum4linux-ng

> SMB/AD 枚举(enum4linux 现代重写)｜ 状态:已装 ｜ 组:`install-tools.sh red`

- **版本钉**:pins.sh 钉版:`GIT_PIN[cddmp/enum4linux-ng]` 钉 sha(clone_pin,幂等:HEAD==钉即跳过;失败重试 2 次;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh
- **来源与安装**:[cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng) 克隆钉 `/opt/enum4linux-ng`;`requirements.txt` 经 `uv pip` 进 `/opt/re-venv`(`RE_VENV`);[red 组册](red.md)
- **落点**:`/usr/local/bin/enum4linux-ng` wrapper:`exec /opt/re-venv/bin/python /opt/enum4linux-ng/enum4linux-ng.py "$@"`(仓内脚本无 console script,wrapper 必须指 re-venv 的 python——依赖在 re-venv,系统 python3 没装)
- **配置与缓存**:无
- **离线行为**:✅ 断网冒烟渗透工具面过(78/0,2026-10-10 离线轮;本件 wrapper 是该轮修复件之一,wrapper 层机制见 [offline.md](../../offline.md) §2)。验证:`ip link set eth0 down` 后 `enum4linux-ng -h` 退 0(枚举动作本身需目标可达)
- **坑与留痕**:运行依赖 `nmblookup`/`net`(samba-common-bin)、`smbclient`、`ldapsearch`(ldap-utils)——`install_red` 组头 `apt-get install -y --no-install-recommends` 补齐,缺了枚举中段才报错;克隆仓名曾写错(cddmp/enum4linux-ng,2026-10-08 fresh 验证修)

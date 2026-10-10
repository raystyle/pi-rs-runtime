# capa

> 恶意软件能力识别(静态特征 → 能力/ATT&CK 映射) ｜ 状态:已装(wrapper 接规则) ｜ 组:`install-tools.sh p0` 装本体与规则、`install-tools.sh pentest` 接线

- **版本钉**:`CAPA_VERSION=9.4.0`(脚本默认,env 可覆盖;脚本留痕「v9.5.0 上游不存在,latest=v9.4.0(已核)」);规则库 pins.sh `GIT_PIN[mandiant/capa-rules]` 钉 sha(805f9eaccfb6a4e1ddffc809d71d1e2b5ccc15e5,clone_pin 幂等:HEAD==钉即跳过;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh
- **来源与安装**:[mandiant/capa](https://github.com/mandiant/capa) releases → `capa-v9.4.0-linux.zip` 经 GITHUB_MIRROR 直下解到 `/opt/capa`,无校验和;规则库 [mandiant/capa-rules](https://github.com/mandiant/capa-rules) `--depth 1` 克隆到 `/opt/capa-rules`(单独克隆便于更新)
- **落点**:zip 解开在 `/opt/capa`;p0 组初装时 `find /opt/capa -name capa` 软链到 `/usr/local/bin/capa`,pentest 组离线固化段把真身挪为 `/usr/local/bin/capa.real`、删链写 wrapper:`exec /usr/local/bin/capa.real -r /opt/capa-rules "$@"`
- **配置与缓存**:规则库 `/opt/capa-rules`(构建日快照,刷新需回有网环境重跑 p0 组);不指定 `-r` 时 capa 会自下载规则到 `~/.local/share/capa`,离线报晦涩错(脚本留痕),wrapper 钉死 `-r` 后该路径不再触及
- **离线行为**:☐ [推断:规则与二进制全本地,wrapper 注入 `-r` 后不触网];逐件断网冒烟未单列登记(wrapper 层机制见 [offline.md](../../offline.md))。验证:`ip link set eth0 down` 后 `capa /bin/true` 正常跑完,不因规则缺失报下载错
- **坑与留痕**:wrapper 写法教训——直接 `printf >` 软链会穿透改写 /opt/capa 里的真身(fresh 实证递归 exec),必须先 `mv` 真身为 `capa.real` 文件、删链再写 wrapper(脚本留痕);行为修正落 wrapper 文件而非 alias,alias 在非交互 shell(incus exec)不生效([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md))

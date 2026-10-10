# impacket

> Windows 网络协议(SMB/Kerberos/MSRPC)工具库与整套示例脚本(secretsdump.py 等) ｜ 状态:已装 ｜ 组:`install-tools.sh p0`

- **版本钉**:uv tool 上游最新,未钉——无 `have` 早退,每次重跑都执行安装尝试(输出被吞),首次装到的是构建日上游版;升级需在线面 `UV_CONFIG_FILE=/etc/uv/uv-online.toml uv tool upgrade impacket`(机制见 [offline.md](../../offline.md) §4)
- **来源与安装**:[fortra/impacket](https://github.com/fortra/impacket) PyPI 包;`uv tool install impacket`(导出 `UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools`),失败退 tuna 索引 `--index-url https://pypi.tuna.tsinghua.edu.cn/simple`;构建期 uv 在线面是 /etc/uv/uv-online.toml(阿里云索引)。用户裁定不用 noble apt 冻结版(发行版冻结,红队实操要上游脚本):老镜像里有 python3-impacket 则先 `apt-get remove -y` 增量迁移卸掉([ADR-0006](../../adr/ADR-0006-user-rulings-log.md))
- **落点**:本体 venv /opt/uv-tools/impacket;整套 *.py 入口 shim(secretsdump.py 等)由 uv 落 /usr/local/bin。另:/opt/re-venv 里也装了一份 impacket 作库(red 组 krbrelayx 依赖批带入)
- **配置与缓存**:无自身配置;/etc/uv/uv.toml 运行期 `offline=true` 只约束 uv 包管理动作,不影响已装入口运行
- **离线行为**:☐ [推断:] 入口脚本本地可起、可解析本地捕获与票据文件;对目标的动作需到目标的网络——断外网但内网可达仍可用,eth0 全断只剩本地处理。建议验证:`ip link set eth0 down` 后 `secretsdump.py -h` 退 0
- **坑与留痕**:uv 隔离面与白名单外链裁定见 [ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md);secretsdump.py 等同名 *.py 入口会被 red 组白名单链接覆盖到 bloodhound-ce venv 内的 dirkjanm impacket 叉(bloodhound-ce 殿后保持其优先,脚本注释与 [software-inventory](../../software-inventory.md) 口径)——PATH 直调实际执行的是叉版,要 upstream 原版需显式调 /opt/uv-tools/impacket/bin/ 下入口 [实证:install_red 链接循环];无 `have` 早退,重跑幂等性依赖 uv 自身行为,未单独实证 [假设:uv 对已装 tool 可能报 already installed,重跑日志若见「impacket uv 安装失败」先核实在位状态];组册见 [p0.md](p0.md)

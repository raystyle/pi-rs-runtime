# rea:rea-agents

> agent 逆向工具面(morluto/rea:MCP server + CLI,Ghidra 无头 provider,封装 analyzeHeadless)｜ 状态:已装 ｜ 组:`install-tools.sh reversea`

- **版本钉**:pins.sh `NPM_PIN[rea-agents]`(当前 6.3.0);升级跑 `scripts/resolve-pins.sh` 审 diff 后重跑本组(组内按版本比对幂等跳装)
- **来源与安装**:npm 全局 `rea-agents@<钉>` 装进系统 node 的全局面 `/opt/node/lib/node_modules`(npmmirror 镜像);构建期 `NPM_CONFIG_OFFLINE=false` 显式拿回在线面(运行期 npm 默认离线见 [offline.md](../../offline.md) §4);Node 要 22.19+/24.11+(镜像默认 node 24.21 满足);装面 `scripts/install-tools.sh install_rea`
- **落点**:被包装的程序 `/opt/node/bin/rea` 与 `/opt/node/bin/rea-agents`;入口 `/usr/local/bin/rea`、`/usr/local/bin/rea-agents` 为 wrapper(export `GHIDRA_INSTALL_DIR` 与 `JAVA_HOME` 后 exec 被包装的程序;ghidra 版本目录组内动态取 `/opt/ghidra/ghidra_*_PUBLIC` 最新,JAVA_HOME 取 Ghidra `support/launch.properties` 的 `JAVA_HOME_OVERRIDE`(temurin 21),升级 ghidra 组后重跑本组即刷新);登录 shell 备份面 `/etc/profile.d/rea-ghidra.sh`。**env 固化必须走 wrapper**:非登录 shell(incus exec)不读 profile.d(限制,见 [known-issues](../../known-issues.md))
- **配置与缓存**:Ghidra provider 依赖镜像内 [ghidra](../tools-ghidra/ghidra.md)(12.1.3;rea 的 verified 版本是 12.1.4,12.1.x 收为 compatible,doctor 报「compatible 12.1.x」属预期不是失败);**rea 无配置文件,配置面全是进程环境**:`GHIDRA_INSTALL_DIR`(不设不自动发现)、`JAVA_HOME`(rea 直 exec `$JAVA_HOME/bin/java`,不读 Ghidra 的 launch.properties override)、`REA_GHIDRA_STARTUP_TIMEOUT_MS`(默认 330000)、`GHIDRA_HEADLESS_MAXMEM`(默认 2G,大二进制才调)、`REA_ANALYSIS_PROVIDER`(多 provider 竞争时显式定 `ghidra`;本镜像只配 Ghidra,auto 可用)、`REA_LOG_LEVEL`;每用户状态 `~/.rea/cache` 与 `~/.rea/state`
- **离线行为**:过,断网全链路(2026-10-11):eth0 down 后 `rea doctor` Ghidra provider healthy(20 项 ok)+ 带符号 ELF `rea decompile <bin> main` 出伪代码(provider 12.1.3);边界:装/更新(`npm install -g`、`rea update`、`npx`)、`rea setup` 若涉及 Hopper 与 registry 解析、其它 provider(Hopper/JADX/固件/浏览器面)需在线;Ghidra provider 代码路径无 URL,断网分析不触网
## rctl 面,机器行:catalog 投影声明,audit 豁免依据

- rctl: rea-agents kind=tool path=/usr/local/bin/rea-agents note=rea 常驻面入口

- **限制**:剥符号件(如 /bin/true、/bin/cat)按名取函数报 `Unknown Ghidra procedure name`(在线离网同行为),要用地址或带符号件,这是 Ghidra 语义不是缺陷;调用恒带 `-readOnly -deleteProject`,临时工程用完即删,注解面(annotate_native_function)Linux 下可用、close 即丢,不写回原二进制;**取消/超时后的 Ghidra JVM 清理撞宿主信号策略**(,kill EACCES):进程可能残留到容器重启,「超时即收干净」不成立;MCP 注册是每客户端文件(无系统级开关),容器内 agent 的注册面:`[mcp_servers.rea]` command `/opt/node/bin/rea`、args `["mcp"]`、`startup_timeout_sec 30`(握手超时,不是分析超时),env 里带同套 `GHIDRA_INSTALL_DIR`/`JAVA_HOME`/`PATH`;rea 会清 `_JAVA_OPTIONS`/`JAVA_TOOL_OPTIONS`/`JDK_JAVA_OPTIONS`/`GHIDRA_JAVA_OPTIONS`,别指望这四个往 Ghidra 塞参数;`REA_GHIDRA_NATIVEAOT_JAR` 不设(设了只走 NativeAOT 扩展路径)


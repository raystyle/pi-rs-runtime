# rea:rea-agents

> agent 逆向工具面:morluto/rea,MCP server + CLI,Ghidra 无头 provider(封装 analyzeHeadless) ｜ 状态:已装 ｜ 组:`install-tools.sh rea`

## 版本

- `NPM_PIN[rea-agents]`(当前 6.3.0)。
- 升级:运行 `scripts/resolve-pins.sh` 审阅差异后重跑本组;组内按版本比对幂等跳装。

## 来源与安装

- npm 全局 `rea-agents@<版本>` 装进系统 node 全局面 /opt/node/lib/node_modules(npmmirror 镜像)。
- 构建期 `NPM_CONFIG_OFFLINE=false` 显式拿回在线面;运行期 npm 默认离线(见 [offline.md](../../offline.md) 第 4 节)。
- Node 要 22.19+ 或 24.11+;镜像默认 node 24.21 满足;脚本:`scripts/install-tools.sh` 的 `install_rea`。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/node/bin/rea、/opt/node/bin/rea-agents | 被包装的程序 |
| /usr/local/bin/rea、/usr/local/bin/rea-agents | wrapper:export GHIDRA_INSTALL_DIR 与 JAVA_HOME 后 exec |
| /etc/profile.d/rea-ghidra.sh | 登录 shell 备份面 |

- wrapper 内 ghidra 版本目录动态取 `/opt/ghidra/ghidra_*_PUBLIC` 最新;JAVA_HOME 取 Ghidra `support/launch.properties` 的 `JAVA_HOME_OVERRIDE`(temurin 21)。升级 ghidra 组后重跑本组即刷新。
- env 固化必须走 wrapper:非登录 shell(incus exec)不读 profile.d(见 [known-issues.md](../../known-issues.md))。

## 配置

- rea 无配置文件,配置面全是进程环境:

| 变量 | 说明 |
| --- | --- |
| GHIDRA_INSTALL_DIR | 不设不自动发现 |
| JAVA_HOME | rea 直 exec `$JAVA_HOME/bin/java`,不读 Ghidra 的 launch.properties override |
| REA_GHIDRA_STARTUP_TIMEOUT_MS | 默认 330000 |
| GHIDRA_HEADLESS_MAXMEM | 默认 2G;大二进制才调 |
| REA_ANALYSIS_PROVIDER | 多 provider 竞争时显式定 `ghidra`;本镜像只配 Ghidra,auto 可用 |
| REA_LOG_LEVEL | 日志级别 |

- 每用户状态:`~/.rea/cache` 与 `~/.rea/state`。
- Ghidra provider 依赖镜像内 [ghidra](../tools-ghidra/ghidra.md)(12.1.3)。rea 的 verified 版本是 12.1.4,12.1.x 收为 compatible;doctor 报「compatible 12.1.x」属预期,不是失败。

## 离线行为

- 支持:断网全链路。关闭 eth0 后 `rea doctor` Ghidra provider healthy(20 项 ok);带符号 ELF `rea decompile <bin> main` 出伪代码(provider 12.1.3)。
- 边界:装与更新(`npm install -g`、`rea update`、`npx`)、`rea setup` 涉及 Hopper 与 registry 解析时、其它 provider(Hopper/JADX/固件/浏览器面)需在线。Ghidra provider 代码路径无 URL,断网分析不触网。

## 限制

- 剥符号件(如 /bin/true、/bin/cat)按名取函数报 `Unknown Ghidra procedure name`(在线离网同行为);要用地址或带符号件,这是 Ghidra 语义,不是缺陷。
- 调用恒带 `-readOnly -deleteProject`:临时工程用完即删;注解面(annotate_native_function)Linux 下可用,close 即丢,不写回原二进制。
- 取消或超时后的 Ghidra JVM 清理撞宿主信号策略(kill EACCES):进程可能残留到容器重启;「超时即收干净」不成立。
- MCP 注册是每客户端文件,无系统级开关。容器内 agent 的注册面:`[mcp_servers.rea]`,command `/opt/node/bin/rea`,args `["mcp"]`,`startup_timeout_sec 30`(握手超时,不是分析超时),env 带同套 `GHIDRA_INSTALL_DIR`、`JAVA_HOME`、`PATH`。
- rea 会清 `_JAVA_OPTIONS`、`JAVA_TOOL_OPTIONS`、`JDK_JAVA_OPTIONS`、`GHIDRA_JAVA_OPTIONS`;不要指望这四个往 Ghidra 塞参数。
- `REA_GHIDRA_NATIVEAOT_JAR` 不设;设了只走 NativeAOT 扩展路径。

## 参见

- [ghidra 册](../tools-ghidra/ghidra.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: rea-agents kind=tool path=/usr/local/bin/rea-agents note=rea 常驻面入口

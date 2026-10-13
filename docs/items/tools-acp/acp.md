# acp:ACP 通道

> 实例标准 agent 接入通道:ACP v1 + stdio 适配器与监督进程 acpsup ｜ 状态:已装(agent 推理经网关;平台面 systemd 常驻,经 incus proxy 对外) ｜ 组:`install-tools.sh acp`

## 版本

- `CLAUDE_ACP_VERSION`(当前 0.89.1);`CODEX_ACP_VERSION`(当前 2.2.2)。
- 两值解析自 registry(解析日 2026-10-11);升级=对 registry 再解析改锁定值后重跑。
- 监督进程仓内 `scripts/acp/`(package.json 0.1.0);bun 编译期锁定 `BUN_VERSION`。

## 来源与安装

- 适配器:npm `@agentclientprotocol/claude-agent-acp@<版本>` 与 `@agentclientprotocol/codex-acp@<版本>`,经 npmmirror(npmjs 三级兜底);构建期在线面。
- 监督进程:acpsup 由 bun `--compile` 产 `/usr/local/bin/acpsup`。
- 脚本:`scripts/install-tools.sh` 的 `install_acp`;旧进程先经 `/shutdown` 自停,再自动跑 `acpsup --selftest claude`,随后写 systemd unit 并起服务。
- Go 承接工程 `scripts/acpsvc/`(承接方案在研究档案,需求单在 docs/req):M0 已建库,`install_acp` 末段跑 `go test ./...` 作组门禁;不产二进制不起第二单元,M2 切流前面板与 7663 全由 TS 服务。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/node/lib/node_modules/@agentclientprotocol/ | 适配器;入口从各包 bin 解析,对布局稳 |
| /usr/local/bin/acpsup | 监督进程 |
| /etc/systemd/system/acpsup.service | 常驻 unit;`Restart=on-failure`;实例重启自起 |
| /var/lib/acpsup/token | 平台 token;首启随机,权限 0600,打印一次,不进镜像 |
| 127.0.0.1:7663 | 平台 HTTP 面;仅回环,对外经 incus proxy 引出 |

## 配置

- 无配置文件。
- agent 环境:claude 适配器 `DISABLE_UPDATES=1`;codex 适配器 `CODEX_PATH=/usr/local/bin/codex`(指镜像内锁定版本,禁用适配器自带)加 `NO_BROWSER=1`;模型道沿 agents 批的网关接线(见 claude-code 与 codex 册),acpsup 不经手凭证。
- 对外引出(宿主执行):`incus config device add <实例> acp proxy listen=tcp:10.10.10.13:7663 connect=tcp:127.0.0.1:7663`;listen 绑宿主 tailnet 地址(tailscale0),只对 tailnet 开,LAN 面不开;全端点先过 Bearer(无 token 401),不裸奔;要放开别的面改 listen。
- token 自取:`incus exec <实例> -- cat /var/lib/acpsup/token`;调用示例:`curl -H "Authorization: Bearer <token>" http://<宿主>:7663/health`。
- 端点面:`GET /health`;`POST /session/new` {agent,cwd};`POST /session/prompt` {sessionId,text};`POST /session/cancel`;`GET /events?sessionId=`(SSE,先回放后订阅);`POST /permission` {requestId,optionId};`POST /shutdown`。

## 离线行为

- 支持:协议自检。关闭 eth0 后,`acpsup --selftest claude` 完成 initialize(protocolVersion=1)和 session/new,并返回会话标识。
- 平台 HTTP 只监听 127.0.0.1:7663;模型推理经网关,是运行期网络,不属于离线范围。

## 限制

- 信号策略:容器内 kill 族 EACCES;监督进程的停止走 `/shutdown` 自终止(干净退出,unit 不再拉起,重启实例才回);长时间命令由进程自己退出。
- 权限确认在 120 秒内没有应答则取消,不提供「始终允许」;平台请求没有 token 时响应 401;监督进程由 `/shutdown` 或 `--selftest` 结束。
- codex-acp 的 session/new 要凭证;网关接线后 session/new 与 prompt 全通(2026-10-13 实例内自检与宿主外部回环双过);无网关令牌时,回到只完成 initialize 的边界。
- proxy 设备属实例配置,不进镜像;新实例按配置节命令一条复现。

## 参见

- [claude-code.md](../tools-agents/claude-code.md)
- [codex.md](../tools-agents/codex.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: acpsup kind=service path=/usr/local/bin/acpsup note=ACP 监督进程(平台面 127.0.0.1:7663;systemd 常驻,经 incus proxy 对外)

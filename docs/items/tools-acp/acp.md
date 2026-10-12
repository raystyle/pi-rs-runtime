# acp:ACP 通道

> 实例标准 agent 接入通道:ACP v1 + stdio 适配器与监督进程 acpsup ｜ 状态:已装(协议面;agent 推理待凭证与网关) ｜ 组:`install-tools.sh acp`

## 版本

- `CLAUDE_ACP_VERSION`(当前 0.89.1);`CODEX_ACP_VERSION`(当前 2.2.2)。
- 两值解析自 registry(解析日 2026-10-11);升级=对 registry 再解析改锁定值后重跑。
- 监督进程仓内 `scripts/acp/`(package.json 0.1.0);bun 编译期锁定 `BUN_VERSION`。

## 来源与安装

- 适配器:npm `@agentclientprotocol/claude-agent-acp@<版本>` 与 `@agentclientprotocol/codex-acp@<版本>`,经 npmmirror(npmjs 三级兜底);构建期在线面。
- 监督进程:acpsup 由 bun `--compile` 产 `/usr/local/bin/acpsup`。
- 脚本:`scripts/install-tools.sh` 的 `install_acp`;尾段自动跑 `acpsup --selftest claude`。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/node/lib/node_modules/@agentclientprotocol/ | 适配器;入口从各包 bin 解析,对布局稳 |
| /usr/local/bin/acpsup | 监督进程 |
| /var/lib/acpsup/token | 平台 token;首启随机,权限 0600,打印一次,不进镜像 |
| 127.0.0.1:7663 | 平台 HTTP 面;引出照 6080 规定:incus proxy,不裸奔 |

## 配置

- 无配置文件。
- agent 环境:claude 适配器 `DISABLE_UPDATES=1`;codex 适配器 `CODEX_PATH=/usr/local/bin/codex`(指镜像内锁定版本,禁用适配器自带)加 `NO_BROWSER=1`。
- 凭证沿 agents 批;acpsup 不经手。

## 离线行为

- 支持:协议自检。关闭 eth0 后,`acpsup --selftest claude` 完成 initialize(protocolVersion=1)和 session/new,并返回会话标识。
- 平台 HTTP 只监听 127.0.0.1:7663;没有凭证时,提示在模型鉴权处失败。模型推理使用运行期网络,不属于离线范围。

## 限制

- codex-acp 在 session/new 时要求凭证;没有凭证时自检只完成 initialize。
- 容器内 terminal/kill 返回 EACCES;长时间命令由该进程自己退出,或由 `/shutdown` 结束监督进程。
- 权限确认在 120 秒内没有应答则取消,不提供「始终允许」;平台请求没有 token 时响应 401;监督进程由 `/shutdown` 或 `--selftest` 结束。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: acpsup kind=service path=/usr/local/bin/acpsup note=ACP 监督进程(平台面 127.0.0.1:7663)

# S-0002 实例标准 RPC 接口:ACP v1 定调与 agent 接入通道

> 状态:accepted(方向定稿;prt-06 复核后维持) ｜ 起草:2026-10-11 ｜ 信源:grok prt-05 回执;grok prt-06(MCP 翻转证伪复核) ｜ 后续:REQ-0002 立单实现监督进程与适配器;pi-rs Agent 侧待实现,约束见五节

## 一、结论

实例的「标准 RPC 接口接不同 agent」采用 **ACP(Agent Client Protocol)v1 + stdio**(agentclientprotocol.com,Zed 与 JetBrains 共治,稳定线 v1;v2 与 HTTP/WebSocket 传输均草案不进生产)。分层不混:ACP 是客户端到 agent(左栏 chat 线);MCP 是 agent 到工具;A2A 是 agent 到 agent(本形态不用);AG-UI 是 agent 到浏览器事件(平台前端层,可经社区桥接 ACP)。

## 二、实例侧架构:web 平台在另项目,本仓只做实例面

```text
web 平台(另项目) --https/自有口令--> 实例内监督进程(ACP Client,非常驻 root)
                                      |--stdio 子进程: claude-agent-acp(Claude Agent SDK)
                                      |--stdio 子进程: codex-acp(CODEX_PATH 指镜像内锁定版本 codex)
                                      +--后续: pi-rs 自实现 ACP Agent 侧
右栏 VNC:不变(127.0.0.1:6080 + 宿主 proxy 引出,独立会话,与左栏只共享实例不共享 sessionId)
```

- 监督进程在实例内:ACP 的 terminal/create、fs 写、request_permission 应答都在实例侧实现(agent 才真正吃到这台渗透实例);对 web 的那一跳照 6080 口径:只绑回环、incus proxy 引宿主回环、自有口令(ACP v1 不提供平台用户鉴权,默认拒绝而非全 allow_always)
- 切换 agent = 换/并存子进程(prompt 只发当前选中);同一 agent 多段对话用 session/new
- 取消走 session/cancel(协议层),不靠宿主信号(本机 kill EACCES 约束 prt-01,天然契合)
- rctl 定调不变:发现/工具面,不是通道;agent 在实例里执行 rctl 做资源发现(session/new 可带 MCP server,未来可选)

## 三、落地要点:REQ-0002 面

1. 适配器锁定版本进镜像:npm `@agentclientprotocol/claude-agent-acp`(2026-10-11 registry 0.89.1)、`@agentclientprotocol/codex-acp`(2.2.2);Codex 适配器设 `CODEX_PATH` 指镜像内 0.162.1(禁用适配器自带 codex);Claude 适配器经 Agent SDK,装前核对其构建是否即镜像 2.1.296
2. 监督进程:TypeScript + bun(rctl 同栈,零依赖面);常驻但可被宿主重启管理(信号策略下进程内自杀式重启走 supervisor 内部逻辑)
3. 鉴权两分:agent 登录沿 prt-04(网关道/env/挂载);平台用户鉴权是监督进程自己的口(默认拒绝、权限卡必须呈现给左栏)
4. 许可陷阱:禁把 request_permission 全自动 allow_always(等于把「谁能跑命令」交给任何连上的人)
5. 协议边界:v2 草案与 Streamable HTTP 不进生产;ACP JSON-RPC 不绑非回环;不自造私有 RPC

## 三点五、MCP 翻转方案的评估与否决:2026-10-11 prt-06

用户问「除 ACP 外更稳的方案」,候选「实例当 MCP Server + 平台网关驱动 agent」经 grok prt-06 证伪:比错了对象。ACP 选定路径是 v1 stdio(唯一稳定传输),草案 HTTP 不在路径上;MCP 翻转把对话腿变成私有网关(S-0002 已否的自造 RPC),丢掉权限卡与对话事件流(左栏没有标准可画),Codex 锁定版本默认 MCP 修订停在 2025-06-18(不是接上现行就稳),且 agent 已在实例内,发现走 rctl 子进程不需要新执行口。MCP 判定为工具协议不升格实例 RPC;若将来另立工具面,条件清单(prt-06 件 5)按三态执行:只读 rctl_* 可采纳,rctl_env/index 需改(白名单/写面分离),terminal_exec 与 VNC 输入不建议(令牌即 shell/两栏焊死)。**裁定:维持 ACP v1+stdio 通道。**

## 四、先例与信源摘

spec 与传输:agentclientprotocol.com/protocol/v1/*(stdio 是唯一稳定传输;initialize/session/prompt/update/request_permission/terminal 族);适配器:github.com/agentclientprotocol/claude-agent-acp 与 codex-acp(registry agent.json);组合先例:Zed external agents、JetBrains ACP、Jockey(多 agent 切换)、acp-to-agui(事件流桥)、acp_rpc_bridge(stdio 桥 HTTP,社区);分界:MCP 2025-11-25 spec、A2A 1.0.0、AG-UI docs。全量链接在 prt-05 回执(轮次档吸收后择要进仓)。

## 五、pi-rs 自实现 Agent 侧的三句补写

> 时点:2026-10-12 ｜ 信源:grok acp-01 回执(轮次档 /tmp/herdr-flywheel/2026-10-12-pi-acp/,研究正文 acp-01-research.md;发起方断言 5/5 件过,file:line 引证独立复核零失) ｜ 结论:可行;ACP 一轮 prompt 与 pi-rs 的 AgentSession.prompt 到 agent_settled 同构;MVP 落 rs-agent 内新 mode(--mode acp 加 acp-entry.ts,stdio JSON-RPC,直接调 AgentSession,复用 jsonl.ts 的 LF 帧读),与既有私有 JSONL rpc mode 并存、不替代、不桥接;chord 不承担 ACP 帧(产品 src 零运行时 import)

三句均为实现约束,不动通道裁定:

1. pi-rs Agent 侧是 stdio 子进程上的 ACP v1,入口与 claude/codex 适配器并列。仓内 `--mode rpc` 仍是嵌入协议,监督进程不连接它。
2. pi-rs 工具在子进程内执行。权限卡依赖它在执行 edit/write/execute 前调用 `session/request_permission`(选项不含默认选中的 allow_always;建议 read 默许、edit/write/execute 提问)。不要求这些工具改走 Client 的 fs/terminal。turn 取消用 `session/cancel`;关掉子进程只用于换 agent 或关机。
3. 现行监督进程一会话一子进程,且 `mcpServers` 为空。pi-rs MVP 按此互通。spec 要求 Agent 支持 stdio MCP;非空列表在 MCP client 落地前应失败,不静默丢弃。单进程多 session 不是现行监督进程的调用方式。

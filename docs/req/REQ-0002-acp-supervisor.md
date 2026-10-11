# REQ-0002 ACP 监督进程与适配器(实例标准 agent 接入通道)

> 状态:implemented ｜ 提出:2026-10-11 ｜ 设计研究:[S-0002](../research/S-0002-instance-rpc-acp.md)(prt-05 定调、prt-06 复核维持) ｜ 前置:REQ-0001(rctl)、agents 批

## 需求

R1 适配器钉版进镜像:`@agentclientprotocol/claude-agent-acp` 与 `@agentclientprotocol/codex-acp`(npmmirror,索引三级兜底同 agents 批);codex 适配器 `CODEX_PATH` 指镜像内钉版 codex(禁用自带)
R2 监督进程 acpsup:TypeScript + bun 零依赖(rctl 同栈),实例内常驻,当 ACP Client 经 stdio 拉起/切换适配器子进程
R3 ACP v1 面实现:initialize/session/new/session/prompt/session/cancel;session/update 与 request_permission 转发给平台;fs 回调在实例内真实现(绝对路径);terminal 族用 spawn 实现(信号策略下 kill 面记边界)
R4 平台面(对 web):仅回环 HTTP + Bearer token(首启随机生成 0600 落 /var/lib/acpsup/,打印一次不进镜像);默认拒绝;权限卡必须呈现(超时拒),禁全 allow_always
R5 生命周期适配宿主信号策略:不依赖信号;提供 token 保护的 /shutdown 与自终止的 --selftest 模式
R6 零网络:stdio 与回环 HTTP 之外不出网;agent 模型调用走 prt-04 凭证/网关道(使用期)
R7 rctl 关系:rctl 仍是 agent 用的发现 CLI,不做通道;acp 册进 catalog 可搜

## trace(实现回填)

- T1 REQ 立单(2026-10-11)
- T2 pins:CLAUDE_ACP_VERSION=0.89.1/CODEX_ACP_VERSION=2.2.2 + npmmirror resolver
- T3 scripts/acp/ 工程:acpclient(stdio JSON-RPC)+fsimpl(fs/terminal 真实现)+main(Bun.serve 回环 HTTP+SSE+permission 120s 默认 cancelled);bun test 4/4
- T4 install-tools.sh acp 组:适配器 npm 三级兜底安装+bun 版本闸+编译+/usr/local/bin/acpsup+组内自动 selftest
- T5 容器实证 2026-10-11:claude selftest PASS(initialize protocolVersion=1、真 sessionId、prompt 到鉴权层快失败属无凭证边界);codex 适配器 session/new 即要鉴权(实证边界入册);HTTP 面无 token 401/带 token 200 双 agent ready//shutdown 自停(端口关);断网(eth0 down)selftest 同过
- T6 册 tools-acp/acp.md+catalog 再生成+计数 78

## 验收判据

- selftest 出协议级证据(initialize 回带 protocolVersion=1);未带 token 的平台面请求 401;prompt 后有 session/update 事件流(无凭证时为鉴权类错误事件也算证据);断网下 acpsup 面可用

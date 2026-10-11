# acp(ACP 通道)

> 实例标准 agent 接入通道:ACP v1 + stdio 适配器与监督进程 acpsup(S-0002/REQ-0002)｜ 状态:已装(协议面实证;agent 推理待凭证/网关)｜ 组:`install-tools.sh acp`

- **版本钉**:pins.sh 标量 `CLAUDE_ACP_VERSION`(当前 0.89.1)与 `CODEX_ACP_VERSION`(当前 2.2.2),2026-10-11 registry 口径,升级=对 registry 再解析改钉重跑;监督进程仓内 `scripts/acp/`(package.json 0.1.0),bun 编译期钉 `BUN_VERSION`
- **来源与安装**:npm `@agentclientprotocol/claude-agent-acp@<钉>` 与 `@agentclientprotocol/codex-acp@<钉>` 经 npmmirror(npmjs 三级兜底);构建期在线面;acpsup 由 bun `--compile` 产 `/usr/local/bin/acpsup`;装面 `scripts/install-tools.sh install_acp`(尾段自动跑 `acpsup --selftest claude`)
- **落点**:适配器 `/opt/node/lib/node_modules/@agentclientprotocol/`(入口从各包 bin 解析,对布局稳);监督进程 `/usr/local/bin/acpsup`;token `/var/lib/acpsup/token`(首启随机,0600,打印一次,不进镜像);平台面 `127.0.0.1:7663`(引出照 6080 口径:incus proxy + 不裸奔)
- **配置与缓存**:无配置文件;agent 环境:claude 适配器 DISABLE_UPDATES=1,codex 适配器 `CODEX_PATH=/usr/local/bin/codex`(指镜像内钉版,禁用适配器自带)+ `NO_BROWSER=1`;凭证沿 agents 批(prt-04 网关道/env/挂载),acpsup 不经手
- **离线行为**:过,断网实证 selftest(initialize protocolVersion=1 + session/new 真 id,eth0 down 下同过);平台面 HTTP 仅回环零外网;prompt 到达模型鉴权层快失败(无凭证边界)属预期,推理走使用期网络不属离线承诺
## rctl 面(机器行:catalog 投影声明,audit 豁免依据)

- rctl: acpsup kind=service path=/usr/local/bin/acpsup note=ACP 监督进程(平台面 127.0.0.1:7663)

- **坑与留痕**:codex-acp 在 session/new 即要鉴权(比 claude 适配器早,无凭证时 selftest 只过 initialize,实证);宿主信号策略下 terminal/kill 如实报 EACCES 边界(known-issues),长命命令靠自退或 /shutdown 重启监督进程;权限卡默认 120 秒不应答即 cancelled(禁 allow_always 空窗);平台面未带 token 恒 401(默认拒绝);acpsup 生命周期不依赖信号(/shutdown 或 --selftest 自终止)

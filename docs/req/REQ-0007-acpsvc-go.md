# REQ-0007 acpsvc:独立 Go 工程承接 acpsup

> 状态:implemented(M0-M3 全落,2026-10-13) ｜ 提出:2026-10-13 ｜ 设计研究:[S-0003](../research/S-0003-acpsvc-go.md)(acpex-01,grok 出案,回执 49 过/1 撤/6 缺) ｜ 前置:REQ-0002(保持 implemented 至 M2 切流,平台口与 Client 由本单承接)

## 需求

R1 源码在 `scripts/acpsvc/`。模块路径 `github.com/raystyle/pi-rs-runtime/scripts/acpsvc`,`go 1.27.1`。布局 `cmd/acpsup` 与 `internal/{platform,backend,acpclient,fsimpl,session,logx}`;不设 `pkg/`。
R2 M0 只加目录与 `go test`。不改 7663 的监听进程,不产二进制,不起第二单元。
R3 M1 移植 stdio 换行分帧、fs 绝对路径、terminal spawn、权限 120 秒无应答即 cancelled、禁自动 `allow_always`、空 `mcpServers`。注册表三行:`claude`/`codex` 适配器 + `pi` 原生(`/usr/local/bin/pi-rs --mode acp`,不连 `--mode rpc`)。`acpsup-go --port 7664 --selftest claude` 打印 `protocolVersion=1` 与 sessionId;`pi` 未就绪不挡本步。
R4 M2 一次切流:正式路径仍是 `/usr/local/bin/acpsup`,端口仍是 7663,同一单元。切换前 7664 selftest 失败则不替换;切流后 HTTP 验收失败则恢复 `acpsup.tsbak`。
R5 七个旧端点(health/session/new/session/prompt/session/cancel/events/permission/shutdown)路径与成功体不变。无有效 Bearer 401;`caller` 调 `/shutdown` 与 `/keys` 403;旧 token 首启导入为 `legacy` admin。
R6 并发与超时按 S-0003 第 4 节:全局会话 8、每密钥 4、同会话第二 prompt 409、短请求桶 10 秒 30 次超限 429;不排队;`WriteTimeout` 为 0,截止按路由入 context;SSE 事件带单调整数 `id`,支持 `Last-Event-ID` 与 `after`,滑出环时从最旧重放并记 `replay=gap`;每 15 秒注释心跳。
R7 日志按 S-0003 第 3 节:slog JSON 单文件 `/var/log/acpsup/acpsup.log`(0600,目录 0750)+ lumberjack 轮转(50MB×5×14 天,压缩);访问/审计两类常开,调试默认关;恒不记 prompt 正文(只记 `prompt_bytes`)、Bearer、密钥原文;模型 token 只记在网关 overcast,本服务不记;canary 验收断言日志不含测试句与令牌。
R8 直接依赖仅 `gopkg.in/natefinch/lumberjack.v2` 与 `golang.org/x/time/rate`,先进 `resolve-pins.sh` go 清单,版本写入 `GO_PIN` 与 `go.sum`,缺锁定版本构建失败;服务自身版本是源码常量加 ldflags 注入,不进 `GO_PIN`;适配器版本仍走 npm 标量。
R9 M3 在 S-0003 第 1 节删除条件满足后删 `scripts/acp/`,与 M2 分提交。
R10 册面与 `resources.json` 在 M2 同步改写(acpsup 单行改 Go 来源,不增第二条服务行),catalog 由生成脚本再生。
R11 验收:双视角(root 与 ubuntu)、无 token 401、health 200 且 agents 含三项、canary 不进日志、eth0 down 后 claude selftest 仍过、`protocolVersion=1`;`pi` 在二进制或 `--mode acp` 缺失时允许 `ready:false`,对 `pi` 的 session/new 回 400。
R12 进程随镜像常驻:`install_acp` 写单元并 enable,只绑 `127.0.0.1:7663`;对外引出仍走宿主 incus proxy(tailnet 绑定,acp 册);不在宿主装第二份二进制;实现进现有实例,不新 launch,publish 等用户点头。

## trace:实现回填

- T1 REQ 立单(2026-10-13)
- T2 M0 建库(2026-10-13):`go.mod`(go 1.27.1,零第三方依赖)+ `cmd/acpsup`(参数面与版本,M0 不启服务)+ `internal/` 六包(backend 注册表与 pi 就绪探针、acpclient 分帧、session 事件环断点重放、platform 密钥模型、logx slog 面、fsimpl 绝对路径);`install_acp` 尾段增 Go 段跑 `go test ./...` 作组门禁;7663 仍由 TS acpsup 服务,面板零改动;实例内 go test 全绿
- T3 M1 移植并自证(2026-10-13):依赖锁定落(lumberjack v2.2.1、x/time v0.16.0 进 resolve-pins 与 go.mod/go.sum);六包全量移植——acpclient 子进程客户端(请求/通知/服务端请求分派/超时/有界 Close)、session 会话表+每密钥限+事件环断点重放+权限槽 120 秒、platform HTTP 全端点(多密钥双角色、legacy 导入、短请求桶 429、并发 prompt 409、SSE id+Last-Event-ID+15s 心跳、会话级 model 参数)、fsimpl terminal 族、logx lumberjack 文件面;实例内 go test 六包绿;install_acp 增 M1 段(acpsup-go 构建 + 7664 完即退 selftest 门禁,实跑 protocolVersion=1+真 sessionId+end_turn 过网关);7663 仍由 TS acpsup 服务,不产第二常驻单元
- T4 M2 切流(2026-10-13):七步切换序进 install_acp(7664 自检闸→/shutdown 自停→tsbak 只认首次→顶同名→inactive 等待闸→起服务→health 三后端验收,败态回滚);测试模式限流与每密钥上限随鉴权旁路(全局 8 保留);429 桶测试改确定性道;实切两次(幂等重跑过),外部验证:三后端 session/prompt 全绿(含 pi 首次对外)、四模型矩阵 7/7、SSE 每事件 id+15s 心跳零断、限额全局 8 精确触发;切流竞态(start 撞未回收单元致旧进程滞留)由 inactive 等待闸根治并实证
- T5 M3 下线 TS(2026-10-13):删除条件三项实证(Go 版本面在役、M2 验收残项全过——日志 canary 双阴性、eth0 down 下 selftest 与回环 health 过、root 与 ubuntu 双面、网络恢复复归;install_acp 无 TS 构建段);`scripts/acp/` 自仓与实例删,源码留 git 历史;镜像内 `acpsup.tsbak` 留作可执行回滚锚(publish 批裁定去留)
- T6 册面与契约同步(M2/M3 时点):acp 册、resources.json、catalog 再生,均落

## 验收判据

- M0:实例内 `go test ./...` 绿;TS 服务与七端点行为不变;不新增常驻进程
- M1:7664 selftest 出 `protocolVersion=1` 与 sessionId;无第二单元;`pi` 未就绪不失败
- M2:切流后 7663 无 token 401、带 legacy token health 200 三 agent 项;日志 canary 阴性;失败路径回滚 tsbak 可用
- M3:`/usr/local/bin/acpsup` 为 Go 二进制且 `install_acp` 不再 bun build;`scripts/acp/` 删除

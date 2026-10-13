# 2026-10-13 agent 网关烤进镜像与 ACP 对外过渡面

## 起点

- 用户指令三连:①把本机现役 claude code / codex 网关(overcast,`http://192.168.88.10:8317`)按「完整照本机」部署进镜像;②先让 ACP 接口对外可调用;③对外 ACP 接口的终态是独立 Golang 服务(本仓独立目录,随容器部署,claude/codex/pi 三后端,含日志设计),研究单 acpex-01 派邻居 grok(w7:p5);proxy 绑 tailnet 地址。
- 探索期事实:实例(10.200.242.148)到网关路由通(401,15ms);仓库 PUBLIC → 令牌绝不进 git;宿主 secretguard 拦命令行明文令牌 → 部署走「宿主临时文件 → incus file push → 实例内消费后删除」道;镜像内 codex 0.162.1 与本机同版;`~/.codex/models.json` 77KB 无机密字段,入库为 `scripts/data/codex-models.json`。

## 实现

- `install_agents` 增网关接线:新变量 `AGENT_GATEWAY_URL`(默认网关地址)/`AGENT_GATEWAY_TOKEN`(或 `AGENT_GATEWAY_TOKEN_PATH` 文件)/模型五变量(`AGENT_CC_HAIKU/SONNET/OPUS/SUBAGENT`、`AGENT_CX_MODEL`)。接线产物:claude `/etc/claude-code/managed-settings.json` env 12 键(BASE_URL、令牌、模型映射、`API_TIMEOUT_MS=3000000`、自动压缩参数);codex `/etc/codex/models.json` 共享模型目录 + config 三份(root/ubuntu 属主 1000:1000/skel,0600,provider `zai` 指 overcast,`experimental_bearer_token`,apikey+forced api 免登录,approval=never,danger-full-access,`[tools.web_search] enabled=false`)。缺令牌重跑时盘上已有网关配置保留不覆盖(防回退闸,md5 验证过)。
- web_search 坑:ubuntu 视角 `codex exec` 报 `tools[13] has unsupported Responses tool type "web_search"`(网关不支持该工具);本机配置本就有禁用段,初版烤库漏了,补齐后双视角过。root 视角当时偶然过,不追因,禁用后确定性强。
- `install_acp` 增常驻:`acpsup.service`(Restart=on-failure;`/shutdown` 干净退出不回拉,重启实例才回);重编译后旧进程经 token 保护的 `/shutdown` 自停再起(信号策略下不依赖 kill)。
- 对外引出:incus proxy 设备,listen 先 `0.0.0.0:7663`,用户裁定后收紧为 tailnet 地址 `10.10.10.13:7663`(LAN 面关)。

## 证据 — 实例 pi-rs-runtime-20261010-2210

- 网关接线:`install_agents` 尾行报接线;盘面 managed settings 12 键、三份 config 435 字节 0600、`/etc/codex/models.json` 77707 字节;令牌文件消费后消失;全仓 grep 令牌零命中。
- ACP 外部回环(经 tailnet 地址):无 token `/health` 401;带 token 200 双 agent ready;claude `session/new`+`prompt` end_turn(模型 zp-cc-glm53[1m],16461 token);codex `session/new` 直接发 sessionId(原「session/new 即要凭证」边界转绿)+ prompt end_turn。
- CLI 双视角:`claude -p` root/ubuntu 双「ok」;`codex exec --skip-git-repo-check` 双「ok」(web_search 禁用后)。
- acpsup systemd:active;`systemctl is-active` 过;重跑 agents 组不带令牌,配置 md5 不变。

## 文档同步

- 册:claude-code/codex(acp.md 互链新增)、acp(文件表加 unit 行、配置节加对外引出与端点面、限制节更新)。
- resources.json:claude-code/codex desc 改网关面,acpsup desc 加常驻与对外;catalog 再生成零漂移(497 件,对账 247 行)。
- params.md 新增 agent 网关参数节;install-surfaces/tools.md agents/acp 两行同步;PROGRESS 当前状态与方向档更新,待办挂 ACP Go 服务等研究回收。

## 方向 — 用户裁定

- 对外 ACP 接口终态 = 独立 Golang 服务:本仓独立目录持续维护、随容器部署(install 集成)、对外提供 claude code/codex/pi 三家 agent 调用(pi=pi-rs 原生 ACP Agent 侧,S-0002)。研究单 acpex-01(架构布局、协议分工、日志、多调用方、兼容、交付六问)已派 grok,简报与补充裁定在 /tmp/acpex-01/brief.md,产出 research.md + receipt.md。
- 本日交付的 TS acpsup + systemd + tailnet proxy 是过渡面,Go 服务落地后按研究方案的迁移序切换。

## 未尽

- publish 未做(等用户点头);proxy 设备属实例配置不进镜像,新实例按 acp 册配置节一条复现。
- acpex-01 研究回收后立 REQ 并吸收进研究档案(docs/research/)。

## M0 — REQ-0007 立单与 acpsvc 建库

- REQ-0007 立(draft;R1-R12 照 S-0003 收敛,trace T2 回填 M0)。
- `scripts/acpsvc/` 建库:go.mod(go 1.27.1,零第三方依赖)+ cmd/acpsup(参数面,M0 不启服务)+ internal 六包(backend 注册表与 pi 就绪探针、acpclient 分帧、session 事件环断点重放、platform 密钥模型、logx slog 面、fsimpl 绝对路径);gofmt 净;host go 1.27.0 低于 go.mod 要求,按仓纪律以实例(1.27.1)为验证面。
- install_acp 末段增 Go 段:PATH 补 /usr/local/go/bin,`go test ./...` 失败即组败;不产二进制不起第二单元。
- 次序坑修正:服务常驻后 selftest 与单元抢 7663 绑口(S-0003 §6 预判过);旧进程 /shutdown 前置到 selftest 之前,修后 selftest PASS。
- 实例验证:go test 六包全绿(cmd 无测试);selftest PASS(claude);服务 active;tailnet /health 200 双 agent ready,面板零改动。
- publish 按用户指示:全部调好后再议。

## 网关地址变量化与配置项清理

- 网关地址改 tailnet `10.10.10.9:8317`(用户指定),且脚本默认值移除:`AGENT_GATEWAY_URL` 空默认,接线必填,params 同步;实例已带变量重部署,claude/codex 配置两处 base_url 均为新址,root 面回环全绿,外部 ACP 回环 end_turn(16935 token)。
- `preferred_auth_method` 在 codex 0.162.1 已不被识别(启动警告),烤库 config 与册面移除;codex 非 tty 下会读 stdin,脚本外调用加 `</dev/null`。
- 用户告知网关将关鉴权(任意 token 放行);当日实测两址(10.10.10.9 / 192.168.88.10)两式(/v1/models、/v1/messages)假 token 均 401 Invalid API key——未生效或另口,待核;部署侧不受影响(真令牌在配,鉴权开着也通,关了也通)。
- 同日复核:网关鉴权已实关(10.10.10.9:8317 假 token 与无头均 200 出模型表;192.168.88.10:8317 LAN 面无头也 200)。服务端逐请求判定,容器侧零动作、请求级实时生效。注意:关鉴权后暴露面=谁能达该口,tailnet 面可控,LAN 面 192.168.88.10:8317 现对全网段开放,网关侧自行权衡(用户当日裁定:内网测试开放,接受该暴露面)。

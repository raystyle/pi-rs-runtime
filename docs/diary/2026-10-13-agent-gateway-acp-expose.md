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

## acpsup-fix-01 与四模型面

- 修复单(fleet seq 40/46 派回):①SSE 断连复现三组对齐(权限等待静默、模型思考静默 10.1 秒、回合尾 usage_update 后静默;断口干净无 chunk 终止符,curl exit 18 与 python ChunkedEncodingError 同形)→ 根因=Bun.serve 空闲超时默认 10 秒杀静默流,权限卡只是静默起点不是触发器;修复=/events 增 15 秒心跳注释(`: ping`)+ Bun.serve idleTimeout 255 + 断开清定时器与订阅;验证:静默 35 秒双心跳零断、工具回合全流完整。②文档事件形修正:线形权限卡是 `{kind:"permission",requestId,request}` 顶层、更新是 `{kind:"session/update",update}`,正确示例进 acp 册端点面。
- 四模型面:session/new 增可选 `model`;claude 注 `ANTHROPIC_MODEL`,codex 生成会话级 CODEX_HOME 改 model 行(catalog 绝对路径不受影响);实跑矩阵 7/7(claude:zp-cc-glm53[1m]/zp-cc-glm53fh[1m]/ds-cc-pro/ds-cc-flash;codex:zp-cx-glm53/ds-cx-pro/ds-cx-flash);models.json 增 ds-cx-pro/ds-cx-flash(128K 保守申报)。
- ACP 测试模式(用户裁定):unit 注 `ACPSUP_AUTH_OFF=1`,任意请求放行(TS 与 Go 面同构开关),回收删行重启即回默认拒绝。
- acpsvc M1 落地:六包全量移植,实例 go test 六包绿(修两处测试自坑:fake 不回 pingreq 应答、Close 无界等长命子进程);install_acp 增 M1 段,acpsup-go 7664 完即退自检过(protocolVersion=1+真 sessionId+end_turn);7663 仍 TS 服务。
- pi 后端:P1 九件单误派旧 pi-rs 仓后纠正,委托 pi-rs-core 工作台(acp-core-01,wC:p1 主格),回执道 /tmp/acp-core-01/。

## pi 后端收单与对接验证(acp-core-01)

- pi-rs-core 交付 11311e2(90368da 九件 + 5b63ec3 模型面 + 评审修复),已推 origin/main;回执 /tmp/acp-core-01/receipt.md:九件与六条硬约束全过,grok 一轮 F(许可桥双包,每 gated tool 发两张卡)修复后二轮 CONFIRM,pi 侧 ACP e2e 自打 9/9(真 --mode acp 子进程+网关模型)。
- 同批模型面(pi-rs-core 5b63ec3):pi 默认模型面 = overcast 网关四模型(默认 ds-cx-flash),凭证任意非空即过;走官方 API 设 PI_GATEWAY_BASE_URL=off。
- 总台对接验证:pi-rs-core 仓根 npm run build 产 bundle(72 件 9.2MB);临时道装进实例(/opt/pi-rs/bundle + /usr/local/bin/pi-rs wrapper 指 /opt/node/bin/node);`pi-rs --help` 列 acp;backend pi 行注 DEEPSEEK_API_KEY=overcast;`acpsup-go --port 7664 --selftest pi` 出 protocolVersion=1(222ms)+真 sessionId+prompt end_turn;Go 面起 7665 验 /health 三后端 ready 全 true、/shutdown 干净退出。
- 待 M2 批:pi-rs 安装件进镜像(pi-rs-core 发布锁定版本,替临时道)、七步切流后 pi 上 7663 公共面。

## M2 切流(Go 承接在役)

- install_acp 重写为七步切流序:Go 编临时件→7664 完即退自检闸(不过 7663 不动)→旧进程 /shutdown 自停→tsbak 只认首次(TS 本尊回滚锚,Go 自更新不覆盖)→顶同名→起服务→health 三后端验收,败态回滚 tsbak;TS 构建段(bun build)移除。
- 两坑收编:①44 桶测试 flake(靠跑速,慢机补币漏检)改确定性道(直耗桶再 HTTP 断言 429);②切流竞态——/shutdown 后旧单元未及回收时 systemctl start 是 no-op,旧进程滞留表观为「新二进制限流不生效」(7666/7667 同盘二进制对照实证 + 弹起即愈),加 inactive 等待闸(循环等单元退净再 start)根治。
- 测试模式语义补全:鉴权关时限流与每密钥上限一并旁路(全员共桶无意义),全局会话 8 保留;实证 #2-#8 过、#9 恰拒。
- 外部验收(经 tailnet):三后端 session/prompt 全绿(pi 首次对外)、claude 四别名/codex 三别名矩阵 7/7、SSE 每事件 id 行+15s 心跳+零断流、bounce 清表后限额精确。
- hx-web 接入单派 pi-server(fleet seq 55):三后端+模型别名+事件形+断点重连契约全文。

## M2 验收残项与 M3 下线 TS

- 残项全过:Go 版本面(acpsup --version 出 go 字样);日志 canary 双阴性(固定句与 Bearer 均不落 /var/log/acpsup/acpsup.log);keys.json 与日志 0600 root;ubuntu 视角容器内回环 health 200;eth0 down 下 Go selftest 过(initialize+session/new 本地,prompt 网络层失败=协议面证据)且回环 health 200,网络恢复 egress 复归。
- M3 删 `scripts/acp/`(仓与实例),源码留 git 历史;`acpsup.tsbak`(90MB TS 本尊)留镜像内作可执行回滚锚,publish 批裁定去留;REQ-0002 补 T7 承接行,REQ-0007 转 implemented。
- hx-web 接入:fleet(seq 55)之外按用户令 agents 直达 pi-web(pi-server w4:p1,cwd /home/ubuntu/repos/hx-web),已投递且目标开工处理。

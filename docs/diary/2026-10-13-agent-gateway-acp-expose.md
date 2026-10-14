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

## hx-web 切道对齐

- pi-web 回执:bin/acpsup-bridge.mjs(stdio ACP→REST+SSE 桥,after= 断点重连,权限卡请求化)三后端全切,本地承重面撤;pi 后端桥冒烟 end_turn。
- 我侧响应:会话上限环境变量化(ACPSUP_SESSION_MAX,默认 8,unit 测试期注 16)并换档清表(16 空位);警示桥侧勿碰 /shutdown(测试模式全员 admin,干净退出不回拉);ACSUP_KEY 命名无冲突确认;终验由 pi-web 跑。

## codex 间歇 web_search 移交与空闲回收

- pi-web 移交自查复现并定性:①裸 codex session/new 400 = 我方换档窗口碰撞(npm 重装适配器+弹服务,窗口内 spawn 短暂失败),事后实证净;②间歇 web_search 错:实例内 CLI 直连复现 50%(zp-cx-glm53 3/6 错、显式 -c tools.web_search.enabled=false 仍 3/6、ds-cx-pro 4/4 净)——web_search 非发自 codex,是网关 zp-cx 路由/池侧注入,带 request id 移交 pi-web;③500/悬空归其网关双实例期,已切单实例。
- 无 close 面压力实发(双方联测 16 槽打满):会话空闲自动回收上线(ACPSUP_SESSION_IDLE,默认 30 分钟,审计记 session/sweep)。

## hx-web 联测闭环与换档硬化

- pi-web 终验回执全绿:经网关→桥→acpsup 三后端只回复 ok 全 end_turn,别名抽查过,桥权限卡回环实测过(Write 工具卡→应答→完成);其两根因自解(cwd chdir 建 /tmp workspace;网关双实例清)。
- 联测暴露两处我侧硬化:①cwd 无效曾报成含混的「agent 未就绪」(chdir 细节),session/new 增 cwd 存在性闸,报「cwd 无效(需存在的绝对路径目录)」;②换档窗口曾现 status=1 监听失败→on-failure 重拉旧二进制滞留(journal 重拉计数 8,systemd 杀 cgroup EPERM 适配器残留),换档序增 systemctl reset-failed,净弹后 cwd 闸实证生效。

## 桥面对齐:cwd 语义与文件承接

- pi-web 报障驱动:zacp default_cwd 指网关宿主路径,session/new 400。裁定走 c 变体(契约定死容器路径)+ 后端补缺:cwd 白名单自动建(ACPSUP_CWD_ALLOW,默认 /tmp 与 /srv/work)+ GET /file 文件承接面(限会话 cwd 子树、4MiB 封顶、403 越树、逐出后 404,审计 file/read);共享卷方案留用户裁。
- 换档滞留旧身顽疾(systemd on-failure 自动重拉与二进制换装竞态,第三次现身)根治:unit 烤 ACPSUP_BUILD 时间戳、/health 回显、验收强校验指纹,不符自动弹换重试三次;本次实证 build 1791902900 在役。
- 协议三点回执:events id 会话内严格单调、after 排他续传(边界=环窗 2000);会话上限默认 8/ACPSUP_SESSION_MAX 可调(现役 16)、空闲回收默认 30 分钟;prompt 断开续跑是既定语义(S-0003),取消走显式 /session/cancel。

## pi-rs 正式安装件(P2 收口)

- pi-rs-core v0.3.0 发版(工件 44MB + sha256 边车 fc666060…);安装件按 GHIDRA 先例进 common.sh 标量(PI_RS_CORE_VERSION/PI_RS_SHA256;镜像道对该仓不可用——api 403、release 资产 404、git ls-remote 要凭证,直连均通——下载三链:镜像→直连→宿主 gh 预推 /root 落盘件)。
- install_pi_rs:sha256 锚、解包 /opt/pi-rs(dist/bundle 布局)、wrapper 指 /opt/node/bin/node、--help 含 acp 作闸;挂 agents 组尾部;踩坑:改了 install-tools.sh 忘推 common.sh,unbound variable 静默跳段(实跑尾输出定位)。
- 实例换装:临时道(宿主构建 bundle)被正式发行件替;ACP initialize 报 0.3.0、prompt end_turn;/health pi ready 探针直取新件。
- 文档面:新册 tools-agents/pi-rs.md(八签)、resources.json 增件、params 版本锁定行、surfaces agents 行、items README 与 software-inventory 计数同步(89 册 498 件)。

## 模型双面(2026-10-14 收尾)

- GET /models 与 POST /session/model 落地;机制实证:claude 运行时换模只认网关 /v1_models 在列名(ds-cc-* 网关未列,set 后静默回落默认——建会话 env 道则全通),codex set_config_option 吃目录全别名,pi 待 core 支持;据此收敛「建会话全清单、中会话换模子清单」双面,五态 e2e 全绿(claude 换 glm53fh 实跑对、claude 拒 ds-cc 带清单、codex 换 ds-cx-flash 实跑对、pi 400、建会话 ds-cc 实跑对)。
- 踩坑记档:python 补丁脚本断言失败时整段未落盘(后段看似已部署实为半件),以 /models 404 与 build 指纹定位补齐。

## 皓玄正式启用(2026-10-14,publish 链)

- 转正链序:正式鉴权部署(build 1791946548,无 token/乱 token 401、legacy 200;unit 环境 SESSION_MAX=16+KEY_SESSIONS=12,无 AUTH_OFF)→ smoke 双视角全绿(root 81/0、ubuntu 68/0;两坑:首跑漏了调用方预降 eth0 的头注约定致 4 败,且带网首跑真装了 sl 还留了 .deb 缓存可离线复装——purge+清缓存后 81/0)→ 凭证删(token+keys.json 不烤进镜像,新实例首启自生)→ clean-image → publish pi-rs-runtime-20261014-1102(快照道零预停;incus publish 压缩期冻结实例约 10 分钟为固有窗口,ACP 面该窗不可达,运营知悉);浮动别名已指 705990d1eaf6。发布后链:复启产新键(旧 legacy 内存键走 /shutdown,新 admin 首启打印一次)→桥 caller 键 k_4c194344(三态实证)→shares 取用行递 pi-web。
- 发布后:acpsup 复启(新键首启打印一次)→ 造桥 caller 键 → shares 取用行递 pi-web(明文不进消息)。
- 契约吸收:pi-rs-core 四条(fleet seq 96 闭环),②--approve 落 pi 行 argv(build 1791946173 实证)。
- 模型双面五态 e2e 全绿 + pi-web 终验 8/8(zacp UI 模型下拉真通)。

## pi 会话反推批(2026-10-14 下午)

- 分析 pi 全部会话(/root/.pi-rs/agent/sessions/ 按工作区分目录):皓玄 tour e2e 全通;真实痛点两条——rust-scripts 编译撞 cargo 离线默认(sparse index 缺新依赖硬失败,实例上 10-13 已热改 online 但仓模板仍是 offline,重建即回归),CVE 检索靠 sh_run 手扒五步(poc-search+exploitdb+nuclei+msf 逐个翻)。
- 三件落:cargo online 收敛进仓;poc-search --deep 五源一发(14750 实测:PoC 库 2 条+nuclei 模板命中,Exploit-DB/msf 对 14750 无直接引用属诚实输出——真实关联在 14882,与 pi 会话结论一致);searchsploit 进 PATH;caps 增 poc 检索行,rctl 语义双查询首中。
- 此批只动在役实例与仓,已发镜像未含,下批 publish 随收。

## session/resume 与换档凭证事故(2026-10-14 晚)

- 契约③接线:POST /session/resume {agent,sessionId,cwd,model?}——spawn+initialize+ACP 原生 resume;cwd fail-closed,未知 id 502,在表 409;E2E:claude 会话横跨监督进程重启续接,暗号问答回「樱桃原子」(记忆真续);pi 会话 -32601 属版本时序(resume 晚于 v0.3.0 发行),下版升 PI_RS_CORE_VERSION 即通,已更正告知 pi-rs-core。
- 换档凭证事故与根修:发布期删 token 文件后,换档脚本的停机/验收 bearer 全空 → 验收三连假红 → 回滚闸消费 tsbak(本实例 TS 回滚锚失,镜像内仍有)。恢复道:journal 抓 admin 键重建 token 文件。根修:EnsureKeys 首启同步把新 admin 键写进 token 文件(操作者 bearer 约定),新实例不再重蹈。
- resume 测试三态落地(fake 适配器增 resume 分支);全套件六包绿。

## 四模型换模放宽(2026-10-14 深夜,pi-web 用户反馈单)

- 界面反馈:下拉各应 4 可用。网关已列 ds-cc-pro/ds-cc-flash/zp-cx-glm5t/zp-cx-glm53fh(直打网关回 model 字段 deepseek-flash/deepseek-v4-pro,ds 档真 DeepSeek 池)。
- claude 堵点定性:适配器 set_config_option 的 value 永远解析成 SDK 选项表规范值(档位词),调用方原始串不透传;ds 别名 fuzzy 落 opus,经 managed env 映射回 zp-cc-glm53[1m](GLM),适配器源码与实跑双验;连 zp-cc 两别名的 set 也存在同类模糊解析,故 claude 换模整体改重建道。
- 重建道:重拉适配器(新 ANTHROPIC_MODEL;spawn env 与建会话道同机制,CLI 对别名仅 unrecognized_model 警告仍原样上送)→ 有轮次 session/resume 原号续接(transcript 在盘)→ 空会话 session/new 底层换 AcpID(对外号恒不变,-32002 除根)→ SwapAdapter 原子换进程,事件环/权限桥/会话号不动,请求参数与事件匹配走 AcpSessionID()。
- codex 第四别名 zp-cx-glm5t(共享目录在册),set_config_option 直通不变。
- 采集教训:SSE 回放读块大于在途字节时 python read 阻塞到超时并丢已收字节(65536 读块吞小回放,4096+心跳容忍 curl -N 才稳);诊断期加 update_mismatch/rebuild_swapped 审计行(留存,零 mismatch 全程)。
- E2E:claude 三别名(ds-cc-flash/zp-cc-glm53fh[1m]/ds-cc-pro)换模 200 rebuilt、暗号跨换模续答、模型标识随 env、同名 noop、非法别名 400 带清单;codex 空会话直通 zp-cx-glm5t + prompt end_turn;acpsup 0.2.0 上线,go.sum 入仓。

## browse 组合入(2026-10-14 深夜,用户放行)

- browse_rs v0.35.5(browse_rs GitHub Release):浏览器 CLI(自研 Chromium 内核 + 油猴标准 userscript 运行时 + Rune 编排,daemon 保会话,CDP 直达);pins 标量 BROWSE_VERSION/BROWSE_SHA256,resolve-pins 增 browse_latest(GitHub API)与 browse_sha(Release 边车)进 SCALARS 与 sha 二段解析。
- 下载三链:GITHUB_MIRROR 前置 → GitHub 直连 → 宿主预推 /root(README 记的 browse.ohmygh.com 镜像实测资产 404,镜像道缺席记档)。
- 引擎:browse chrome install 155.0.8059.39-gen8-r5(browse 托管面,~/.browse-rs/chrome,云端道 chrome.ohmygh.com 同源,BROWSE_CHROME_MIRROR 指路);与 chrome 组(/opt/clean-chrome 系统级单副本,ADR-0007)互不搬动;chrome 组 pins 已随 gen8-r5。
- 组进默认全量 TOOLS_ALL(chrome 组仍保留不默认);实例已部署:fetch 网关 /v1/models 200 via engine,/health 无凭证 401 诚实报 net::ERR_HTTP_RESPONSE_CODE_FAILURE。
- 两个 shell 坑:set -u 下 `local a=x b=$a` 前项不可见(declaration builtin 先展参后赋值,pi-rs 道分行写是对的,同款一行版实测必炸);grep 图样引号失衡 host bash -n 放行、实例 bash 炸在后续行(跨机语法门要两边 -n)。
- pins 全量刷新积压:--check 记录漂移面 UV 0.13.1/FRP v0.71.1/TRIVY v0.76.0/CLAUDE_CODE 2.1.299/CLAUDE_ACP 0.90.0,归专门升级批(版本纪律:跑解析器审 diff 再增量发布)。

## 镜像瘦身批(2026-10-14 深夜,用户裁定:保留运行时与编程环境)

- 盘面:实例根 60G;/opt 46G(go pkg/mod 10G、cargo 4.2G、rustup 3.4G、trivy-db 2.9G、SecLists 2.6G、nuget 2G、zig 双版…)。
- 裁定:保运行时与编程环境;删构建缓存;go 模块缓存删。clean-image.sh 扩:go pkg/mod+sumdb、cargo registry/src(保 cache+git+index,离线编译实测过)、zg target、vcpkg buildtrees、rust-script/ort 缓存。
- 险情记档:初稿误列 /opt/zig-cache——查 clean-image.sh 既有保护清单发现它是固化软链的 zig 离线包缓存(install-libcache zig 组建),纠正保留;清单纪律三面再立功。zig-0.15.2 非"旧版"而是 bof-launcher 锁定工具链,保留。
- 实释 18G(60G→42G):go 10G+cargo src 3.5G+zg target 1.4G+buildtrees 0.7G+各用户缓存 ~1.5G+/tmp 与 apt ~1G。
- 根修泄漏:acpsup codexHomeWithModel 落系统 /tmp 的会话级 CODEX_HOME(MkdirTemp 每会话 ~110M,近 8 个堆积 ~775M)永不回收;改归 DataDir/codex,Session.Home 字段 + Close 异步删 + New() 启动清旧账 + 表满 429 路补 Close;spawnModelEnv/codexHomeWithModel 转方法;六包+race 绿;实例验证 codex model 会话 200 落位。

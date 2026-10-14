# acp:ACP 通道

> 实例标准 agent 接入通道:ACP v1 + stdio 与平台 HTTP 监督进程 acpsup(Go 承接在役) ｜ 状态:已装(三后端 claude/codex/pi;推理经网关) ｜ 组:`install-tools.sh acp`

## 版本

- `CLAUDE_ACP_VERSION`(当前 0.89.1);`CODEX_ACP_VERSION`(当前 2.2.2)。
- 两值解析自 registry(解析日 2026-10-11);升级=对 registry 再解析改锁定值后重跑。
- 监督进程:`scripts/acpsvc/`(Go,版本是源码常量,ldflags 注入,当前 0.2.0;依赖仅 lumberjack/x-time/coder-websocket 三件);TS 工程已删(M3,2026-10-13),源码留 git 历史,可执行回滚锚是镜像内 `/usr/local/bin/acpsup.tsbak`。

## 来源与安装

- 适配器:npm `@agentclientprotocol/claude-agent-acp@<版本>` 与 `@agentclientprotocol/codex-acp@<版本>`,经 npmmirror(npmjs 三级兜底);构建期在线面。
- 监督进程:`scripts/acpsvc` 由 `install_acp` 编到 `/usr/local/bin/acpsup`(同名同 unit 同端口)。
- 脚本:`scripts/install-tools.sh` 的 `install_acp`,M2 切流序:Go 编到临时件 → 7664 完即退自检闸(不过则 7663 不动)→ 旧进程 `/shutdown` 自停并等单元彻底退出(容器内信号不可投,不能 restart)→ 首次换档备份 `acpsup.tsbak`(只认第一次,保 TS 回滚锚)→ 顶同名 → 起服务 → health 三后端验收,败态回滚 tsbak。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/node/lib/node_modules/@agentclientprotocol/ | 适配器;入口从各包 bin 解析,对布局稳 |
| /usr/local/bin/acpsup | 监督进程(Go 二进制) |
| /usr/local/bin/acpsup.tsbak | 切流前的 TS 本尊,回滚锚 |
| /var/lib/acpsup/keys.json | 多密钥表(SHA-256 哈希落盘,0600);首启含 legacy 导入与 admin 一把 |
| /var/log/acpsup/acpsup.log | 审计与访问日志(slog JSON,lumberjack 轮转;恒不含 prompt 正文与令牌) |
| /etc/systemd/system/acpsup.service | 常驻 unit;`Restart=on-failure`;实例重启自起 |
| /var/lib/acpsup/token | 平台 token;首启随机,权限 0600,打印一次,不进镜像 |
| 127.0.0.1:7663 | 平台 HTTP 面;仅回环,对外经 incus proxy 引出 |

## 配置

- 无配置文件;密钥面是 `keys.json`(管理口 `POST /keys` {label,role} 发新钥、`GET /keys` 列表、`POST /keys/{id}/revoke` 吊销;admin 全路由,caller 业务路由,`/shutdown` 与 keys 族对 caller 回 403)。
- agent 环境:claude 适配器 `DISABLE_UPDATES=1`;codex 适配器 `CODEX_PATH=/usr/local/bin/codex`(指镜像内锁定版本,禁用适配器自带)加 `NO_BROWSER=1`;模型道沿 agents 批的网关接线(见 claude-code 与 codex 册),acpsup 不经手凭证。
- 对外引出(宿主执行):`incus config device add <实例> acp proxy listen=tcp:10.10.10.13:7663 connect=tcp:127.0.0.1:7663`;listen 绑宿主 tailnet 地址(tailscale0),只对 tailnet 开,LAN 面不开;全端点先过 Bearer(无 token 401),不裸奔;要放开别的面改 listen。
- token 自取:`incus exec <实例> -- cat /var/lib/acpsup/token`;调用示例:`curl -H "Authorization: Bearer <token>" http://<宿主>:7663/health`。
- 端点面:`GET /health`(含 `build` 构建指纹,换档滞留检测用);`POST /session/new` {agent,cwd,model?};`POST /session/resume` {agent,sessionId,cwd,model?}(跨监督进程重启续会话;cwd 须等会话记录的 cwd,后端 fail-closed;未知 id 502,已在表 409);`POST /session/prompt` {sessionId,text};`POST /session/model` {sessionId,model};`POST /session/cancel`;`GET /events?sessionId=`(SSE,先回放后订阅,15 秒心跳注释保活);`POST /permission` {requestId,optionId};`GET /file?sessionId=&path=`(文件承接面,限该会话 cwd 子树,4MiB 封顶,空闲逐出后失效);`GET /vnc?sessionId=`(VNC 直显:WS 升级后裸 RFB 直通,子协议 `binary`;升级前先备显示栈,失败 503 `display_unavailable`;noVNC 直连);`POST /shutdown`。
- cwd 语义(桥面对齐):调用方传容器内绝对路径;目录不存在时在白名单前缀下自动建(`ACPSUP_CWD_ALLOW` 逗号分隔,默认 `/tmp/,/srv/work/`),之外 400;产物落容器内,平台侧经 `/file` 取。
- 模型清单与换模(2026-10-14 双面):`GET /models?agent=` 出各 agent 合法别名、默认与可换子清单(`models` 建会话全清单,`switch_models` 中会话可换清单,四模型面两者全等,`switchable` 总开关);`POST /session/model` {sessionId,model} 中会话换模,转发 ACP 原生 `session/set_config_option`(configId=model),会话号不变。
- 两道语义:建会话 `model` 参数走 spawn env 道(claude 注 `ANTHROPIC_MODEL`,codex 会话级 `CODEX_HOME`,归 `/var/lib/acpsup/codex/` 会话关自回收、服务重启清旧账),全清单生效;中会话换模按后端分道(catalog `switch_mode`,2026-10-14):codex 直通 ACP `set_config_option`(认目录全别名,第四别名 `zp-cx-glm5t`);claude 走重建道——适配器 `set_config_option` 只认 SDK 档位词、任意别名被解析后经 managed env 映射回 zp-cc GLM(适配器源码与 ds 档实跑已验),故以新 `ANTHROPIC_MODEL` 重拉适配器:已发过 prompt 的会话用 `session/resume` 原号续接(transcript 在盘,暗号跨换模已验),空会话(建后未发首条,无 transcript 可续,旧病 -32002)底层全新 `session/new` 换新号;对外会话号、事件环、权限桥两者都恒不变,适配器事件按 AcpID 匹配。pi 待 pi-rs-core 支持后开放(暂 400 明示)。
- 换模边界:回合在途 409(不排队);非法别名 400 带合法清单;`session/new` 响应透传后端 `configOptions`(桥拼下拉用);`config_option_update` 通知经事件流回推。
- VNC 直显(2026-10-15):每会话按需起 Xvfb(:100-:131)+ 有头 clean-chrome(browse 引擎同一副本;CDP 19200-19231 只回环),每条 WS 一条 `x11vnc -inetd`(stdio 即 RFB,断开自退);进程回收全走自退道(容器内 kill 族 EACCES):chrome 走 CDP Browser.close、Xvfb `-terminate`,停不掉的槽标泄漏不复用、重启按口映射清孤儿。鉴权收紧:caller 只能开自己建的会话(跨键与缺失同 404,admin 任意);WS 断开画面保留(下次新起 x11vnc 续上),chrome 常驻到会话关闭/空闲逐出;桥存活期 ping 30s + 隔拍 Touch(看画面不动键不逐出);第二条 WS 替换第一条;`cdp.ws` 落盘会话目录(0600,后续 browse 会师批 `BROWSE_CDP_WS` 用);帧内容永不落日志。
- 事件线形(调用方按此匹配):更新是 `{"kind":"session/update","update":{"sessionUpdate":"…"}}`;权限卡是 `{"kind":"permission","requestId":"perm-…","request":{…}}`,`requestId` 顶层取,应答走 `POST /permission`。

## 离线行为

- 支持:协议自检。关闭 eth0 后,`acpsup --selftest claude` 完成 initialize(protocolVersion=1)和 session/new,并返回会话标识。
- 平台 HTTP 只监听 127.0.0.1:7663;模型推理经网关,是运行期网络,不属于离线范围。

## 限制

- 信号策略:容器内 kill 族 EACCES;监督进程的停止走 `/shutdown` 自终止(干净退出,unit 不再拉起);切流/换档等单元退出回收有竞态窗,安装脚本带 inactive 等待闸。
- `GET /events` 每事件带 `id:` 行,断线重连带 `Last-Event-ID` 头或 `after=` 参数断点重放;事件滑出环(2000 条)从最旧重放;15 秒 `: ping` 心跳。
- 权限确认在 120 秒内没有应答则取消,不提供「始终允许」;平台请求没有 token 时响应 401;监督进程由 `/shutdown` 或 `--selftest` 结束。
- codex-acp 的 session/new 要凭证;网关接线后全通(2026-10-13 双视角回环过)。
- 会话全局上限默认 8 活,unit 环境变量 `ACPSUP_SESSION_MAX` 可调(测试期 16);空闲自动回收兜底:`ACPSUP_SESSION_IDLE` 分钟无活动逐出(默认 30,关适配器 stdin 自退),服务重启表清但 transcript 落盘不丢——续接走 `POST /session/resume`;同会话并发第二个 prompt 回 409。
- proxy 设备属实例配置,不进镜像;新实例按配置节命令一条复现。
- 测试模式(unit 注 `ACPSUP_AUTH_OFF=1`,2026-10-13 起):任意请求放行,身份记 test/admin;限流与每密钥会话上限随鉴权一起旁路(全员共桶无意义),全局会话上限 8 仍护机;回收时删该环境变量重启即回默认拒绝。

## 参见

- [claude-code.md](../tools-agents/claude-code.md)
- [codex.md](../tools-agents/codex.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: acpsup kind=service path=/usr/local/bin/acpsup note=ACP 监督进程(平台面 127.0.0.1:7663;systemd 常驻,经 incus proxy 对外)

# S-0003 对外开放 ACP 接口的 Golang 方案:acpsvc

> 研究单 acpex-01(2026-10-13,派 grok w7:p5,简报与两条补充裁定见当日 diary);回执 49 过、1 撤(按补充裁定撤三案对比表)、6 缺(均如实声明);总台抽核 3/3 过(pi-rs 模式表、pins 行号、GOPROXY/Go 版本)。可照抄立 REQ-0007(正文「REQ-0007 可照抄的需求」节)。

# acpex-01 对外开放 ACP 接口的 Golang 方案

日期:2026-10-13。只出方案。协议裁定仍是 S-0002。同日两条补充都已吸收:服务是本仓内的独立 Go 工程;它随镜像安装、在实例内常驻,对外提供 claude、codex、pi 三家。本页是下一张需求单的设计输入。

## 结论

在 `scripts/acpsvc/` 新建独立 Go 模块,持续维护。二进制名仍是 `acpsup`,安装路径仍是 `/usr/local/bin/acpsup`,监听仍是 `127.0.0.1:7663`。TypeScript 工程 `scripts/acp/` 在切流前继续服务,切流后删除。

- 模块路径:`github.com/raystyle/pi-rs-runtime/scripts/acpsvc`。布局是 `cmd/acpsup` 加 `internal/*`。不设 `pkg/`。
- 迁移分四步。M0 只建库。M1 把现行行为移植进 Go,并用 7664 做完即退出的 selftest,不与 TS 同时常驻。M2 一次切流,覆盖同名二进制。M3 在工作实例验收通过后删除 `scripts/acp/`。
- 终态由 Go 同时拥有平台 HTTP、stdio JSON-RPC、fs、terminal 和权限应答。不长期保留「Go 反代 + TS 监督」两进程。
- 对外名字是 `claude`、`codex`、`pi`。前两家拉 npm 适配器,再由适配器拉 claude code 与 codex CLI。`pi` 直接拉 `pi-rs --mode acp`,不经适配器,也不接 `--mode rpc`。
- 服务由 `install_acp` 编进镜像,systemd 常驻。容器内只绑 `127.0.0.1:7663`。实例外面靠 incus proxy 到达。
- 对外仍是现在这组私有 HTTP。不实现 ACP 的 Streamable HTTP 草案。
- 日志要写。一类 JSON 文件,标准库 `slog`,lumberjack 按大小轮转。模型 token 仍只记在网关 overcast。
- 可直接立 REQ-0007。REQ-0002 保持 implemented,直到 M2 切流后由 REQ-0007 承接平台口与 Client。

## 现状锚点

`acpsup` 是 TypeScript,`scripts/acp/src/` 共 470 行(main.ts 244,acpclient.ts 98,fsimpl.ts 93,测试 35)。`package.json` 的 name 是 `acpsup`,version 是 `0.1.0`。它在实例内当 ACP Client:stdio 拉起 claude-agent-acp 与 codex-acp,对本机提供 HTTP。

现行平台口在 `scripts/acp/src/main.ts`:

- 默认端口 7663,绑定 `127.0.0.1`(第 19、118–123 行)。
- 全路径核对 `Authorization: Bearer`,失败 401(第 123 行)。token 首启随机,0600,路径 `/var/lib/acpsup/token`(第 24–32 行)。
- `POST /session/prompt` 上游超时 600 秒(第 164 行)。`session/new` 与 `initialize` 各 30 秒(第 145–146 行)。
- `GET /events` 先把内存环整段重放,再订阅。环上限 2000 条。没有 SSE `id`,没有 `Last-Event-ID`(第 61–64、179–189 行)。
- `session/request_permission` 转发后 120 秒无应答则 `cancelled`(第 87–99 行)。
- `POST /shutdown` 停进程(第 202–205 行)。安装脚本在重启前调这个口,因为容器内信号返回 EPERM。

安装脚本把 acpsup 写成 systemd 单元,`ExecStart=/usr/local/bin/acpsup`,`Restart=on-failure`(`scripts/install-tools.sh` 第 1515–1536 行)。往实例送源码的命令是 `incus file push scripts <实例>/root/ -r`(`AGENTS.md`)。镜像内 Go 是 1.27.1(`scripts/lib/common.sh` 第 32 行,`docs/params.md`)。构建期 `GOPROXY=https://goproxy.cn,direct`(`common.sh` 第 13–14 行)。运行期 `GOPROXY=off`。仓内另有一个 Go 模块 `scripts/lock/go`,`module prewarm`,`go 1.26.0`,只为离线编译预热,不是这个服务。

S-0002 已定:ACP v1 的稳定传输是 stdio;Streamable HTTP 不进生产;web 平台在另一个项目;本仓只做实例面;平台口只绑回环,用 incus proxy 引出,与 6080 同一口径。

## 1. 目录、模块与迁移序

补充裁定把服务定为独立 Go 工程,放在本仓独立目录里持续维护,与 `scripts/acp/` 并列。下面四项是这个问题的结论。

### 目录

源码放 `scripts/acpsvc/`,与 `scripts/acp/` 并列。不放进 `scripts/acp/`,也不放到仓库根。

放在 `scripts/` 下的原因:实例只收这一棵树。`AGENTS.md` 与 `README.md` 的推送命令都是 `incus file push scripts`。根上另起目录就要加第二趟推送,安装脚本还要认识一个新的容器路径。

不放进 `scripts/acp/` 的原因:该目录已是 bun 工程(`package.json`、`src/`、`test/`)。同一目录再放 `go.mod`,两个工具链会抢根目录。迁移期 TS 必须能原样编译。

不放进 `scripts/lock/go/` 的原因:那里的模块名是 `prewarm`,语言版本写成 `go 1.26.0`,职责是把一批第三方库烤进模块缓存。服务源码混进去之后,离线冒烟和 ACP 进程会绑在同一次 `go build` 上。

目录名用 `acpsvc`,不用 `acpsup`。`acpsup` 继续指产品和二进制,避免和 `scripts/acp`、`/usr/local/bin/acpsup` 三个名字叠在一起。

### 布局与模块路径

```text
scripts/acpsvc/
  go.mod
  go.sum
  cmd/acpsup/main.go          只做参数、监听、组装
  internal/platform/          HTTP、Bearer、密钥、限流、SSE
  internal/backend/           三家注册表:适配器两家,pi 原生一家
  internal/acpclient/         stdio JSON-RPC,对应 acpclient.ts
  internal/fsimpl/            fs 与 terminal,对应 fsimpl.ts
  internal/session/           会话表、事件环、权限槽;一会话一子进程
  internal/logx/              slog 与轮转
```

`go.mod` 第一行:

```text
module github.com/raystyle/pi-rs-runtime/scripts/acpsvc

go 1.27.1
```

模块路径取仓库地址加目录。仓库地址在 `README.md` 第一段:`github.com/raystyle/pi-rs-runtime`。这个模块是主模块。`go build` 在该目录内执行,不从 goproxy 拉取它自己。

`cmd/` 放唯一的 `main`。`internal/` 放其余包。Go 的模块布局文档对服务器项目的建议是:命令放在 `cmd/`,实现放在 `internal/`。`internal` 目录不能被其他模块导入。本仓没有第二个模块需要链接监督进程的会话表。`scripts/lock/go` 若能 import 这些包,预热工程会误依赖服务内部类型。

不设 `pkg/`。官方布局文档没有把 `pkg/` 列为服务器项目的目录。现在也没有别的模块要引用这套包。以后真有稳定库,再从 `internal` 拆出去。

社区仓库 `golang-standards/project-layout` 不是 Go 团队的规范,不作为本布局的依据。

### 迁移序

终态是一个 Go 进程。并存期只并存源码和一次性 selftest,不并存两个常驻监督进程。两个常驻进程会有两套会话和两把 token。

| 阶段 | 谁听 7663 | Go 产物 | `scripts/acp/` | 切流 |
| --- | --- | --- | --- | --- |
| M0 建库 | TS `acpsup` | 只 `go test`。不写入 `/usr/local/bin`,不起单元 | 不动 | 不切 |
| M1 移植并自证 | TS `acpsup` | 编到 `/usr/local/bin/acpsup-go`。单元仍指向 TS。`--selftest` 绑 7664,跑完退出 | 不动 | 不切 |
| M2 切流 | Go,路径仍是 `/usr/local/bin/acpsup` | 先对 7663 `POST /shutdown`,把 bun 二进制留成 `/usr/local/bin/acpsup.tsbak`,再覆盖同名路径 | `install_acp` 不再把它编到正式路径 | 一次切换 |
| M3 下线 | Go | 同左 | 删除目录 | 已经切完 |

M1 的 7664 只在 selftest 进程的生命期内占用。selftest 退出后端口放开。不写 `acpsup-go.service`。

M2 的切换顺序写进 `install_acp`,同一次执行做完:

1. 编译 Go 到临时文件。
2. `acpsup-go --port 7664 --selftest claude` 必须打印 `protocolVersion=1` 和 sessionId。失败则停,7663 仍是 TS。
3. 对 `127.0.0.1:7663` 发 `POST /shutdown`(现行第 1529–1534 行的做法)。
4. `mv /usr/local/bin/acpsup /usr/local/bin/acpsup.tsbak`,再把新二进制放到 `/usr/local/bin/acpsup`。
5. 单元 `ExecStart` 保持 `/usr/local/bin/acpsup`。不新增第二个单元。
6. `systemctl start acpsup`。Go 进程读已有 `/var/lib/acpsup/token`,导入为 `legacy` 管理员密钥。
7. 对 7663 做无 token 401、带 token 的 `/health` 200。失败则把 `acpsup.tsbak` 移回并再次 start。

M3 的删除条件,全部满足才删 `scripts/acp/`:

- 工作实例上的 `/usr/local/bin/acpsup` 是 Go 二进制(`acpsup -version` 打出 Go 侧版本)。
- M2 的 selftest、401、`/health`、日志 canary、eth0 down、root 与 ubuntu 两面都过。
- `install_acp` 已经不再调用 `bun build` 生产 acpsup。

M3 与 M2 分属两次提交。同一次提交里又切流又删 TS,回滚要同时翻二进制和源码。M3 不需要等 `incus publish`。publish 仍等用户点头。留下未接线的 TS 树会让下一次 `install_acp` 有机会把 bun 二进制编回去,所以 M3 紧跟 M2 的实例验收,不另等一个镜像版本。

### 版本与发布纪律

服务自身版本写在 Go 源码的常量里,初值 `0.1.0`,与现行 `package.json` 对齐。用 `-ldflags '-X main.version=...'` 注入。它不是 goproxy 上的模块,不进 `GO_PIN`,也不要手改 `scripts/lib/pins.sh`(该文件由 `resolve-pins.sh` 生成)。

第三方直接依赖进 `GO_PIN`,并提交 `go.sum`:

- `gopkg.in/natefinch/lumberjack.v2`,发布页最新 tag 为 v2.2.1。
- `golang.org/x/time` 的 `rate`。版本等 `resolve-pins.sh` 跑出来再写入,本页不猜。

`install_acp` 在编译前执行 `go list -m`,版本与 `GO_PIN` 不一致则失败。禁止 `@latest`。

构建在实例内、`install_acp` 同组完成。脚本已带上 `common.sh` 的 `GOPROXY` 与 `GOSUMDB`。运行期 `GOPROXY=off` 只影响再编译,不影响已装好的二进制。离线冒烟跑二进制和 `--selftest`,不要求离线再编译。

镜像发布仍是一批一实例。改动进 `pi-rs-runtime-20261010-2210`。不新 launch。不自行 publish。Go 源码进 git,二进制不进 git。

## 2. 协议分工

终态的界线在 Go 进程里面,不在两个进程之间。

M2 之后 Go 拥有现在 TS 拥有的全部协议行为:

- stdio JSON-RPC,一行一条,stdout 只有 ACP 消息。规范页写明这是应支持的传输,Streamable HTTP 仍是草案。移植时保持 `acpclient.ts` 第 1–2 行的分帧。
- `initialize` 的 `protocolVersion: 1`,`session/new` 的 `mcpServers: []`。
- fs 绝对路径读写,terminal spawn。`terminal/kill` 在本机返回 EACCES,这是宿主信号策略(`fsimpl.ts` 第 2 行,`docs/known-issues.md`)。Go 同样把该错误回给适配器,不在 Go 里重试信号。
- 权限 120 秒无应答则 `cancelled`。不自动选择 `allow_always`。规范把 `allow_always` 定义为选项种类,并允许客户端按用户设置自动同意。本仓比规范更严,REQ-0002 R4 的这条在 Go 里原样保持。
- prompt 上下文 600 秒,session/new 与 initialize 各 30 秒。

Go 在上述行为之外增加:多密钥、角色、限流、请求体上限、访问日志、审计日志、SSE 序号和注释心跳。这些在 M1 就放进 `internal/platform`,随 M2 一起对外。

M0 与 M1 期间,跑着的进程仍是 TS。这段时间不改 `scripts/acp/src/main.ts` 的协议行为,也不给 TS 加 `/sessions` 或 SSE `id`。序号写在 Go 的事件环上。给即将删除的 TS 打补丁,会做出两套序号。

不采用社区 Go SDK `github.com/coder/acp-go-sdk` 做这次移植。ACP 仓库的官方库清单是 Kotlin、Java、Python、Rust、TypeScript,没有 Go。该模块在 pkg.go.dev 上有 v0.13.5(页面日期 2026-06-02),页面同时标明它不是模块最新版。现行客户端是 98 行,已经对镜像里的两只适配器跑过 selftest。移植这 98 行,比引入一份仍在改版本的 SDK 更容易对照。

也不实现规范草案里的 Streamable HTTP / WebSocket。那份 RFD 自己写:目前只有 stdio,各家自造 HTTP 会导致互不相容。本仓的平台 HTTP 是 S-0002 已接受的私有口,不是 ACP 传输。

### 三家后端

`POST /session/new` 的 `agent` 字段只接受三个名字:`claude`、`codex`、`pi`。`claude` 对外就是 claude code,`codex` 就是 codex CLI。名字保持现在的短词,已有调用方不用改。

三家共用一个子进程形状:一会话一个子进程,stdin/stdout 是 ACP v1 的换行分帧,stderr 进调试日志。`session/new` 发给子进程的 `mcpServers` 仍是空列表。S-0002 要求 pi 的 MVP 按这个空列表互通;非空列表在 pi 的 MCP client 落地前应失败,监督进程不静默改成空。本张需求不给任何一家送非空列表。

注册表是一张静态表,不是插件目录。每一行有 `name`、`kind`、`argv`、`env`、`clientCapabilities`。`kind` 只有两种。

| name | kind | argv | env | initialize 里的 clientCapabilities |
| --- | --- | --- | --- | --- |
| `claude` | adapter | `node` 加 `@agentclientprotocol/claude-agent-acp` 的 bin | `DISABLE_UPDATES=1` | fs 读写与 terminal 都为 true |
| `codex` | adapter | `node` 加 `@agentclientprotocol/codex-acp` 的 bin | `CODEX_PATH=/usr/local/bin/codex`,`NO_BROWSER=1` | 同上 |
| `pi` | native | `/usr/local/bin/pi-rs`,`--mode`,`acp` | 不注入适配器变量 | fs 与 terminal 都为 false |

适配器的 bin 不写死文件名。启动时读 `/opt/node/lib/node_modules/@agentclientprotocol/<包>/package.json` 的 `bin` 字段,与 `main.ts` 第 36–39 行相同。包名和版本仍是 `CLAUDE_ACP_VERSION`、`CODEX_ACP_VERSION`,由现行 npm 安装段锁定。这两项不是 Go 模块,不进 `GO_PIN`。

`pi` 不走 node,不读适配器包。argv 就是镜像里的 `pi-rs` 加 `--mode acp`。这是 S-0002 第五节的入口:rs-agent 里该模式经 stdio JSON-RPC 直接调 `AgentSession`。监督进程不连接 pi-rs 的 `--mode rpc`,那是另一套私有 JSONL。`pi-rs` 的 `package.json` 把命令名定为 `pi-rs`。

`pi` 的工具在子进程内执行。S-0002 不要求这些工具改走 Client 的 fs/terminal,所以 initialize 对 `pi` 不广告这两项能力。权限转发对三家一样:子进程调用 `session/request_permission` 时,监督进程把卡片交给平台,120 秒无应答则 `cancelled`,不自动选 `allow_always`。pi 若在 edit/write/execute 前不发这张卡,那是 pi-rs 侧的缺口,监督进程不替它自动同意。

就绪与自检分开:

- `/health` 的 `agents` 数组固定三项。适配器能解析到 bin 则 `ready: true`。`pi` 要同时满足两点才 `ready: true`:`/usr/local/bin/pi-rs` 可执行,且 `pi-rs --help` 在 5 秒内结束,输出里能看到 `acp` 这个模式。超时、文件不存在、二进制还没有该模式,写成不同的 `err`。健康检查不拉起会话。
- 切流门禁仍是 claude 的 selftest(`protocolVersion=1` 与 sessionId)。codex 在 `session/new` 就要凭证,与现行册面相同,不作为切流门禁。
- `pi` 的 selftest 不挡住 `install_acp`。2026-10-13 查看 pi-rs 的 CLI 文档,`--mode` 只有 `text`、`json`、`rpc`,没有 `acp`。S-0002 把 Agent 侧标为待实现。在该模式出现之前,`pi.ready` 为 false。镜像构建不因此失败。调用方对 `pi` 发 `session/new` 得到 400(未就绪),与今天未知 agent 的状态码相同。
- 本仓不编译、不安装 pi-rs。二进制由 pi-rs 仓自己的发布进镜像。REQ-0007 只钉 argv 合同。

换 agent 就是新开一个 session,从而新起一个子进程。不在一个子进程里切换三家。关掉子进程只用于该会话结束或 `/shutdown`。取消一轮用 `session/cancel`。

## 3. 日志设计

要写日志。7663 经 incus proxy 进 LAN 和 tailscale 之后,需要能回答谁在何时调用了哪个口。调试适配器时还要有一条可开关的错误记录。日志从 M1 的 selftest 起就由 Go 写出,M2 之后是唯一的监督进程日志。

四类里写三类,用量不在这里记 token:

| 类别 | 字段 `cat` | 默认 | 记什么 |
| --- | --- | --- | --- |
| 访问 | `access` | 开,级别 info | 每个完成的 HTTP 请求一条。SSE 只在连接开始和结束各一条,不按事件刷 |
| 审计 | `audit` | 开,级别 info | `session/new`、`session/cancel`、`permission` 的选项、`shutdown`、密钥签发与吊销 |
| 调试 | `debug` | 关 | 适配器 stderr 的截断、JSON-RPC 错误码 |
| 用量 | 不设 | 不记模型 token | 见下文与 overcast 的分工 |

调用方身份是密钥的公开 `key_id`。进程看到的 TCP 对端在 incus proxy 后面,多半是 `127.0.0.1`,不能当成 LAN 上的人。日志字段名用 `peer`,表示这是回环连接的对端。

### 结构化选型

用标准库 `log/slog` 的 `JSONHandler`。

| 库 | 依赖 | 与本服务的关系 |
| --- | --- | --- |
| slog | 无,Go 1.21 起在标准库,镜像是 1.27.1 | JSON 一行一条,可用 `LevelVar`。热路径是一次 600 秒的 prompt,日志是每次调用几行 |
| zap(`go.uber.org/zap`) | 第三方模块 | 面向高 QPS。这里省下的分配换不来可观察的差别,多一份锁定版本 |
| zerolog(`github.com/rs/zerolog`) | 第三方模块 | 同上 |

`slog` 默认 JSON 形如 `{"time":"...","level":"INFO","msg":"...","count":3}`。时间、级别、消息这三个键保持默认,业务字段往后加。

级别只在进程启动时读环境变量 `ACPSUP_LOG_LEVEL`,默认 `info`。容器内 SIGHUP 不可用,不做运行中改级别。要改级别,走 `/shutdown` 再由 systemd 拉起。

### 日志文件与轮转

一个文件:`/var/log/acpsup/acpsup.log`,模式 0600,属主 root。目录 `/var/log/acpsup` 模式 0750。路径用产品名 `acpsup`,与二进制、单元、数据目录同一套名字。

轮转用 `gopkg.in/natefinch/lumberjack.v2`,发布页上的最新 tag 是 v2.2.1(2026-10-13 查看)。参数:

- `MaxSize`: 50(单位 MB)
- `MaxBackups`: 5
- `MaxAge`: 14(单位天)
- `Compress`: true
- `LocalTime`: true

选它的原因:轮转发生在进程内,靠文件大小,不发信号。本机容器内 logrotate 常用的 SIGHUP 会碰到 EPERM。journald 随 systemd 单元存在,但审计记录放在 journal 里会跟着 vacuum 和限速丢掉,也不能直接 `incus file pull` 一个明文文件。

结构化日志只写这一个文件。stderr 只在启动时打一行听端口说明,systemd 会把它收进 journal。那一行不是审计副本。两份结构化流在一边阻塞时会岔开,所以不双写。

lumberjack 上游不活跃,接口是一个 `io.Writer`。`go.sum` 锁定校验和。以后要去掉这一个依赖,只换 Writer,`slog` 调用不变。

### 字段、脱敏、级别

每条都有:`time`、`level`、`msg`、`cat`、`req`。`req` 是 16 个十六进制字符,同时放进响应头 `X-Request-Id`。

访问字段:`method`、`path`、`status`、`dur_ms`、`bytes_in`、`key_id`、`session_id`、`peer`。

审计字段按动作取用:`action`、`key_id`、`session_id`、`agent`、`cwd`、`option_id`、`prompt_bytes`、`role`。`cwd` 最长保留 256 个字符。

恒定不写:

- `Authorization` 头、Bearer 原文、密钥原文、密钥哈希、`/var/lib/acpsup/token` 的内容。
- prompt 正文。只写 `prompt_bytes`。渗透任务的 prompt 里会有目标口令和利用文本,截断仍会露出短秘密。调试级别也不写正文。
- SSE 的 `data` 载荷。里面有 `session/update` 和完整的权限请求。
- 适配器 stderr 全文。调试级别只留前 200 字节。

级别:

- info:访问与审计。
- warn:401、403、429、502、504。
- error:密钥文件读不了、随机源失败、适配器进程退出。
- debug:默认关。打开后多写 JSON-RPC 错误码和截断后的适配器 stderr。

验收时用一句固定 canary 做 prompt,断言日志文件里没有这句,也没有测试用的 Bearer。

### 示例行

访问,一次成功的 prompt:

```json
{"time":"2026-10-13T21:10:00.123456789+08:00","level":"INFO","msg":"http","cat":"access","req":"a1b2c3d4e5f67890","method":"POST","path":"/session/prompt","status":200,"dur_ms":81234,"bytes_in":4096,"key_id":"k_7f3a","session_id":"sess_abc","peer":"127.0.0.1:51234"}
```

审计,新建会话:

```json
{"time":"2026-10-13T21:09:00.000000000+08:00","level":"INFO","msg":"session_new","cat":"audit","req":"0011223344556677","action":"session/new","key_id":"k_7f3a","session_id":"sess_abc","agent":"claude","cwd":"/tmp"}
```

审计,权限选择:

```json
{"time":"2026-10-13T21:09:40.000000000+08:00","level":"INFO","msg":"permission","cat":"audit","req":"8899aabbccddeeff","action":"permission","key_id":"k_7f3a","session_id":"sess_abc","option_id":"allow-once"}
```

拒绝,无密钥:

```json
{"time":"2026-10-13T21:11:00.000000000+08:00","level":"WARN","msg":"http","cat":"access","req":"fedcba9876543210","method":"GET","path":"/health","status":401,"dur_ms":1,"bytes_in":0,"key_id":"","peer":"127.0.0.1:51299"}
```

### 与 overcast 的分工

模型 token 只记在网关 `http://192.168.88.10:8317`。claude 册写明用量集中在网关侧。Go 进程记的是调用方账:哪把密钥、哪个 agent、哪个 session、prompt 字节数、耗时、HTTP 状态。

两边没有共同的请求号。监督进程不经手模型凭证,适配器直接跟网关说话。用 prompt 原文对齐两边会迫使两边都存正文。本方案不做这件事,也不在 Go 里估算 token。

## 4. 多调用方

密钥、并发、超时、SSE 重连按下面执行。数字是单台渗透实例的建议默认值,本轮没有压测。写进 REQ 时标成可改默认值。这些规则在 M2 切流时生效。M1 的 selftest 只检查 401 与 `/health`,不把限流提前加到仍在服务的 TS 进程上。

### 密钥

文件 `/var/lib/acpsup/keys.json`,模式 0600,属主 root。与现行 token 同一目录,M2 不必迁数据目录。安装脚本不生成它,避免密钥进镜像。首启若文件不存在:用 `crypto/rand` 生成管理员密钥,写文件,向 stderr 打一次原文。

记录字段:`id`(公开)、`hash`(SHA-256 十六进制)、`label`、`role`、`disabled`、`created`(RFC3339)。不存原文。

新密钥格式:`acp_` 加 32 字节的 base64.RawURLEncoding。校验时对全部记录做 SHA-256 再 `crypto/subtle.ConstantTimeCompare`,避免按密钥个数提前返回。密钥数量按小于 32 把设计。

角色:

- `admin`:全部路由,含 `POST /shutdown` 和 `/keys`。
- `caller`:业务路由。对 `/shutdown` 和 `/keys` 回 403 `{"error":"forbidden"}`。

管理口:

- `POST /keys`,体 `{label, role}`。`role` 省略时当作 `caller`。响应 `{id, token}`,token 只此一次。
- `GET /keys`,返回 id、label、role、disabled、created,无哈希。
- `POST /keys/{id}/revoke`。

内存里的表由这些口更新并落盘。手改 JSON 要重启才生效。

兼容:M2 首次启动时,若 `/var/lib/acpsup/token` 存在且 keys 文件刚创建,把该 token 的哈希记成 `id=legacy`、`role=admin`、`label=imported-acpsup`。现行调用方不用换 token。签发平台自己的密钥后,吊销 `legacy`。在吊销前,这把旧 token 仍能关机。token 文件保留,供回滚到 `acpsup.tsbak` 时 TS 仍能读到同一把 token。

### 并发与排队

建议默认:

- 全局存活会话 8。
- 每把密钥存活会话 4。
- 同一 `sessionId` 同时只允许一个 `POST /session/prompt`。第二个回 409 `{"error":"prompt_in_flight"}`。
- 短请求令牌桶:每把密钥 10 秒 30 次。计入的路由是 `/health`、`/session/new`、`/session/cancel`、`/permission`、`/keys`。用 `golang.org/x/time/rate`。prompt 不进这个桶。
- 超限回 429 `{"error":"rate_limited"}`,响应头 `Retry-After: 5`。

不排队。prompt 本身最长 600 秒,队列会把等待算进另一次超时。会话上限打满时,`/session/new` 直接 429。

计数就是本进程的会话表。进程重启后表为空,正在跑的适配器子进程随进程一起退出。没有第二个进程需要再拉一份 `/sessions`。

### 超时

`http.Server` 的 `WriteTimeout` 覆盖整段响应写出,设了就会切断 600 秒 prompt 和 SSE。因此:

- `ReadHeaderTimeout`: 5 秒。挡住慢速头。
- `ReadTimeout`: 0。请求体用 `MaxBytesReader`,上限 1 MiB。
- `WriteTimeout`: 0。截止时间按路由放在请求 context 上。
- `IdleTimeout`: 120 秒。只约束空闲 keep-alive,不约束正在写的 SSE。

| 路由 | 截止 |
| --- | --- |
| `POST /session/prompt` | 600 秒,与现行 `main.ts` 第 164 行相同 |
| `POST /session/new` 与 `initialize` | 各 30 秒 |
| `POST /permission` | 等待平台应答;120 秒无应答则对适配器回 `cancelled`,HTTP 本身在应答或取消时返回 |
| `/health`、`/session/cancel`、`/shutdown`、`/keys` | 处理函数直接返回。读头超时 5 秒已足够 |
| `GET /events` | 直到客户端断开 |

`/permission` 的 120 秒是协议槽,不是更短的 HTTP 写超时。写超时若设成 60 秒,平台在第 90 秒提交的选择会得到断开,适配器却还在等。

SSE 由本进程直接写 `http.Flusher`。每条事件写出后 flush。不经 `httputil.ReverseProxy`,因此也不启用响应压缩。

客户端断开只结束这次 HTTP。现行 TS 不会因为 HTTP 断开去 `session/cancel`。Go 初版同样不宣称断开等于取消。要补这个行为,在 M2 之后单独做。

### SSE 断线重连

现行行为:重连后整环重放,客户端会看到重复事件(`main.ts` 第 179–189 行)。

Go 的事件环在写入时分配该会话的单调整数,并写成 SSE 字段 `id`。重连请求带 `Last-Event-ID`(查询参数 `after` 同义)时,只重放编号更大的事件,再继续实时推。HTML 规范规定浏览器 EventSource 在重连时带回这个头;以冒号开头的行是注释,不产生事件。

环仍最多保留 2000 条。客户端要的编号已经滑出环时,从环里最旧的一条重放,并在访问日志里记 `replay=gap`。不另建第二份环。

每 15 秒写一次 `: ping\n\n`,减轻中间盒子把空闲连接拆掉。注释不进入事件环,不占 `id`。

## 5. 兼容面

保留的端点、方法和 JSON 形状:

- `GET /health`
- `POST /session/new`,体 `{agent, cwd}`,成功体含 `sessionId`
- `POST /session/prompt`,体 `{sessionId, text}`
- `POST /session/cancel`
- `GET /events?sessionId=`
- `POST /permission`,体 `{requestId, optionId}`
- `POST /shutdown`
- 无 Bearer 或 Bearer 不对:401,体 `{"error":"unauthorized"}`

M2 之后调用方仍连 `127.0.0.1:7663`,仍用原来的 token。incus proxy 不用改。systemd 单元的 `ExecStart` 路径不用改。rctl 收录行的 path 仍是 `/usr/local/bin/acpsup`。

有意的行为差,在 M2 写进册面:

- 新签发的 `caller` 密钥不能 `/shutdown`,回 403。`legacy` 在吊销前仍可以。
- 会话打满、短请求超速、同一会话第二个 prompt:429 或 409。旧的单 token 进程没有这些状态码。
- `GET /events` 多 `id` 行。旧客户端忽略未知 SSE 字段即可。`after` 与 `Last-Event-ID` 是新增能力。
- `/health` 的 `agents` 多一项 `pi`。只读取 `claude` 与 `codex` 的调用方不受影响。
- 二进制从 bun 换为 Go。源码目录从 `scripts/acp/` 换成 `scripts/acpsvc/`。这是册面要改的句子,不是调用方要改的 URL。

迁移时要改的仓内文档,发生在 M2,不在 M0:

- `docs/items/tools-acp/acp.md`:版本行改为 Go 常量 `0.1.0`;来源改为 `scripts/acpsvc` 由 `install_acp` 编译;文件表增加 `/var/lib/acpsup/keys.json` 与 `/var/log/acpsup/acpsup.log`。7663 与 `/usr/local/bin/acpsup` 两行保留。
- `scripts/ctl/data/resources.json` 只改 acpsup 那条的说明,不新增第二条服务。再跑 `scripts/gen-rctl-catalog.sh`。不手改 `catalog.tsv`。
- REQ-0002 在 M2 之前保持 implemented。M2 的追溯记在 REQ-0007:R3 与 R4 的实现从 TS 换成 Go,验收判据不变,并加上密钥与日志。

册面从「单 token、无并发上限」变成「多密钥、有上限」。调用方代码不用改,直到运营吊销 `legacy`。

## 6. 交付形态

服务随容器走。`install_acp` 在镜像构建期编译并安装,systemd 在每个从该镜像拉起的实例里把进程留住。不在宿主上另放一份网关,也不在实例启动后再编译。

镜像内的安装链:

1. 镜像里已有 claude code 与 codex,路径 `/usr/local/bin/claude`、`/usr/local/bin/codex`。版本标量是 `CLAUDE_CODE_VERSION`(当前 2.1.296)与 `CODEX_VERSION`(当前 0.162.1),见 `scripts/lib/pins.sh`。它们由 agents 组安装,不由本服务编译。
2. `install_acp` 安装两只 npm 适配器,版本是 `CLAUDE_ACP_VERSION` 与 `CODEX_ACP_VERSION`。
3. 同一函数编译 `scripts/acpsvc`,装到 `/usr/local/bin/acpsup`,写 `/etc/systemd/system/acpsup.service`,`systemctl enable` 后 start。
4. 单元 `Restart=on-failure`。停止仍走 `POST /shutdown`,因为容器内信号返回 EPERM。
5. 监听地址写死 `127.0.0.1:7663`。incus proxy 在宿主上把 `0.0.0.0:7663` 转到这个口,与 6080 同一口径。proxy 设备不属于镜像构建,每个实例单独加。

pi-rs 不在这三步里。镜像里没有 `/usr/local/bin/pi-rs` 时,服务仍常驻,`/health` 里 `pi.ready` 为 false。pi-rs 进镜像之后不用改监督进程的代码,只要路径和 `--mode acp` 对上。

Go 侧锁定面只有 lumberjack 与 `golang.org/x/time/rate`(第 1 节)。适配器版本继续走 npm 标量。pi-rs 的版本留在它自己的仓,本仓不把它写进 `GO_PIN`。

M0 起,`install_acp` 增加 Go 构建,且在 M2 之前不替换正式二进制:

```bash
cd /root/scripts/acpsvc
# go list -m 的直接依赖版本必须等于 GO_PIN,否则失败
go test ./...
go build -trimpath -ldflags '-s -w -X main.version=0.1.0' -o /usr/local/bin/acpsup-go ./cmd/acpsup
```

M1 在上述构建之后加:

```bash
/usr/local/bin/acpsup-go --port 7664 --selftest claude
```

这一步失败则 `install_acp` 失败。7663 上的 TS 单元不动。

M2 起删除 bun 正式安装,改为第 1 节的切换顺序。构建输出直接是 `/usr/local/bin/acpsup`。`acpsup-go` 这个临时名字只存在于 M1。

M0 到 M1,TS 段保持今天的样子,仍在 Go 段之前执行:

```bash
cd /root/scripts/acp
bun build --compile --minify src/main.ts --outfile /usr/local/bin/acpsup
acpsup --selftest claude
```

自检:

1. M1:`acpsup --selftest claude`(TS,7663 的默认端口,跑完退出;若单元已占着 7663,这步与今天一样会绑失败,安装脚本应先按现行办法 shutdown 再 selftest,然后再 start)。随后 `acpsup-go --port 7664 --selftest claude` 打印 `protocolVersion=1`。
2. M2 之后只留 Go:`acpsup --selftest claude` 在 7663 上跑完退出,证据相同。另作 HTTP 检查:无 Bearer 得 401;错误 Bearer 得 401;有效密钥 `GET /health` 得 200,体里有 `claude`、`codex`、`pi` 三项;日志文件不含 canary 和 Bearer。`pi` 未就绪时这项检查仍通过,只要 `ready` 为 false 且 `err` 非空。
3. 断网(eth0 down)下 selftest 仍过。模型推理失败仍算协议面证据,与现行 selftest 相同。

进程以 root 跑(systemd 默认)。ubuntu 用户拿 Bearer 调 7663,应得到与 root 相同的 HTTP 结果。ubuntu 读不了 0600 的密钥文件和 token 文件。验收覆盖这两个视角。

单元在 M2 之后仍是一份:

```ini
# /etc/systemd/system/acpsup.service
[Service]
ExecStart=/usr/local/bin/acpsup
Restart=on-failure
```

停止仍是 `POST /shutdown`。不依赖 SIGTERM。

## REQ-0007 可照抄的需求

标题:acpsvc,用独立 Go 工程承接 acpsup。前置:REQ-0002。研究:本页。补充裁定:2026-10-13。

- R1 源码在 `scripts/acpsvc/`。模块路径 `github.com/raystyle/pi-rs-runtime/scripts/acpsvc`。`go 1.27.1`。布局为 `cmd/acpsup` 与 `internal/{platform,backend,acpclient,fsimpl,session,logx}`。不设 `pkg/`。
- R2 M0 只加目录与 `go test`。不改 7663 的监听进程。
- R3 M1 移植 stdio、fs、terminal、权限 120 秒、禁止自动 `allow_always`、空 `mcpServers`。注册表三行按第 2 节的表。`acpsup-go --port 7664 --selftest claude` 打印 `protocolVersion=1`。不起第二份单元。`pi` 的 selftest 失败不让本步骤失败。
- R4 M2 一次切流。正式路径仍是 `/usr/local/bin/acpsup`,端口仍是 7663。切换前 selftest 失败则不替换。切换后 HTTP 验收失败则恢复 `acpsup.tsbak`。
- R5 七个旧端点的路径与成功体保持不变。无有效 Bearer 回 401。`caller` 调 `/shutdown` 与 `/keys` 回 403。旧 token 导入为 `legacy` admin。
- R6 并发与超时采用第 4 节的表。不排队。`WriteTimeout` 为 0。SSE `id` 与 `Last-Event-ID` 在 Go 的事件环上实现。
- R7 日志采用第 3 节:slog JSON、`/var/log/acpsup/acpsup.log`、lumberjack、不记 prompt 正文、不记 token、不记模型用量。
- R8 直接依赖 lumberjack 与 `golang.org/x/time/rate` 进入 `resolve-pins.sh` 的 go 清单,版本写入 `GO_PIN` 与 `go.sum`。缺锁定版本则构建失败。服务自身版本是源码常量,不进 `GO_PIN`。
- R9 M3 在第 1 节的删除条件满足后去掉 `scripts/acp/`。与 M2 分提交。
- R10 册面与 `resources.json` 在 M2 同步。catalog 由生成脚本重写。不新增第二条 rctl 服务。
- R11 验收:双视角、无 token 401、health 200 且 agents 含三项、canary 不进日志、eth0 down 后 claude selftest 仍过、`protocolVersion=1`。`pi` 在二进制或 `--mode acp` 缺失时允许 `ready: false`。
- R12 进程随镜像常驻:`install_acp` 写 systemd 单元并 enable。只绑 `127.0.0.1:7663`。不在宿主安装第二份二进制。

做这张需求时进现有实例 `pi-rs-runtime-20261010-2210`。不新 launch。publish 仍等用户点头。

## 风险与边界

- M2 是唯一的切流点。selftest 放在替换二进制之前;HTTP 验收失败则移回 `acpsup.tsbak`。两步都要写进 `install_acp`,不能只靠人工。
- M1 若把 `acpsup-go` 做成常驻单元,会和 TS 各持一套会话。本方案禁止这份单元。
- 全局 `WriteTimeout` 会切断 600 秒 prompt 和 SSE。第 4 节把该值定为 0。
- 处理函数若把请求体写入日志,prompt 会落盘。日志接口不接收 body,并用 canary 测试守住。
- 客户端断开不等于取消 agent。现行 TS 同样如此。M2 之后再单独立项。
- `legacy` 在吊销前具备 admin。运营要在平台密钥可用后吊销它。token 文件在回滚完成前保留。
- lumberjack 上游安静。锁定校验和,调用面只是 `io.Writer`。
- 社区 Go ACP SDK 版本在动,且不在官方库清单里。移植不引入它。
- 规范上的 Streamable HTTP 仍是草案。本方案的 HTTP 是私有平台口。
- 会话上限、桶速率、日志 50 MB 都是建议默认值,没有压测数据。
- Go 二进制的字节数本轮没有测量。
- 本页没有进容器跑通。实现验收仍要 root 与 ubuntu 两面,并在 eth0 down 后做。
- 2026-10-13 的 pi-rs CLI 还没有 `--mode acp`。本方案把 argv 定下来,不把 pi-rs 的 Agent 实现算进 REQ-0007。在该模式落地前,对外的 `pi` 会在 `/session/new` 失败。

不在本方案里的事:实现 ACP HTTP 传输,宿主多实例路由,把 token 账和 overcast 对齐,给断开的 HTTP 补 `session/cancel`,在 M2 之前修改 TS 的协议行为,在本仓编译或安装 pi-rs。

## 信源

规范与协议:

- ACP v1 传输(stdio 稳定,Streamable HTTP 草案):https://agentclientprotocol.com/protocol/v1/transports
- ACP v1 概览:https://agentclientprotocol.com/protocol/v1/overview
- 初始化:https://agentclientprotocol.com/protocol/v1/initialization
- terminal:https://agentclientprotocol.com/protocol/v1/terminals
- 工具调用与 `request_permission`、`allow_always`:https://agentclientprotocol.com/protocol/tool-calls
- v1 schema 中的权限选项:https://agentclientprotocol.com/protocol/v1/schema
- Streamable HTTP / WebSocket RFD:https://agentclientprotocol.com/rfds/streamable-http-websocket-transport.md
- 官方库清单(无 Go):https://github.com/agentclientprotocol/agent-client-protocol
- 社区 Go SDK:https://github.com/coder/acp-go-sdk 与 https://pkg.go.dev/github.com/coder/acp-go-sdk

Go:

- 模块布局(`cmd` 与 `internal`):https://go.dev/doc/modules/layout
- `log/slog`:https://pkg.go.dev/log/slog
- `net/http` Server 超时(0 表示不设截止):https://pkg.go.dev/net/http#Server
- `crypto/subtle.ConstantTimeCompare`:https://pkg.go.dev/crypto/subtle#ConstantTimeCompare
- 模块校验和 `go.sum`:https://go.dev/ref/mod#authenticating
- `golang.org/x/time/rate`:https://pkg.go.dev/golang.org/x/time/rate
- zap:https://github.com/uber-go/zap
- zerolog:https://github.com/rs/zerolog
- lumberjack:https://github.com/natefinch/lumberjack 与 tag https://github.com/natefinch/lumberjack/releases/tag/v2.2.1

SSE:

- HTML 标准 `Last-Event-ID` 与事件流:https://html.spec.whatwg.org/multipage/server-sent-events.html
- MDN,冒号行是注释:https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events

本仓:

- `docs/research/S-0002-instance-rpc-acp.md`
- `docs/req/REQ-0002-acp-supervisor.md`
- `docs/items/tools-acp/acp.md`
- `docs/items/tools-agents/claude-code.md`(用量在网关侧)
- `docs/known-issues.md`(容器内信号 EPERM)
- `docs/params.md`(`GOLANG_VERSION` 1.27.1)
- `README.md`(仓库地址 `github.com/raystyle/pi-rs-runtime`,推送 `scripts/`)
- `AGENTS.md`(`incus file push scripts`)
- `scripts/acp/package.json`、`src/main.ts`(注册表第 43–46 行,bin 解析第 36–39 行)、`acpclient.ts`、`fsimpl.ts`
- `docs/research/S-0002-instance-rpc-acp.md` 第五节(pi 的 `--mode acp`、禁止连接 `--mode rpc`、一会话一子进程、空 `mcpServers`)
- pi-rs `packages/rs-agent/package.json` 的 bin 名 `pi-rs`;`packages/rs-agent/docs/cli.md` 当前 `--mode` 仅 `text`、`json`、`rpc`
- `scripts/lock/go/go.mod`(`module prewarm`,与本服务分开)
- `scripts/install-tools.sh` 的 `install_acp`
- `scripts/lib/common.sh`(`GOPROXY`、`GOLANG_VERSION`、`go_install_pin`)
- `scripts/lib/pins.sh`(由 resolve-pins 生成,勿手改)
- `scripts/resolve-pins.sh`(goproxy.cn 解析 go 模块)
- `/tmp/acpex-01/brief.md` 尾部「补充裁定」节

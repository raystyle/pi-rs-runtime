# pi-rs

> 自家 agent(pi-rs-core 产品仓的 rust harness agent)。ACP 原生后端,`--mode acp` 直连监督进程 ｜ 状态:已装 ｜ 组:`install-tools.sh agents`

## 版本

- common.sh 标量 `PI_RS_CORE_VERSION` = 0.4.0(pi-rs-core GitHub Release 锚);`PI_RS_SHA256` 是发行件 sha256 边车锚,换版本两值同改。
- CLI `--version` 与 ACP initialize 同源,均报真实版本(实测 wrapper 与裸 node、多 cwd 一致);0.4.0 起 `session/resume` 原生在(initialize 广告 `sessionCapabilities.resume:{}`,cwd fail-closed),经监督进程 `POST /session/resume` 横跨重启续接已验(旧会话文件名问答续答)。

## 来源与安装

- 发行件:`pi-rs-dist-<版本>-x86_64-unknown-linux-gnu.tar.gz`(pi-rs-core Releases;含 dist 全 bundle、acp-entry、vendor blob、rust-scripts)。
- 下载道三链:GITHUB_MIRROR 前置 → GitHub 直连 → 宿主预推 `/root/<件名>`(前两道不可达时,构建机 `gh release download` 后推入);sha256 校验不过即失败。
- 解包到 `/opt/pi-rs`(整包解:顶层 `package.json` 是版本 walk-up 命中点,bundle 运行时读它解析版本——只抽 dist/bundle 子树会回退 0.0.0,旧临时道的病根),入口 wrapper `/usr/local/bin/pi-rs`(exec `/opt/node/bin/node /opt/pi-rs/dist/bundle/cli.js`);`--help` 列 acp 是安装闸;脚本:`install-tools.sh` 的 `install_pi_rs`(agents 组尾部)。
- 本仓不编译 pi-rs。

## 文件

- 安装树是 `/opt/pi-rs/dist/`(bundle/cli.js 主入口、bundle/acp-entry.js 是 ACP 入口、vendor 与 rust-scripts 伴生);vendored zg 伴生库 `libzvec_c_api.so` 在 vendor 目录,RUNPATH `$ORIGIN` 自寻;入口是 `/usr/local/bin/pi-rs`。

## 配置

- 模型面(pi-rs-core 0.3.0 起):默认走 overcast 网关四模型(`PI_GATEWAY_BASE_URL` 未设即网关,默认别名 ds-cx-flash);凭证 env `DEEPSEEK_API_KEY` 任意非空即过(关鉴权期);走官方 API 设 `PI_GATEWAY_BASE_URL=off`。
- 监督进程注册表 pi 行:argv `/usr/local/bin/pi-rs --approve --mode acp`(`--approve` 统一信任项目本地件:无 UI 的 ACP 重启遇 pi install 扩展或 `.pi-rs/settings.json` 时不再静默不加载项目面),env 注 `DEEPSEEK_API_KEY`;就绪探针是 `--help` 含 acp。
- 不连 `--mode rpc`(那是另一套私有 JSONL,设计研究已否定)。

## 离线行为

- `--help` 读本地;ACP initialize 与 session/new 是 stdio 本地面;模型推理经网关,是运行期网络,不属于离线范围;未验证:断网下的全模式面。

## 限制

- 模型目录与别名以 pi-rs-core 侧锁定为准,本仓不代理。
- MVP 边界(pi-rs-core 实现):不做 session/load 族、HTTP/SSE MCP、音频、内嵌 resource、多 session 表、allow_always。

## 参见

- [claude-code.md](claude-code.md)
- [acp.md](../tools-acp/acp.md)

## rctl 收录行

- rctl: pi-rs kind=tool path=/usr/local/bin/pi-rs note=自家 agent,ACP 原生后端(--mode acp)

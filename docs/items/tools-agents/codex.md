# codex

> OpenAI Codex CLI。二进制已装。网关接线随镜像(config 三份),用户凭证不进镜像 ｜ 状态:已装 ｜ 组:`install-tools.sh agents`

## 版本

- pins.sh 标量 `CODEX_VERSION` = 0.162.1(解析日 2026-10-11);alpha 通道不锁定。

## 来源与安装

- npm 包是 `@openai/codex@<版本>`;经 npmmirror 全局装进 `/opt/node`;启动器以 `#!/usr/bin/env node` 开头;它再拉起平台二进制;该二进制是 `x86_64-unknown-linux-musl`,作为 linux-x64 可选依赖。
- 构建期的在线安装与 agents 组的其他件相同。见 [claude-code.md](claude-code.md)。
- 链接到 `/usr/local/bin/codex`。
- 网关接线在同一函数:共享模型目录装 `/etc/codex/models.json`(源文件 `scripts/data/codex-models.json`;含 `zp-cx-glm53`、`zp-cx-glm5t` 与 `ds-cx-pro`、`ds-cx-flash` 两别名,DeepSeek 窗按 128K 保守申报,只影响显示);config 三份写 `/root/.codex/`、`/home/ubuntu/.codex/` 与 `/etc/skel/.codex/`(均 0600,含网关令牌,关鉴权期占位 `overcast`)。

## 文件

- 二进制是 `/opt/node/bin/codex`;状态根是 `CODEX_HOME`,默认 `~/.codex`;该目录里有 `config.toml`;该目录里有 `auth.json`;`auth.json` 是明文,按密码保管,不进镜像;个人挂载面:宿主的 incus disk device 挂 `~/.codex`(`shift=true`,目录必须可写),整体覆盖烤库 config;共享模型目录是 `/etc/codex/models.json`,config 以绝对路径引用;刷新后的 token 写回挂载目录的 `auth.json`。

## 配置

- 烤库 config 内容:模型 `zp-cx-glm53`;提供商 `zai`(overcast;`base_url` 指网关 `/v1`;`experimental_bearer_token` 是网关令牌;`wire_api = "responses"`);`model_catalog_json` 指共享模型目录;推理力度 high;`forced_login_method = "api"` 免登录(`preferred_auth_method` 在 0.162.1 已不被识别,不写);`approval_policy = "never"` 与 `sandbox_mode = "danger-full-access"`(容器即沙箱,原生 yolo 无审批停顿);**顶层 `web_search = "disabled"`**(2026-10-15 修形:旧 `[tools.web_search] enabled = false` 是非法形状静默无效,工具仍随请求发,网关 Responses 面拒 `tools[N] unsupported` 硬断 exec;顶层键须在一切表头前;官方 config-reference 正形,grok 与 runtime 双独立实证)。
- **原生 yolo 阻塞边界**(grok 容器实证,board `2026-10-15-native-yolo`):`exec` 面零停顿,但 git 仓外须 `--skip-git-repo-check`(仓库检查,非信任);TUI 在 git 仓内未写信任会停 `Trust this folder?`:要开 TUI 的目录在 config 追加 `[projects."<绝对路径>"] trust_level = "trusted"`(无通配,镜像无法预置全路径);非 git 目录 TUI 直入 `permissions: YOLO mode`;`CODEX_HOME` 指向的目录必须已存在且属主对(ubuntu 面 1000:1000)。
- 网关 URL、模型与令牌的给法见 [claude-code.md](claude-code.md)(codex 侧模型变量是 `AGENT_CX_MODEL`);缺令牌重跑保留盘上配置。
- 个人面:设备码登录 `codex login --device-auth`(beta);或 `printenv CODEX_API_KEY | codex login --with-api-key`(`CODEX_API_KEY` 只对 `codex exec` 这类非交互进程成立);本机机器面(hooks 状态、项目信任表、状态行、插件市场)不进镜像。

## 离线行为

- 支持 `--version`。它读本地;支持 `login status`。它读本地;关闭 eth0 后,这两条命令读本地状态;未验证:登录、token 刷新、推理。这三项是运行期网络(推理经网关),不属于离线范围;运行期的 npm 升级同样被离线 npmrc 拦住。

## 限制

- musl 二进制跑在 glibc 容器上;npm 的 linux-x64 包就是这支 musl 二进制;安装后用 `codex --version` 确认;策略跟着有效 config 走(烤库三份,或挂载整体覆盖);挂载目录的属主不对时,先修 idmap;非特权容器需要 `shift=true`;网关令牌随镜像,撤销与轮换走网关侧。

## 参见

- [claude-code.md](claude-code.md)
- [acp.md](../tools-acp/acp.md)
- [offline.md](../../offline.md)

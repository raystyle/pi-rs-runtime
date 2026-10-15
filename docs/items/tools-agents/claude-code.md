# claude-code

> Anthropic Claude Code CLI。二进制已装。模型道经 overcast 网关,网关令牌随镜像,用户凭证不进镜像 ｜ 状态:已装 ｜ 组:`install-tools.sh agents`

## 版本

- pins.sh 标量 `CLAUDE_CODE_VERSION` = 2.1.296(解析日 2026-10-11)。
- 发版按天计算;latest 与 stable 大约相差一周;升级:修改锁定版本,再执行 agents 组;alpha 与 next 通道不锁定。

## 来源与安装

- npm 包是 `@anthropic-ai/claude-code@<版本>`;经 npmmirror 全局装进 `/opt/node`;linux-x64 原生包是可选依赖,必须安装;禁止 `--omit=optional`;构建期设置 `NPM_CONFIG_OFFLINE=false`,恢复在线安装;链接到 `/usr/local/bin/claude`;脚本:`scripts/install-tools.sh` 的 `install_agents`。
- 网关接线在同一函数尾段:写 managed settings 的 env,并产 codex 三份 config(见 [codex.md](codex.md))。

## 文件

- 二进制是 `/opt/node/bin/claude`;入口链接是 `/usr/local/bin/claude`;策略文件是 `/etc/claude-code/managed-settings.json`;该文件是组织级;网关 env 写在这份文件;`DISABLE_UPDATES=1`;关闭非必要流量;关闭遥测;用户文件不能覆盖这份策略;配置与凭证目录是 `~/.claude`;`CLAUDE_CONFIG_DIR` 可以改这个目录。

## 配置

- 网关部署已进镜像:managed settings 的 env 带 `ANTHROPIC_BASE_URL`(overcast 网关)、`ANTHROPIC_AUTH_TOKEN`(网关令牌)、模型映射(haiku 与子代理是 `zp-cc-glm53fh[1m]`,sonnet 与 opus 是 `zp-cc-glm53[1m]`)、`API_TIMEOUT_MS=3000000` 与自动压缩参数;它的优先级高于用户 token;实例不挂用户 OAuth;用量集中在网关侧。
- **原生 yolo 面**(用户令 2026-10-15:原生无阻塞交互;grok 容器实证,研究档案 board `2026-10-15-native-yolo`):策略层三键 `permissions.defaultMode = "bypassPermissions"`(TUI 与 `-p` 全覆盖,Bash 免 allow;项目/本地层无权授予 bypass)、`env.IS_SANDBOX = "1"`(根闸恰值,策略 env 在闸前注入;ubuntu 无此闸;`"true"` 不放行)、`skipDangerousModePermissionPrompt = true`(免危险模式免责框);`/etc/profile.d/claude-yolo.sh` 供登录壳;家目录 `.claude.json` 预置四键 `hasCompletedOnboarding`/`theme`/`bypassPermissionsModeAccepted`/`hasSeenAutoDefaultNudge`(TUI 首启零弹窗;2.1.296 无 `hasCompletedNonInteractiveOnboarding` 名,禁预置;已有文件只并键)。`-p` 面天然零弹窗且非交互会话直接视为已信任。禁写 `disableBypassPermissionsMode`。
- 网关 URL 与模型映射经环境变量覆盖(`AGENT_GATEWAY_URL`、`AGENT_CC_*`);令牌经 `AGENT_GATEWAY_TOKEN` 或令牌文件(默认 `/root/.agent-gateway-token`)给,消费后删除,不进仓库;网关关鉴权期统一用占位串 `overcast`(2026-10-13 起),鉴权重开时换真令牌重跑即可;缺令牌重跑时,盘上已有网关配置保留不覆盖。
- 个人凭证面:无头登录在有浏览器的机器执行 `claude setup-token`,再注入长效 token;`CLAUDE_CODE_OAUTH_TOKEN` 环境变量旧道保留;root 与 ubuntu 共用挂载时,设 `CLAUDE_CONFIG_DIR=/home/ubuntu/.claude`;挂载个人 `~/.claude` 覆盖用户层,压不过组织级策略。

## 离线行为

- 支持 `--version`;支持 `doctor`;这两条命令不开会话;关闭 eth0 后,`claude --version` 与 `claude doctor` 不开会话;未验证:交互会话;交互启动会检查更新;changelog 从 raw.githubusercontent 拉取;模型请求经网关,是运行期网络;OAuth 刷新是运行期网络;这两项不属于离线范围。
- 运行期 `npm install -g` 被 prefix npmrc 的 `offline=true` 拒绝。

## 限制

- 网关令牌写在镜像内策略文件,镜像即令牌载体;分发镜像等于分发令牌;撤销与轮换走网关侧。
- 容器没有浏览器;`/login` 的回调到不了容器;个人凭证走 token 注入,或挂载已经登录的目录;`DISABLE_AUTOUPDATER` 只停止后台检查;managed settings 的 `DISABLE_UPDATES` 连手动更新一起停;一个目录对应一个登录;切换账户时改 `CLAUDE_CONFIG_DIR`。

## 参见

- [codex.md](codex.md)
- [acp.md](../tools-acp/acp.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: claude kind=tool path=/usr/local/bin/claude note=claude-code CLI 入口名

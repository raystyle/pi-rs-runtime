# claude-code

> Anthropic Claude Code CLI。二进制已装。凭证经挂载注入,不进镜像 ｜ 状态:已装 ｜ 组:`install-tools.sh agents`

## 版本

- pins.sh 标量 `CLAUDE_CODE_VERSION` = 2.1.296(解析日 2026-10-11)。
- 发版按天计算;latest 与 stable 大约相差一周;升级:修改锁定版本,再执行 agents 组;alpha 与 next 通道不锁定。

## 来源与安装

- npm 包是 `@anthropic-ai/claude-code@<版本>`;经 npmmirror 全局装进 `/opt/node`;linux-x64 原生包是可选依赖,必须安装;禁止 `--omit=optional`;构建期设置 `NPM_CONFIG_OFFLINE=false`,恢复在线安装;链接到 `/usr/local/bin/claude`;脚本:`scripts/install-tools.sh` 的 `install_agents`。

## 文件

- 二进制是 `/opt/node/bin/claude`;入口链接是 `/usr/local/bin/claude`;策略文件是 `/etc/claude-code/managed-settings.json`;该文件是组织级;`DISABLE_UPDATES=1`;关闭非必要流量;关闭遥测;用户文件不能覆盖这份策略;配置与凭证目录是 `~/.claude`;`CLAUDE_CONFIG_DIR` 可以改这个目录;宿主用 incus disk device 挂入,`shift=true`;也可以用环境变量 `CLAUDE_CODE_OAUTH_TOKEN` 注入。

## 配置

- 凭证文件是 `~/.claude/.credentials.json`,权限 0600;无头登录:在有浏览器的机器执行 `claude setup-token`,再注入长效 token。
- root 与 ubuntu 共用挂载时,设 `CLAUDE_CONFIG_DIR=/home/ubuntu/.claude`。
- root 可以读取模式 0600 的文件;ubuntu 用户不能读取 root 家目录里模式 0600 的文件;不再把 `/root` 挂进来;自建 agent API 网关时,`ANTHROPIC_BASE_URL` 指向网关;`ANTHROPIC_AUTH_TOKEN` 写入网关令牌;managed settings 的 env 可以写在系统级,并随镜像保存;它的优先级高于用户 token;实例不挂用户 OAuth;用量集中在网关侧。

## 离线行为

- 支持 `--version`;支持 `doctor`;这两条命令不开会话;关闭 eth0 后,`claude --version` 与 `claude doctor` 不开会话;未验证:交互会话;交互启动会检查更新;changelog 从 raw.githubusercontent 拉取;模型请求是运行期网络;OAuth 刷新是运行期网络;这两项不属于离线范围。
- 运行期 `npm install -g` 被 prefix npmrc 的 `offline=true` 拒绝。

## 限制

- 容器没有浏览器;`/login` 的回调到不了容器;使用 token 注入,或挂载已经登录的目录;`DISABLE_AUTOUPDATER` 只停止后台检查;managed settings 的 `DISABLE_UPDATES` 连手动更新一起停;一个目录对应一个登录;切换账户时改 `CLAUDE_CONFIG_DIR`。

## 参见

- [codex.md](codex.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: claude kind=tool path=/usr/local/bin/claude note=claude-code CLI 入口名

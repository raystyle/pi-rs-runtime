# claude-code

> Anthropic Claude Code CLI(agent 挂载面之一)｜ 状态:已装(二进制;凭证经挂载注入,不进镜像)｜ 组:`install-tools.sh agents`

- **版本钉**:pins.sh 标量 `CLAUDE_CODE_VERSION`(当前 2.1.296,2026-10-11 解析;发版以天计,latest 与 stable 差约一周,升级=改钉重跑 agents 组;alpha/next 通道不钉)
- **来源与安装**:npm `@anthropic-ai/claude-code@<钉>` 经 npmmirror 全局装进 /opt/node(linux-x64 原生包是可选依赖,必须随装,禁 --omit=optional);构建期 `NPM_CONFIG_OFFLINE=false` 拿回在线面;链 /usr/local/bin/claude;装面 `scripts/install-tools.sh install_agents`
- **落点**:二进制 /opt/node/bin/claude(链 /usr/local/bin/claude);策略 /etc/claude-code/managed-settings.json(组织级,DISABLE_UPDATES=1+关非必要流量+关遥测,用户文件压不过);配置与凭证 `~/.claude`(`CLAUDE_CONFIG_DIR` 可换)由宿主侧 incus disk device 挂入(shift=true),或环境变量 `CLAUDE_CODE_OAUTH_TOKEN` 注入
- **配置与缓存**:凭证 ~/.claude/.credentials.json(0600);无头登录推荐在有浏览器的机器 `claude setup-token` 出长效 token 再注入;root 共用 ubuntu 挂载时设 CLAUDE_CONFIG_DIR=/home/ubuntu/.claude(root 可读 0600,反向不行),不重复挂 /root
- **离线行为**:边界型,`--version`/`doctor` 不开会话(断网冒烟面);交互启动查更新(changelog 拉 raw.githubusercontent)、模型请求、OAuth 刷新均为使用期触网,**不属离线承诺**;运行期 `npm install -g` 升级被 prefix npmrc offline=true 拦(设计)
- **坑与留痕**:容器无浏览器,/login 回调到不了,用 token 注入或挂已登录目录;DISABLE_AUTOUPDATER 只停后台检查,managed settings 的 DISABLE_UPDATES 连手动一起停(grok prt-04 实查文档);多账户一目录一登录(CLAUDE_CONFIG_DIR 切)


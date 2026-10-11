# codex

> OpenAI Codex CLI(agent 挂载面之一)｜ 状态:已装(二进制;凭证经挂载注入,不进镜像)｜ 组:`install-tools.sh agents`

- **版本钉**:pins.sh 标量 `CODEX_VERSION`(当前 0.162.1,2026-10-11 解析;alpha 通道不钉)
- **来源与安装**:npm `@openai/codex@<钉>` 经 npmmirror 全局装进 /opt/node;启动器 `#!/usr/bin/env node` spawn 平台二进制(x86_64-unknown-linux-musl 的 linux-x64 可选依赖);构建期在线面同 agents 组;链 /usr/local/bin/codex
- **落点**:二进制 /opt/node/bin/codex;状态根 `CODEX_HOME`(默认 ~/.codex):config.toml 与 auth.json(明文,按密码对待)都由宿主侧 incus disk device 挂入(shift=true;目录必须可写,刷新的 token 会写回 auth.json)
- **配置与缓存**:`cli_auth_credentials_store = "file"` 写进挂载的 config.toml(容器无钥匙串,auto 会落回 file,显式 file 可预测);无头登录:有浏览器的机器登录后拷 auth.json 进挂载目录,或 `codex login --device-auth`(设备码 beta),或 `printenv CODEX_API_KEY | codex login --with-api-key`;`CODEX_API_KEY` 只对 codex exec 类非交互进程成立
- **离线行为**:边界型,`--version`/`login status` 读本地(断网冒烟面);登录、token 刷新、推理均为使用期触网,不属离线承诺;运行期 npm 升级同被离线 npmrc 拦
- **坑与留痕**:musl 二进制跑在 glibc 容器上(npm 的 linux-x64 就是这支,装后 `codex --version` 实证即判);config.toml 不烤进镜像(策略随挂载走);凭证文件明文,挂载目录属主不对(非特权容器要 shift=true)时先修 idmap 再用


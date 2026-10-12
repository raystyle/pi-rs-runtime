# codex

> OpenAI Codex CLI。二进制已装。凭证经挂载注入,不进镜像 ｜ 状态:已装 ｜ 组:`install-tools.sh agents`

## 版本

- pins.sh 标量 `CODEX_VERSION` = 0.162.1(解析日 2026-10-11)。
- alpha 通道不锁定。

## 来源与安装

- npm 包是 `@openai/codex@<版本>`。
- 经 npmmirror 全局装进 `/opt/node`。
- 启动器以 `#!/usr/bin/env node` 开头。
- 它再拉起平台二进制。
- 该二进制是 `x86_64-unknown-linux-musl`,作为 linux-x64 可选依赖。
- 构建期的在线安装与 agents 组的其他件相同。见 [claude-code.md](claude-code.md)。
- 链接到 `/usr/local/bin/codex`。

## 文件

- 二进制是 `/opt/node/bin/codex`。
- 状态根是 `CODEX_HOME`,默认 `~/.codex`。
- 该目录里有 `config.toml`。
- 该目录里有 `auth.json`。
- `auth.json` 是明文,按密码保管。
- 这两份文件由宿主的 incus disk device 挂入。
- 挂载使用 `shift=true`。
- 目录必须可写。
- 刷新后的 token 写回 `auth.json`。

## 配置

- `config.toml` 写入 `cli_auth_credentials_store = "file"`。
- 容器没有钥匙串。
- 值是 auto 时,会回到 file。
- 写成 file 时,存放位置是确定的。
- 无头登录:在有浏览器的机器登录后,把 `auth.json` 拷进挂载目录。
- 或者执行 `codex login --device-auth`。这是设备码,处于 beta。
- 或者执行 `printenv CODEX_API_KEY | codex login --with-api-key`。
- `CODEX_API_KEY` 只对 `codex exec` 这一类非交互进程成立。
- 自建 agent API 网关时,`config.toml` 的 model_providers 设置 `base_url`。
- `env_key` 引用网关令牌的环境变量。
- 这两项随挂载的 `config.toml` 注入,或随实例环境变量注入。
- 实例不存放用户凭证文件。

## 离线行为

- 支持 `--version`。它读本地。
- 支持 `login status`。它读本地。
- 关闭 eth0 后,这两条命令读本地状态。
- 未验证:登录、token 刷新、推理。这三项是运行期网络,不属于离线范围。
- 运行期的 npm 升级同样被离线 npmrc 拦住。

## 限制

- musl 二进制跑在 glibc 容器上。
- npm 的 linux-x64 包就是这支 musl 二进制。
- 安装后用 `codex --version` 确认。
- `config.toml` 不写入镜像。
- 策略跟着挂载的文件走。
- 挂载目录的属主不对时,先修 idmap。
- 非特权容器需要 `shift=true`。

## 参见

- [claude-code.md](claude-code.md)
- [offline.md](../../offline.md)

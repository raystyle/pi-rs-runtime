# cloud:云厂商 CLI

> 云资产面 CLI:aliyun(阿里云)与 tccli(腾讯云)｜ 状态:已装 ｜ 组:`install-tools.sh cloud`

- **版本钉**:pins.sh 标量 `ALIYUN_CLI_VERSION`(当前 v3.5.1,2026-10-11 解析)与 `TCCLI_VERSION`(当前 3.1.180.1);升级跑 resolve-pins.sh 审 diff 后重跑本组
- **来源与安装**:aliyun 走 [aliyun/aliyun-cli](https://github.com/aliyun/aliyun-cli) release tar.gz(GitHub 道经 GITHUB_MIRROR,Go 静态单二进制);tccli 走 PyPI `uv tool install`(默认阿里云索引,tuna 兜底;UV_TOOL 面 shim 进 /usr/local/bin);装面 `scripts/install-tools.sh install_cloud`
- **落点**:aliyun `/usr/local/bin/aliyun`(实体);tccli shim `/usr/local/bin/tccli`,本体 `/opt/uv-tools/tccli`
- **配置与缓存**:凭证不进镜像:aliyun `~/.aliyun/config.json`(容器内 `aliyun configure --mode ...` 或挂载注入);tccli 走环境变量 `TENCENTCLOUD_SECRET_ID/SECRET_KEY/REGION`(非交互面);同 agents 批规定,使用期注入
- **离线行为**:过,`aliyun version` 与 `tccli --version` 断网可用(本地读);一切云 API 调用(枚举/查询)属使用期触网,断网失败是设计边界;与 pd 组 cloudlist/uncover 的云面互补
- **限制**:tccli 包体大(uv tool 独立 venv),PyPI 源偶发同步滞后时走 tuna 兜底;aliyun release 道无 sha256 边车,校验面依赖 GitHub 道完整性(known-issues 软钉同类)

- rctl: aliyun kind=tool path=/usr/local/bin/aliyun note=阿里云 CLI
- rctl: tccli kind=tool path=/usr/local/bin/tccli note=腾讯云 CLI(uv-tool 面)


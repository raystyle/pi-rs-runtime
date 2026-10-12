# cloud:云厂商 CLI

> 云资产面 CLI:aliyun(阿里云)与 tccli(腾讯云) ｜ 状态:已装 ｜ 组:`install-tools.sh cloud`

## 版本

- `ALIYUN_CLI_VERSION`(当前 v3.5.1,解析日 2026-10-11)。
- `TCCLI_VERSION`(当前 3.1.180.1)。
- 升级:运行 `scripts/resolve-pins.sh`,审阅差异后重跑本组。

## 来源与安装

- aliyun:[aliyun/aliyun-cli](https://github.com/aliyun/aliyun-cli) release tar.gz;GitHub 道经 GITHUB_MIRROR;Go 静态单二进制。
- tccli:PyPI `uv tool install`(默认阿里云索引,tuna 兜底);UV_TOOL 面 shim 进 /usr/local/bin。
- 脚本:`scripts/install-tools.sh` 的 `install_cloud`。

## 文件

| 路径 | 内容 |
| --- | --- |
| /usr/local/bin/aliyun | 实体二进制 |
| /usr/local/bin/tccli | shim;本体在 /opt/uv-tools/tccli |

## 配置

- 凭证不进镜像。aliyun:`~/.aliyun/config.json`(容器内 `aliyun configure --mode ...` 或挂载注入)。
- tccli:环境变量 `TENCENTCLOUD_SECRET_ID`、`TENCENTCLOUD_SECRET_KEY`、`TENCENTCLOUD_REGION`(非交互面)。
- 与 agents 批同规定:使用期注入。

## 离线行为

- 支持:`aliyun version` 与 `tccli --version` 断网可用(本地读)。
- 一切云 API 调用(枚举、查询)属使用期触网;断网失败是设计边界。
- 与 discovery 组 cloudlist、uncover 的云面互补。

## 限制

- tccli 包体大(uv tool 独立 venv);PyPI 源偶发同步滞后时走 tuna 兜底。
- aliyun release 道无 sha256 边车;校验面依赖 GitHub 道完整性(known-issues 软件源锁定同类)。

## 参见

- [docs/params.md](../../params.md)
- [known-issues.md](../../known-issues.md)

## rctl 面,机器行

- rctl: aliyun kind=tool path=/usr/local/bin/aliyun note=阿里云 CLI
- rctl: tccli kind=tool path=/usr/local/bin/tccli note=腾讯云 CLI(uv-tool 面)

# ClickHouse

> 列存分析引擎官方单二进制;本镜像规定:只用 `clickhouse local` 嵌入式直查本地文件 ｜ 状态:已装 ｜ 组:`install-runtimes.sh clickhouse`

## 版本

- 软件源锁定。官方安装脚本跟随最新稳定线。
- pins.sh 没有锁定项。见 [known-issues.md](../../known-issues.md)。
- 一次安装得到的版本是 26.10。

## 来源与安装

- 上游:[clickhouse.com](https://clickhouse.com)。
- 安装器:`curl -fsSL https://clickhouse.com/ | CLICKHOUSE_ONLY=1 sh`。直连,无镜像。
- `CLICKHOUSE_ONLY=1` 只产出 clickhouse 二进制,不附带 clickhousectl。
- 文件先落到 `/tmp`,再 `install -m755`。
- 脚本:`scripts/install-runtimes.sh` 的 `install_clickhouse`。

## 文件

- `/usr/local/bin/clickhouse` 是单二进制,含子命令 local、client、server 等。
- 没有 `clickhouse-local` 软链。
- 裸跑 `clickhouse` 即交互式 local。

## 配置

- 不起 server。
- 不写配置。

## 离线行为

- 未验证:`clickhouse local` 直查本地文件。它是嵌入式引擎,不访问网络。断网冒烟未单独覆盖本件。
- 构建期已用它把 PoC-in-GitHub 各年 JSON 灌成 `/opt/recon-ref/poc-index.parquet`。这一步属 recon 组,共 25988 条。
- 运行期查询面是 `poc-search --ch '<SQL>'`。
- 判定:关闭 eth0 后执行 `clickhouse local -q "SELECT count() FROM file('/opt/recon-ref/poc-index.parquet','Parquet')"`。

## 限制

- clickhouse.com 直连抖动时,下载失败只打印信息,不退出。
- 函数末尾以 `true` 兜底。该次执行不安装。再次执行该组时安装。
- 官方安装器没有单独的 clickhouse-local 命令名。写 `clickhouse-local` 软链是错的。
- 该规定写在脚本的 log 注释里。
- 用法示例见 [tools 安装面 poc-search 节](../../install-surfaces/tools.md)。

## 参见

- [known-issues.md](../../known-issues.md)
- [tools 安装面](../../install-surfaces/tools.md)

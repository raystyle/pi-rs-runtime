# ClickHouse

> 列存分析引擎官方单二进制;本镜像口径:只用 `clickhouse local` 嵌入式直查本地文件 ｜ 状态:已装 ｜ 组:`install-runtimes.sh clickhouse`

- **版本钉**:未钉——官方安装脚本构建期取最新;2026-10-09 轮实证装到 26.10([日记](../../diary/2026-10-09-review-rounds.md))
- **来源与安装**:[clickhouse.com](https://clickhouse.com) 官方安装器 `curl -fsSL https://clickhouse.com/ | CLICKHOUSE_ONLY=1 sh`(直连无镜像;`CLICKHOUSE_ONLY=1` 只产 clickhouse 二进制,不附带 clickhousectl),/tmp 落地后 `install -m755`(`scripts/install-runtimes.sh` `install_clickhouse`)
- **落点**:`/usr/local/bin/clickhouse`(单二进制,含 local/client/server 等子命令;**无 clickhouse-local 软链**,裸跑 `clickhouse` 即交互式 local)
- **配置与缓存**:无(不起 server、不写配置)
- **离线行为**:☐ [推断:]`clickhouse local` 是嵌入式引擎直查本地文件,不触网;构建期已用它把 PoC-in-GitHub 各年 JSON 灌成 `/opt/recon-ref/poc-index.parquet`(recon 组,25988 条),运行期 `poc-search --ch '<SQL>'` 是其查询面;断网冒烟未单独覆盖本件。验证:`ip link set eth0 down` 后 `clickhouse local -q "SELECT count() FROM file('/opt/recon-ref/poc-index.parquet','Parquet')"`
- **坑与留痕**:clickhouse.com 直连抖动时下载失败只 echo 不退出(函数末尾 `true` 兜底,下轮补装);官方安装器没有单独的 clickhouse-local 命令名——写 clickhouse-local 软链是错的,口径钉在脚本 log 注释;用法示例见 [tools 安装面 poc-search 节](../../install-surfaces/tools.md)

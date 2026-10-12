# ClickHouse

> 列存分析引擎官方单二进制;本镜像规定:只用 `clickhouse local` 嵌入式直查本地文件 ｜ 状态:已装 ｜ 组:`install-runtimes.sh clickhouse`

- **版本钉**:软钉,官方安装脚本设计即最新稳定线(pins.sh 无钉位, [known-issues](../../known-issues.md));2026-10-09 轮装到 26.10([日记](../../diary/2026-10-09-review-rounds.md))
- **来源与安装**:[clickhouse.com](https://clickhouse.com) 官方安装器 `curl -fsSL https://clickhouse.com/ | CLICKHOUSE_ONLY=1 sh`(直连无镜像;`CLICKHOUSE_ONLY=1` 只产 clickhouse 二进制,不附带 clickhousectl),/tmp 落地后 `install -m755`(`scripts/install-runtimes.sh` `install_clickhouse`)
- **落点**:`/usr/local/bin/clickhouse`(单二进制,含 local/client/server 等子命令;**无 clickhouse-local 软链**,裸跑 `clickhouse` 即交互式 local)
- **配置与缓存**:无(不起 server、不写配置)
- **离线行为**:未验 [推断:]`clickhouse local` 是嵌入式引擎直查本地文件,不触网;构建期已用它把 PoC-in-GitHub 各年 JSON 灌成 `/opt/recon-ref/poc-index.parquet`(recon 组,25988 条),运行期 `poc-search --ch '<SQL>'` 是其查询面;断网冒烟未单独覆盖本件。验证:`ip link set eth0 down` 后 `clickhouse local -q "SELECT count FROM file('/opt/recon-ref/poc-index.parquet','Parquet')"`
- **限制**:clickhouse.com 直连抖动时下载失败只 echo 不退出(函数末尾 `true` 兜底,本次不安装,再次执行该组时安装装);官方安装器没有单独的 clickhouse-local 命令名,写 clickhouse-local 软链是错的,规定钉在脚本 log 注释;用法示例见 [tools 安装面 poc-search 节](../../install-surfaces/tools.md)

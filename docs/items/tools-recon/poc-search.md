# poc-search

> PoC-in-GitHub 本地索引查询 wrapper(只查索引信息,不拉任何 PoC 代码) ｜ 状态:已装 ｜ 组:`install-tools.sh recon`

- **版本钉**:wrapper 随脚本 heredoc 生成、无独立版本;parquet 索引是构建期快照(2026-10-09 轮灌出 25988 条,重建后条数随上游仓变动)
- **来源与安装**:`scripts/install-tools.sh install_recon` 段 heredoc 写入 `/usr/local/bin/poc-search` + `chmod +x`;索引由 `clickhouse local` 把 PoC-in-GitHub `<年>/*.json`(每 CVE 一个多行美化 JSON)按 JSONAsObject 整读——每文件一行、单列 `json`——灌成单文件 parquet,构建条件:索引不在 + `have clickhouse` + 索引仓已克隆,失败提示 `poc-search --reindex` 重试
- **落点**:`/usr/local/bin/poc-search`(wrapper 真身);`/opt/recon-ref/poc-index.parquet`(离线索引);数据仓 `/opt/recon-ref/PoC-in-GitHub`(见 [recon 组册](recon.md))
- **配置与缓存**:无配置文件;环境变量 `POC_DIR`(默认 /opt/recon-ref/PoC-in-GitHub)、`POC_INDEX`(默认 /opt/recon-ref/poc-index.parquet)、`LIMIT`(默认 20)。四用法:`poc-search <CVE-ID>` 精确查(先 tr 大写化 + `CVE-<年4位>-<编号>` 格式校验,直取 `$POC_DIR/<年>/<CVE>.json`,不中找到 find 兜底,jq 美化打印);`poc-search -k <关键词>` 索引全文搜(`rg -il --glob '*.json'`,前 LIMIT 条,逐文件 `jq -c` 压缩打印、jq 失败 `head -c 400` 兜底);`poc-search --ch '<SQL>'` clickhouse local 查 parquet(`--multiquery`,视图名 `poc`、单列 `json`,取字段如 `JSONExtractString(json,'cve_id')`);`poc-search --reindex` 重建 parquet 索引并打印 count
- **离线行为**:☐ [推断:]四用法全读本盘 JSON/parquet,wrapper 无任何网络调用;PoC-in-GitHub 索引在 [离线机制 §1](../../offline.md) 登记为固化数据「直接读盘」,但断网查询动作未单列实证。验证:`ip link set eth0 down` 后 `poc-search CVE-2024-38077` 退 0 且 `poc-search --ch 'SELECT count() FROM poc'` 出条数
- **坑与留痕**:空命中文案坑——rg 无命中退 1,`set -euo pipefail` 下管道赋值会静默杀死脚本,故先 `|| true` 收名单再判空,输出「索引无命中: <词>」退 1(grok 评审 G3);索引无该 CVE 时文案「索引无 <CVE>(可在 https://github.com/nomi-sec/PoC-in-GitHub 核实)」退 1;无参打印用法退 0,未知选项打印用法退 1;索引仓 README 明示混有恶意样本,本 wrapper 只读索引不下载,下载执行是使用者自己的裁量(脚本注释裁定;留痕 [known-issues](../../known-issues.md))

# poc-search

> PoC-in-GitHub 本地索引查询 wrapper。只查索引信息,不拉任何 PoC 代码 ｜ 状态:已装 ｜ 组:`install-tools.sh recon`

## 版本

- wrapper 由脚本 heredoc 生成,没有独立版本。
- parquet 索引是构建期快照。
- 一次构建灌入 25988 条。
- 重建之后,条数随上游仓变动。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_recon`。
- heredoc 写入 `/usr/local/bin/poc-search`,再 `chmod +x`。
- 索引由 `clickhouse local` 读取 PoC-in-GitHub 的 `<年>/*.json`。
- 每个 CVE 对应一个多行、经过美化的 JSON 文件。
- 读取方式是 JSONAsObject,整文件读入。
- 每个文件一行,只有一列 `json`。
- 结果灌成单个 parquet 文件。
- 构建条件是索引不存在,并且 `have clickhouse`,并且索引仓已经克隆。
- 失败时提示执行 `poc-search --reindex` 重试。

## 文件

- `/usr/local/bin/poc-search` 是 wrapper,也是入口。
- `/opt/recon-ref/poc-index.parquet` 是离线索引。
- 数据仓是 `/opt/recon-ref/PoC-in-GitHub`。见 [recon.md](recon.md)。

## 配置

- 无配置文件。
- `POC_DIR` 默认 `/opt/recon-ref/PoC-in-GitHub`。
- `POC_INDEX` 默认 `/opt/recon-ref/poc-index.parquet`。
- `LIMIT` 默认 20。
- `poc-search <CVE-ID>` 做精确查询。
- 精确查询先用 `tr` 把输入转成大写。
- 格式必须是 `CVE-<年4位>-<编号>`。
- 命中时直接读 `$POC_DIR/<年>/<CVE>.json`。
- 该路径没有文件时,用 `find` 兜底。
- 输出用 `jq` 美化打印。
- `poc-search -k <关键词>` 对索引做全文搜索。
- 搜索命令是 `rg -il --glob '*.json'`。
- 只取前 `LIMIT` 条。
- 每个文件用 `jq -c` 压缩打印。
- `jq` 失败时,用 `head -c 400` 兜底。
- `poc-search --ch '<SQL>'` 用 `clickhouse local` 查 parquet。
- 该模式带 `--multiquery`。
- 视图名是 `poc`,只有一列 `json`。
- 取字段的例子是 `JSONExtractString(json,'cve_id')`。
- `poc-search --reindex` 重建 parquet 索引,并打印 count。

## 离线行为

- 未验证。
- 四种用法都只读本盘的 JSON 与 parquet。
- wrapper 没有任何网络调用。
- PoC-in-GitHub 索引在 [offline.md](../../offline.md) 登记为固化数据,直接读盘。
- 断网查询这一动作没有单独列入该登记。
- 关闭 eth0 后,`poc-search CVE-2024-38077` 退 0。
- 同时 `poc-search --ch 'SELECT count FROM poc'` 打出条数。

## 限制

- `rg` 无命中时退 1。
- 在 `set -euo pipefail` 下,把该结果赋给变量会结束脚本,并且没有单独的错误输出。
- 因此先 `|| true` 收下名单,再判断是否为空。
- 空命中时输出「索引无命中: <词>」,退 1。
- 索引没有该 CVE 时,输出「索引无 <CVE>(可在 https://github.com/nomi-sec/PoC-in-GitHub 核实)」,退 1。
- 无参数时打印用法,退 0。
- 未知选项时打印用法,退 1。
- 索引仓 README 写明混有恶意样本。
- 本 wrapper 只读索引,不下载。
- 下载并执行由使用者自行决定。见 [known-issues.md](../../known-issues.md)。

## 参见

- [recon.md](recon.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: poc-search kind=tool path=/usr/local/bin/poc-search env=工具环境 note=PoC 查询 wrapper(已装入口,非参考克隆)

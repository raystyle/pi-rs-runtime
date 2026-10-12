# rctl

> pi runtime 实例总 ctl。agent 的第一入口。渐进索引,全资源可搜:search、where、caps、show、env ｜ 状态:已装 ｜ 组:`install-tools.sh ctl`

## 版本

- 源码在仓内 `scripts/ctl/`;`package.json` 的 version 当前是 0.1.0;bun 的编译期锁定是 pins.sh 标量 `BUN_VERSION`,当前 1.4.3;`scripts/ctl/data/catalog.tsv` 是 `docs/items/` 的生成投影;生成命令是 `scripts/gen-rctl-catalog.sh`;`--check` 是漂移守卫,进门禁;投影禁止手改。

## 来源与安装

- 实现是仓内 TypeScript,用 bun 编译;`bun build --compile` 产出单文件二进制;没有 npm 依赖;脚本:`scripts/install-tools.sh` 的 `install_ctl`;版本闸要求 `bun` 等于 `BUN_VERSION`;通过后编译并安装到 `/usr/local/bin/rctl`;`catalog.tsv` 与 `caps.tsv` 烤进 `/var/lib/rctl/`;然后执行一次 `rctl index`,建立路径库。

## 文件

- 二进制是 `/usr/local/bin/rctl`;数据目录是 `/var/lib/rctl/`;其中有 `catalog.tsv`、`caps.tsv`、`paths.json`。
- 路径库的根是 `/opt`、`/usr/local/bin`、`/root/scripts`、`/usr/share/wordlists`。
- 剪枝 `node_modules`、`.git`、模块缓存、固化仓;深度限制是 3 层;索引的是资源树;词表正文不进内容索引。

## 配置

- 无配置文件;`RCTL_HOME` 可以指向数据目录;默认是 `/var/lib/rctl`;开发态回退到仓内 `data/`;没有常驻进程;没有 inotify。
- 词面打分如下。id、alias、desc、group 是子串命中。taskHint 来自能力词典。整句词袋命中是在 taskHint 之上再加。ids 的首位等于样例工具时再加。

| 位置 | 加分 |
| --- | --- |
| id | 10 |
| alias | 9 |
| desc | 6 |
| group | 3 |
| taskHint | 8 |
| 整句词袋 | 4 |
| ids 首位等于样例工具 | 2 |

- `caps.tsv` 的 task 列是中英同义词袋;词之间用空格分隔;多个查询词要全部命中,才算一条结果;金标回归是 `test/search.test.ts`;共 27 案;门禁是 recall@10;MRR 只作观察,不作门禁。
- 回归覆盖的查询有:票据、密码爆破、提权、横向移动、subdomain、tunnel、deserialization、wordlist、screenshot。
- zg 在位时接管 search 的排序。见 [zg.md](zg.md);zg 是 zvec-grep,向量与 fts 混排;自然语言按含义召回;引擎、模型与烤库见 [zg.md](zg.md);检索单元是一行一条微文档;字段是 id、desc、task、kind、alias;索引在构建期写一次,路径是 `/var/lib/rctl/semantic/`;一次查询大约 1.3 秒;zg 不在或失败时,回退到词面;`RCTL_ZG_PATH` 可以指向 zg,也可以禁用 zg;输出标注 `engine=zvec` 或 `engine=lexical`;人读的标注在最后一行;`--json` 的标注在 `meta.note`。

## 离线行为

- 支持。全部命令不访问网络;能力表与路径库都是本地烤库;env 只读 `/proc` 与配置文件;断网定义见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`rctl search`、`rctl where`、`rctl caps`、`rctl show`、`rctl env` 不访问网络。

## 限制

- 宿主的 grep 套了 ugrep 配置时,会吞掉 tsv 匹配;在宿主上核对 catalog 时用 awk;成员表蒸馏遇到编号表时,第一列是数字就改取第二列;缩进表按 pivot 册的方式处理;查能力用 search;查路径用 where;查册用 docs;这三件事不合成一个模糊框;退出码 1 表示没有命中;它不是错误;裸调用打开面板,退出码 0;面板给出下一步 CTA。

## 参见

- [zg.md](zg.md)
- [offline.md](../../offline.md)

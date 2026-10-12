# rctl

> pi runtime 实例总 ctl:agent 第一入口,渐进索引与全资源可搜(search/where/caps/show/env)｜ 状态:已装 ｜ 组:`install-tools.sh ctl`

- **版本钉**:仓内源码 `scripts/ctl/`(package.json version,当前 0.1.0);bun 编译期钉 `BUN_VERSION`(pins.sh 标量,当前 1.4.3);能力表 `scripts/ctl/data/catalog.tsv` 是 docs/items/ 的生成投影(`scripts/gen-rctl-catalog.sh`,--check 漂移守卫进门禁,投影禁手改)
- **来源与安装**:仓内 TypeScript + bun(`bun build --compile` 单文件二进制,零 npm 依赖);装面 `install-tools.sh install_ctl`:版本闸(bun == BUN_VERSION)后编译装 `/usr/local/bin/rctl`,烤库 catalog.tsv/caps.tsv 到 `/var/lib/rctl/`,并跑一次 `rctl index` 建路径库
- **落点**:二进制 `/usr/local/bin/rctl`;数据 `/var/lib/rctl/`(catalog.tsv、caps.tsv、paths.json);路径库根名单 /opt、/usr/local/bin、/root/scripts、/usr/share/wordlists,剪枝 node_modules/.git/模块缓存/固化仓,限深 3 层(资源树语义,词表正文不进内容索引)
- **配置与缓存**:无配置文件;`RCTL_HOME` 可指数据目录(默认 /var/lib/rctl,开发态回退仓内 data/);无常驻进程、无 inotify(S-0001 否决项)
- **离线行为**:过,全命令零网络(能力表与路径库都是本地烤库;env 面只读 /proc 与配置文件);断网见 REQ-0001 trace
- **search 评分与回归**:词面子串命中 id+10/alias+9/desc+6/group+3;能力词典 taskHint +8,整句词袋命中再 +4(ids 首位=样例工具再 +2;caps.tsv task 列是中英同义词袋,空格分隔);多词 AND 全命中才算结果;金标回归 `test/search.test.ts`(27 案 recall@10 门禁 + MRR 观察;2026-10-12 优化 MRR 0.502 到 0.944,九个零召回查询全清:票据/密码爆破/提权/横向移动/subdomain/tunnel/deserialization/wordlist/screenshot)
- **语义腿**:zg(zvec-grep,向量+fts 混排)在位时接管 search 排序,自然语言按含义召回(REQ-0005;引擎/模型/烤库见 [zg](zg.md) 册);检索单元=每行一微文档(id/desc/task/kind/alias),索引构建期一次落 /var/lib/rctl/semantic/,查询约 1.3 秒;zg 缺席或失败回退词面,RCTL_ZG_PATH 可显式指/禁;输出面 engine=zvec|lexical 标注(人读尾行与 --json meta.note)
- **限制**:宿主 grep(ugrep 皮)配置会吞 tsv 的匹配,宿主侧对 catalog 用 awk 验;成员表蒸馏吃编号表(第一列数字时取第二列)与缩进表(pivot 册);三问句三命令纪律(search 能力/where 路径/docs 册),别合成一个模糊框;退出码 1 是未命中不是错误;裸调用面板 exit 0 给下一步 CTA

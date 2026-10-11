# rctl

> pi runtime 实例总 ctl:agent 第一入口,渐进索引与全资源可搜(search/where/caps/show/env)｜ 状态:已装 ｜ 组:`install-tools.sh ctl`

- **版本钉**:仓内源码 `scripts/ctl/`(package.json version,当前 0.1.0);bun 编译期钉 `BUN_VERSION`(pins.sh 标量,当前 1.4.3);能力表 `scripts/ctl/data/catalog.tsv` 是 docs/items/ 的生成投影(`scripts/gen-rctl-catalog.sh`,--check 漂移守卫进门禁,投影禁手改)
- **来源与安装**:仓内 TypeScript + bun(`bun build --compile` 单文件二进制,零 npm 依赖);装面 `install-tools.sh install_ctl`:版本闸(bun == BUN_VERSION)后编译装 `/usr/local/bin/rctl`,烤库 catalog.tsv/caps.tsv 到 `/var/lib/rctl/`,并跑一次 `rctl index` 建路径库
- **落点**:二进制 `/usr/local/bin/rctl`;数据 `/var/lib/rctl/`(catalog.tsv、caps.tsv、paths.json);路径库根名单 /opt、/usr/local/bin、/root/scripts、/usr/share/wordlists,剪枝 node_modules/.git/模块缓存/固化仓,限深 3 层(资源树语义,词表正文不进内容索引)
- **配置与缓存**:无配置文件;`RCTL_HOME` 可指数据目录(默认 /var/lib/rctl,开发态回退仓内 data/);无常驻进程、无 inotify(S-0001 否决项)
- **离线行为**:过,全命令零网络(能力表与路径库都是本地烤库;env 面只读 /proc 与配置文件);断网实证见 REQ-0001 trace
- **坑与留痕**:宿主 grep(ugrep 皮)配置会吞 tsv 的匹配,宿主侧对 catalog 用 awk 验;成员表蒸馏吃编号表(第一列数字时取第二列)与缩进表(pivot 册);三问句三命令纪律(search 能力/where 路径/docs 册),别合成一个模糊框;退出码 1 是未命中不是错误;裸调用面板 exit 0 给下一步 CTA

# REQ-0001 实例总 ctl · rctl:agent 友好的渐进索引与全资源可搜

> 状态:implemented ｜ 提出:2026-10-11 ｜ 设计研究:[S-0001](../research/S-0001-agent-ctl.md) ｜ 裁定:[ADR-0008](../adr/ADR-0008-rctl-core-cli.md)

## 需求

R1 一个总 ctl 命令 `rctl` 进镜像成为核心 CLI,agent 进实例第一个入口;chrome/browse 未合入期不依赖其面
R2 渐进提示:裸调用出面板(实例态、分类计数、下一步 CTA),exit 0 不交互
R3 全资源可搜:能力问句(search,打能力表)、路径问句(where,打路径库)、册问句(docs,打册投影)三分离;exit 1 未命中
R4 单件全息:show <id> 给 kind、安装路径、版本锁定口径、组、离线行为、wrapper 关系、册链接(kubectl explain 语义)
R5 能力路由:caps [<task>] 给任务到资源组合与可抄命令模板(navi 语义,默认打印不执行)
R6 实例态:env 给离线态、端口面、PATH 面与五生态快失败面
R7 agent 原生面:--llms 120 行手册、七件旗标、json 信封(类型化 CTA)、错误 stderr 单行 JSON、退出码 0/1/2
R8 索引:构建期烤能力表(items/ 册投影,投影不双写)+ 镜像内路径库;无常驻进程、无 inotify(S-0001 第四节)
R9 零网络:全部命令断网可用
R10 载体:TypeScript + bun 开发,`bun build --compile` 产单文件二进制(用户裁定 2026-10-11;零 npm 依赖,断网可构建)

## trace:实现回填

- T1 scripts/ctl/ TS 工程:命令表单一真源,help/--llms/schema 自渲染,bun test 6/6(2026-10-11)
- T2 scripts/gen-rctl-catalog.sh:75 册蒸馏 274 件(册级+成员级,编号表第二列与缩进表都吃),--check 漂移守卫
- T3 scripts/ctl/data/caps.tsv 种子 17 条,caps ids 对 catalog 全命中(drift.test.ts 守卫)
- T4 install-tools.sh ctl 组:bun 版本闸(BUN_VERSION 1.4.3)后编译装 /usr/local/bin/rctl+烤库 /var/lib/rctl+rctl index 建路径库
- T5 容器实证 2026-10-11:断网(eth0 down)root/ubuntu 双视角,面板 274 件/17 条、search/caps/show/where(paths.json 命中 rockyou)/env(--json 信封,五生态快失败面与 listeners 实测准,::1 回环判定修两次字节序坑)
- T6 册 tools-ctl/rctl.md 已立;门禁接线:gen --check 与 bun test 进门禁(本批随提交)

## 验收判据

- R2-R7 各一条实测证据(断网);catalog 再生成零漂移(gen --check 过);漂移守卫测试进工程测试

# S-0001 实例总 ctl 命令(agent 友好:渐进索引与全资源可搜)设计研究

> 状态:draft ｜ 起草:2026-10-11 ｜ 信源:本仓 docs/items 74 册实测面、native-design 乙面标准、grok prt-03 先例研究(回执后补评注) ｜ 后续:REQ 立单再实现

## 一、问题

实例内资源面大而散:130+ CLI(含 11 个行为 wrapper)、/opt 下 50+ 资源树(SecLists、frida-server、trivy-db、nuclei 模板 14041 件、ghidra、rea provider、wheelhouse、五生态缓存、参考克隆 50+ 仓)、服务面(VNC/noVNC/CDP)、离线边界(五生态快失败)、件级事实册 74 册。agent 进实例后的发现成本是最大摩擦:不知道有什么、在哪、断网能不能用、入口名与册名不一致(certipy vs certipy-ad)、wrapper 背后有 env 接线。单件文档解决「这件是什么」,不解决「我现在该用什么」。

目标:一个总 ctl 命令(下称 pictl,名可裁),渐进索引提示所有资源,agent 能搜任意资源、按任务路由能力、稳定机读。

## 二、资源模型(七类)

| 类 | 例 | 可搜键 |
| --- | --- | --- |
| tool | CLI 二进制、wrapper(.real 真身)、uv-tool/go-tool 落点 | 名称、真身路径、组、版本钉 |
| data | SecLists、rockyou、frida-server、trivy-db、nuclei 模板、PoC 索引 | 路径、条目数、语义 tag(册投影) |
| cache | 五生态固化缓存、/opt/go/pkg/mod、wheelhouse | 生态、离线行为(锁消费路径) |
| service | VNC/noVNC/CDP 端口、vnc-screen 形态 | 端口、回环绑定、起停面 |
| capability | 「破解 hash」「逆向 ELF」「隧道出网」等任务到资源的路由 | 任务词、资源组合、CTA |
| doc | items/ 册投影(版本钉/落点/离线行为/坑) | 册 id、组、七节字段 |
| boundary | 五生态快失败、apt lists 空、宿主信号策略 | 边界语义、绕行说明 |

## 三、命令面草案

```text
pictl                    # 裸调用:渐进提示面板(实例态一行 + 分类计数 + 下一步 CTA),exit 0
pictl --llms [--json]    # 120 行紧凑手册(七件旗标、退出码、信封);manifest 版本注入
pictl index [--refresh]  # 索引建/增量刷新(L2 路径库跳变式增量;L3 语义层镜像固化),打印索引统计
pictl search <q> [--kind tool|data|cache|service|capability|doc|boundary] [--limit N]
                         # 能力问句:打 L3 能力表(id/tag/一句话/册描述);exit 1 未命中,CTA 给放宽建议
pictl where <path-q>     # 路径问句:打 L2 路径库(文件在哪,apt-file 语义)
pictl show <id>          # 单资源全息(kubectl explain 语义):kind、落点、版本钉、组、离线行为、wrapper 关系、册链接
pictl caps [<task>]      # 能力路由:无参列能力词典;带任务词给资源组合+命令示例+CTA
pictl env                # 实例状态:离线态、eth0、PATH 面、五生态快失败、JDK/node 面、端口面
pictl faces              # 服务面:端口监听与回环绑定、vnc 形态、CDP 态
pictl docs <册id|组>     # 册投影检索(投影不双写,真相仍在 docs/items/)
```

全局七件旗标(--filter-output、--format、--full-output、--help、--llms、--json、--schema)与 json 信封(ok/data/meta.cta)、错误 stderr 单行 JSON、退出码 0/1/2,全按 native-design 乙面,不另造。命令树面抄 gh(子命令树+每层 --help),资源目录面抄 kubectl(「有什么」与「这一项的字段」分两条命令)。

## 四、索引设计(渐进,三层)

> 2026-10-11 修订:吸收 grok prt-03 回执。fff(github.com/dmtrKovalenko/fff)定性为常驻内存文件表 + notify 监听(非 mtime 差量库、文件表不落盘、Linux 每目录一 watch),不宜当本镜像总 ctl(冷启动全树 walk、watch 配额、与 prt-01 信号策略叠加的常驻进程不可管理);第一版主路径是「构建时烤小册 + 路径库」,参照 updatedb「目录未变不重读」(plocate 系)。

| 层 | 面 | 建法 | 成本 | 新鲜度 |
| --- | --- | --- | --- | --- |
| L1 | PATH 与 wrapper 面 | 枚举 /usr/local/bin 与 PATH,解析软链与 .real 真身 | 亚秒 | 每次命令顺带重建 |
| L2 | 资源路径库 | 构建期烤库:根限定名单(/opt 资源树、/usr/local/bin、wrapper),剪枝词表正文/db/wheelhouse/构建缓存;运行期新增走下次调用时的跳变式增量(未变目录不重读) | 首次毫秒级查询 | 镜像发布时固化;增量按需 |
| L3 | 语义层(能力记录) | 构建期生成:items/ 册投影 + caps 词典 + wrapper 接线表,随镜像走;记录字段固定为 id、namespace/tags、一句话、落点、离线可用、下一步命令 | 构建期一次 | 镜像发布时固化(实例开发态重跑生成命令即刷) |

- 索引落点 `/var/lib/pictl/`(jsonl 或烤库,root 可写、ubuntu 可读);**无常驻进程、无 inotify 整树监听**(prt-01 信号策略下守护不可管理;镜像态资源 publish 时冻结,运行期只增少数工作文件,新鲜度便宜的做法是索引跟镜像走)
- **三种问句三条命令,不混一个模糊框**(apt-file 与 brew search 故意分开的先例):能力问句(caps/search 打 L3 能力表)、路径问句(where 打 L2 路径库)、内容 grep(只对件级文档与短 wrapper 开,不对 SecLists/nuclei 模板正文/trivy-db/wheelhouse/五生态缓存建内容索引,那些用 tag 与目录语义进 L3)
- 渐进提示:裸 pictl 与 search 未命中时的 CTA 面板即「渐进索引提示」呈现层:先给分类计数与热门词,agent 逐层下钻(llms 手册、search、show/caps)
- token 经济:search 默认 top N 带 id 与一句话,详情走 show;--full-output 与 --token-limit 三件可选扩展

## 五、能力路由(capability)设计要点

- 词典来源:items/ 册的用途句 + 组册成员表用途列,构建期蒸馏成 task 到资源的映射(不手维护第二份;漂移守卫锁覆盖)
- 词条形:`{task 词, tools[], data[], 边界注记, 示例命令[]}`;输出直接带类型化 CTA(命令可照抄)
- 语义资产带 tag:nuclei 模板 tag 面、capa 规则命名、SecLists 目录语义,进 L3 可搜

## 六、实现载体与治理对接

- 载体倾向:Rust 单二进制(镜像自带 rust 链;源码进本仓 `ctl/`(仓库只维护源与脚本,产物不入库,ADR-0001 口径),装机走 install-tools.sh 新组 `ctl`,钉版走 pins(CRATE_PIN 或仓内路径);bash+jq 形被否:能力路由与索引增量用 bash 维护成本失控
- 三面同源:help、--llms、schema 由命令树派生;漂移守卫(遍历命令树断言出现在 --llms)进仓库门禁
- 册是唯一真相:pictl docs 是投影,投影生成物可再生成,禁手改(文档即代码纪律)
- REQ 立单:实现前先 REQ 登记需求与 trace(doc-gov 状态机)

## 七、边界与风险

- 实例开发态资源会增,L2 mtime 增量覆盖;删减场景(资源卸载,如 chrome 下架)靠 --refresh 与 L1 顺带重建收口
- /root 0700:索引器以 root 建,ubuntu 只读消费;ubuntu 自建索引则 /root 面不可见,属实例访问模型固有限制(与 smoke 同款边界)
- 断网:索引与检索全程零网络(离线承诺面);caps 示例命令须全部离线可跑
- 宿主信号策略(prt-01):pictl 自身不依赖进程管理;faces 面对「stop 摘不掉进程」给边界注记不假装能停

## 八、先例矩阵(grok prt-03 回执已回填,2026-10-11)

| 主题 | 先例(链接见回执) | 可抄点 | 采纳态 |
| --- | --- | --- | --- |
| 渐进索引(fff 定位) | dmtrKovalenko/fff(常驻内存表+notify 监听;同名干扰:dylanaraps/fff 是 bash 文件管理器、EdgeOfAssembly/ffind 同型异名) | 不抄其常驻/监听形态;抄「先短索引再下钻」的查询分层;fff 留作「同一会话上百次搜同一小树」场景的后续候选 | 需改(不当总 ctl) |
| 发现通道 | llms.txt(llmstxt.org)、kubectl api-resources/explain 分离、gh 命令树、nix search 搜描述、apt-file/brew search 异键异索引 | --llms 短手册;「有什么」与「字段下钻」分命令;能力命中说明文字不命中文件名;路径问句与能力问句分开 | 可直接采纳 |
| 能力路由 | kubectl explain 点路径、navi cheat 标签+一句话+可执行模板(--print 不执行)、capa namespace 前缀/nuclei tags/SecLists 目录语义 | 词条=标签+一句话+命令模板;语义资产用自带 tag 面不扫正文;默认打印不执行 | 可直接采纳 |
| 索引工程 | 构建时烤小册(主路径)、plocate/updatedb 跳变式增量、fd/fzf 每次走查(仅交互用)、inotify 整树(否决:watch 配额) | L2 用烤库+未变目录跳过;内容索引只开件级文档与短 wrapper;SecLists/模板/db/缓存不进内容索引 | 可直接采纳 |
| 回执否决项对照 | 把 fff 装成总 ctl、/opt 开内容索引与 inotify、第一版就上 fff、三种问句混一个模糊框 | 本稿第四节修订已按否决项收口(分命令、烤小册、无常驻) | 不建议项均已避 |

回执对设计意图的三态意见与本稿逐节对照:全部「可直接采纳」项已吸收进第三、四、五节;「需改」「不建议」项见上表末行自查。

# REQ-0006 资源契约清单:单 JSON 数据模型

## 需求

所有资源做成契约清单数据模型,一个 JSON 维护(用户裁定 2026-10-12:「我们所有资源应该做成契约清单数据模型」「一个json维护」)。起因:单日两回重复实现(裁定项八件、HackTricks 文本面),根因是无单一机读清单可查,待办口径滞后于已实现。

## 决策草案

- **单元 = 拥有契约元数据的资源**:每资源一个对象,字段组即合同条款(id 谁是、kind 是什么、pin 钉在哪、path 落在哪、verify 怎么验、status 什么态)——违者守卫红,这就是「契约」的强制力。
- **单文件**:`scripts/ctl/data/resources.json` 为结构契约唯一真源(机读面);一份数组,每资源一个对象。
- **字段模型(v1 草案,按 catalog 现列扩)**:
  - `id`(唯一键)、`kind`(tool|data|cache|ref|service|compiler|runtime|model|source|lockface)
  - `pin`(钉:sha/version/URL+sha256,来源 pins.sh 语义)、`path`(落点;空则 `where` 语义,见 pathq-01 裁定)
  - `group`(安装组)、`status`(已装|已烘焙|参考克隆)、`env`(七域)、`alias`、`task`(能力词袋,caps 并入)
  - `book`(叙事册链接)、`verify`(断网验证判据句,冒烟/守卫消费)、`provenance`(来源叙事短句)
- **分层**:JSON=结构契约(增删改在这);册=叙事层(坑/离线行为/来源长文,按 id 双链);投影:catalog.tsv 与 caps.tsv 由 JSON 生成(rctl 热库可改直读 JSON,tsv 兼容期保留);漂移守卫双向:JSON↔册(id 引用一致)、JSON↔镜像(audit:声明皆在、在皆有声明)。
- **覆盖面**:镜像内资源(现 catalog 域)+ 构建期资产(烤库模型如 zg-models、源码克隆、锁面、数据快照)全量入模;~184 空 path 行随迁移补齐或按 pathq-01 裁定定型。
- **消费方**:rctl(search/show/audit 直读)、install 脚本(幂等判据引用 verify)、publish 门禁(清单完备性检查)、agent(一站式查资源)。

## 验收判据(草案)

1. resources.json 落地且覆盖现 catalog 494 件全量+构建期资产,JSON Schema 校验过( malformed 拒绝)。
2. catalog.tsv/caps.tsv 改为 JSON 投影生成,gen 守卫零漂移;册 id↔JSON id 双向对账守卫在。
3. audit 双向:JSON 声明资源在镜像全在;镜像 /opt+/usr/local/bin 资产未声明者列缺(闭集域外豁免表)。
4. 迁移一次性:旧 tsv 数据无丢失(diff 对账),rctl 查询行为不回退(金标回归 27+5 案全绿)。
5. 新增资源只改 JSON 一处,投影与守卫自动跟(演示一例)。

## trace

- 2026-10-12 立单(draft);pathq-01(空 path 定性)与 edb-01(exploitdb 副本)研究在办,回执吸收后字段面定稿。
- 2026-10-12 两笺吸收,字段面定稿:
  - **path 字段语义(pathq-01 裁定=混合)**:落点进 path 列,蒸馏读册表已有「入口/落点」列(文件形直取、目录形尾段 bin/sbin 拼单命令入口、无落点列走册落点节 apt /usr/bin 声明兜底、入口格多名或说明不猜留空);/usr/bin 不进路径库根名单(where 只答资源树,S-0001 L2 行已补写);实施已落地:gen 蒸馏升级,空 path 202 到 156(剩 156 属混格册,归本单迁移面补入口列)。容器实证 rctl show jq → path=/usr/bin/jq。
  - **pin 字段语义(edb-01 裁定)**:exploitdb 官方本尊在 GitLab(GitHub 2022 归档,副本一个 force-push 一个停更 17 月均不可钉);resolve-pins 增 GIT_SOURCE_URL 覆写表(非 GitHub 源完整 URL,不经镜像)——REQ-0006 的 pin 字段必须带源 URL 面(forge 无关),不能只按 GitHub 键名解析。顺手修 pypi 解析道(pypi.org 直连回 HTML 挑战页、tuna JSON 滞后,改 aliyun simple 排序),TCCLI 复原并升 3.1.181.1,全仓空钉清零。
  - HackTricks 文本面:2026-10-11 已裁定+实现,本日重复造轮自查抓获回滚;旧块潜伏 bug(--depth 1 克隆 checkout 不到非 HEAD 钉)修为 fetch sha 回退道,文本面重建 1095 篇 18M。

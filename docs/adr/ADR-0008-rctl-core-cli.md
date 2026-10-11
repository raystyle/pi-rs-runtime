# ADR-0008 rctl 为核心 CLI,TypeScript + bun 载体,源码进仓

> 状态:accepted ｜ 日期:2026-10-11 ｜ 关联:[REQ-0001](../req/REQ-0001-agent-ctl.md)、[S-0001](../research/S-0001-agent-ctl.md)、[ADR-0001](ADR-0001-image-artifacts-and-incremental-publish.md)

## Context

实例资源面大而散(130+ CLI、50+ /opt 资源树、服务面、离线边界、件级册 74 册),agent 发现成本高。设计研究(S-0001)定下渐进索引与三问句分离的总 ctl 形态。用户裁定:该 ctl 是项目核心 CLI,用 bun 开发;chrome/browse 仍在开发期不集成。

## Decision

1. `rctl` 是镜像核心 CLI:agent 进实例的第一入口,装 /usr/local/bin/rctl,install-tools.sh 新 `ctl` 组
2. 载体 TypeScript + bun:源码进仓 `ctl/`(仓库自此维护 yaml/脚本/文档之外多一类 ctl 源码;二进制产物不入库,同 ADR-0001 口径),`bun build --compile` 产单文件二进制,零 npm 依赖(断网可构建可复跑)
3. 能力表(items 册投影)由 `scripts/gen-rctl-catalog.sh` 在仓侧生成入库,`--check` 漂移守卫进门禁;册仍是件级唯一真相,投影可再生成不手改
4. 路径库在镜像内 install 期生成(/var/lib/rctl);无常驻进程、无 inotify(S-0001 第四节否决项)
5. chrome/browse 未合入期:rctl 不依赖其面;catalog 按册状态字段如实标(暂不装项可见但带状态)

## Consequences

- 仓内新增 ctl/ 与 scripts/ctl/ 两处;门禁链加 gen --check 与 crate 内三面同源测试
- bun 版本进运行时面依赖(镜像已烘焙);rctl 编译属构建期在线动作,运行期零网络
- 命令面是对外接口:旗标、信封、退出码变更视作接口变更(REQ 面登记)

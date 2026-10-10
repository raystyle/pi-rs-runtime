# ADR-0001 镜像产物不入库 + 增量发布链

状态:accepted(2026-10-08 立,多次实证)｜ 关联:README.md 步骤节、PROGRESS.md 发布链

## Context

镜像 17+ GB,git 不适合承载二进制产物;同时安装脚本幂等,全量重建 1.5 小时级,而增量改动只需几分钟验证。

## Decision

仓库只维护 yaml、脚本与文档。发布走增量链:从线上镜像 `incus launch` 开实例 → 推 scripts → 只跑改动组 → 验收(含断网冒烟)→ `incus publish --alias pi-rs-runtime`(先删旧别名)→ 删旧镜像与容器。全量链(distrobuilder 基础镜像 + install-all.sh)只在基础镜像或脚本大改后用。publish 前必跑 `clean-image.sh`(install-all.sh 末尾自动)。

## Consequences

- 镜像内容完全由脚本决定,手改容器不留痕即违例(验收时 diff 不出来)
- 增量组跑依赖幂等判据正确;早退组的配置写入必须放早退前(血泪:golang/uv 两犯)
- 发布链约 22 分钟是固定成本,小改动合并批次发布

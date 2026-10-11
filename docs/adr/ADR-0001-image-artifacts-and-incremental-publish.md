# ADR-0001 镜像产物不入库 + 增量发布链

状态:accepted(2026-10-08 立,多次实证)｜ 关联:README.md 步骤节、PROGRESS.md 发布链

## Context

镜像 17+ GB,git 不适合承载二进制产物;同时安装脚本幂等,全量重建 1.5 小时级,而增量改动只需几分钟验证。

## Decision

仓库只维护 yaml、脚本与文档。一批环境改动共用一个已解开的工作实例:改动进这个实例(推 scripts、只跑改动组、断网冒烟),不要为每笔改动再 `incus launch`。没有存活实例时才从线上镜像 launch 一次。这批改到稳定状态后先问用户,点头才 `incus publish` 一次(整盘 gzip,不是增量)→ 删旧镜像。全量链(distrobuilder 基础镜像 + install-all.sh)只在基础镜像或脚本大改后用。publish 前必跑 `clean-image.sh`(install-all.sh 末尾自动)。

名字用主机本地时间做版本,格式 `pi-rs-runtime-YYYYMMDD-HHMM`。实例名是 launch 时刻,新镜像别名是 publish 时刻,两个时间必须不同。浮动别名 `pi-rs-runtime` 只指向最新已发布镜像,供下一次 launch。禁止 `rt-*` 和 `-dev`。

## Consequences

- 镜像内容完全由脚本决定,手改容器不留痕即违例(验收时 diff 不出来)
- 增量组跑依赖幂等判据正确;早退组的配置写入必须放早退前(血泪:golang/uv 两犯)
- 发布链约 22 分钟是固定成本(launch 解包约 3.5 分钟 + publish 整盘 gzip 18–22 分钟),小改动合并到同一实例,稳定后问过用户再发一次
- 2026-10-10 用户裁定:后续改动都进当前工作实例,改完再打包;发不发仍问用户。实例已从 `rt-clean` 改名为 launch 时刻 `pi-rs-runtime-20261010-2210`(停机改名再启动,未解包未发布)。已发布镜像 `5e947cfcd98e` 的版本别名是打包时刻 `pi-rs-runtime-20261010-2201`,`pi-rs-runtime` 仍指向它

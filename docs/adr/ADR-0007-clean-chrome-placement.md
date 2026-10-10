# ADR-0007 clean-chrome 落位:系统级单副本

状态:accepted(2026-10-10,跨机派单 prt-01 裁定)｜ 关联:[items/tools-chrome/clean-chrome.md](../items/tools-chrome/clean-chrome.md)、tools-vnc/vnc

## Context

clean-chrome 经 browse 的云端安装道落运行用户 state 目录(`~/.browse-rs/chromium/<版本>/`,约 1.9 GB/版)。镜像服务 root + ubuntu 双视角;总台给三案取舍:单副本系统级 / 双用户各装 / 系统级部署 + BROWSE_CHROME 指路。同时 browse CLI 暂缓(仓不可达),安装语义需本仓复刻。

## Decision

系统级单副本:`/opt/clean-chrome/<版本>/`(root 755 可读不可写,双用户共用),wrapper `/usr/local/bin/clean-chrome`(恒 `--no-sandbox`,容器必需)压 PATH,`chrome`/`chromium` 同链;`/opt/clean-chrome/CURRENT` 记当前版。browse 合入后由它经 `BROWSE_CHROME` 指路到同一份,不双装。构建期经云端道直取(版本段路由+sha256 锚),不手搬本地产物。

## Consequences

- 镜像只 +1.9 GB(双用户方案要 +3.8 GB)
- ubuntu 可执行不可写;browse 合入后的版本升级路径是「新钉进 /opt/clean-chrome/<新版> + CURRENT 换指」
- 若 browse 的托管 pin 语义与 CURRENT 冲突,以 browse 为准再迁

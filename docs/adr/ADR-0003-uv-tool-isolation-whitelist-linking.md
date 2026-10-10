# ADR-0003 uv tool 隔离面 + venv 外链白名单

状态:accepted(2026-10-09 立;2026-10-10 grok 评审加固)｜ 关联:items/runtimes/uv、items/tools-red/*

## Context

Python 工具生态包互相抢依赖(impacket 叉、requests 版本),系统 python3 的 site-packages 一旦污染,apt 装的工具与逆向链全伤。uv tool 的 venv bin/ 目录不只装工具本体,还散落依赖 CLI(httpx/idna/normalizer/python3…),全目录软链曾把依赖 CLI 链到 /usr/local/bin 盖掉 pd 组 Go httpx 并劫持系统 python 成环(ELOOP)。

## Decision

- 用户裁定:不碰系统 python3;Python 工具一律 `uv tool` 隔离装(UV_TOOL_DIR=/opt/uv-tools,UV_TOOL_BIN_DIR=/usr/local/bin),或进 /opt/re-venv 研究环境
- venv 到 /usr/local/bin 的外链**必须白名单化**:只链工具本体入口与明确的依赖叉 *.py(如 bloodhound-ce 内 impacket 叉的 secretsdump.py),排除 python*/pip*/*activate*/*.bat;垃圾链一律清
- impacket 用 uv 上游版,不用 noble apt 冻结版(增量迁移自动卸 apt 版)

## Consequences

- 工具间依赖隔离,单件升级不传染
- 外链循环是复发高危区,新增 uv tool 件必须走白名单路径并断网实证 PATH 面
- bloodhound-python 等无 entrypoint 的包用 wrapper(python -m)而非硬链

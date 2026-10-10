# 逐件索引(docs/items/)

每件一册,模板见 [TEMPLATE.md](TEMPLATE.md)。目录按脚本分组:`compilers/`(install-compilers.sh)、`runtimes/`(install-runtimes.sh)、`libcache/`(install-libcache.sh)、`tools-<组>/`(install-tools.sh 各组)。

粒度规则:有独立版本钉/wrapper/缓存/离线行为/坑的件单独成册;同质批量件(apt 批、pd/secgo CLI 集、参考克隆批)由组册承载批量机制与成员表,成员不单独立册。

对账口径:各组索引表的成员数必须等于该组脚本实际安装/克隆件数;新增件时先加册再改计数。

(全量内容迁移中——各组完成度见下表)

| 脚本 | 组 | 册 | 状态 |
|---|---|---|---|
| install-compilers.sh | c / golang / rust / zig / nim / vcpkg | compilers/ | 迁移中 |
| install-runtimes.sh | node fnm bun uv python python2 duckdb clickhouse php mono dotnet pwsh sdkman | runtimes/ | 迁移中 |
| install-libcache.sh | go rust python node java pwsh dotnet zig | libcache/ | 迁移中 |
| install-tools.sh | fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz maldev recon nu pentest red msf | tools-<组>/ | 迁移中 |

返回 [docs 文档地图](../README.md)。

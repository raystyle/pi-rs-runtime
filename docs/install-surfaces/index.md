# 安装面清单(组卡导览)

> 逐件的版本钉/来源/落点/离线行为已移到 [items/](../items/README.md)(唯一真相);本册只留每个脚本组的安装机制与批量命令骨架,成员明细链 items 册。

## 分册

| 册 | 脚本 | 组 |
|---|---|---|
| [compilers.md](compilers.md) | install-compilers.sh | c golang rust zig nim vcpkg |
| [runtimes.md](runtimes.md) | install-runtimes.sh | node fnm bun uv python python2 duckdb clickhouse php mono dotnet pwsh sdkman |
| [tools.md](tools.md) | install-tools.sh | fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz maldev recon nu pentest red msf |

libcache 八生态(go rust python node java pwsh dotnet zig)的组机制直接见 [items/libcache/](../items/README.md#libcacheinstall-libcachesh8-册) 各册(缓存固化不产生安装面命令骨架之外的件)。

## 口径说明

- 组卡写「这批怎么装」:幂等判据、批量循环、容错与兜底;「每件是什么/在哪/断网如何」一律在 items 册。
- 版本钉变量集中在 `scripts/lib/common.sh`(参数表 [params.md](../params.md));镜像源口径同册。
- 改脚本行为时:先改脚本,再同步对应 items 册,组卡只在机制变化时动。

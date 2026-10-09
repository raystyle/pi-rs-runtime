# 安装面清单

本册按「脚本 → 组」分节列出三个分类脚本（外加库缓存脚本）的全部安装面。GitHub 网页上单文件过长，拆为编译器、运行时、工具三个分册，本页是索引。运行步骤见 [README](../../README.md)；参数取值见 [参数表](../params.md)；装完后的全景归档见 [软件清单](../software-inventory.md)。

## 分类与清单入口

三个分类脚本末尾各有 `*_ALL` 名单，`run_category` 校验入参；不传参数装全部，传入选项只装对应函数，未知项直接退出：

- `install-compilers.sh`:`COMPILERS_ALL=(c golang rust zig nim vcpkg)`
- `install-runtimes.sh`:`RUNTIMES_ALL=(node fnm bun uv python python2 duckdb clickhouse php mono dotnet pwsh sdkman)`
- `install-tools.sh`:`TOOLS_ALL=(fd astgrep cli herdr ghidra re pd secgo secrust pivot p0 c2 bof pz maldev recon nu pentest red)`
- `install-libcache.sh`:`LIBCACHE_ALL=(go rust python node java pwsh dotnet zig)`(八生态库缓存固化,独立分类)

## 分册

| 分册 | 内容 |
|------|------|
| [compilers.md](compilers.md) | 编译器 6 组:c、golang、rust、zig、nim、vcpkg |
| [runtimes.md](runtimes.md) | 运行时 13 组:node、fnm、bun、uv、python、python2、duckdb、clickhouse、php、mono、dotnet、pwsh、sdkman |
| [tools.md](tools.md) | 工具 19 组:fd、astgrep、cli、herdr、ghidra、re、pd、secgo、secrust、pivot、p0、c2、bof、pz、maldev、recon、nu、pentest、red |

## 口径说明

安装面事实（按代码）。各分册按「脚本 → 组」分节，每组一张三列小表（项目、版本、官方来源），表后 bash 代码块是脚本实际执行命令的摘录，`#` 注释标归属；省略 `have && skip` 幂等判断；`${变量}` 均为 `lib/common.sh` 的镜像源或版本钉，可用环境变量覆盖，取值见 [参数表](../params.md)。

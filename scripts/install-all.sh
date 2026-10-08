#!/usr/bin/env bash
# 全量入口:按 编译器 → 运行时 → 工具 顺序跑三个分类安装器
# 只装某一类或某几项时,直接调对应脚本:
#   ./install-compilers.sh [c|golang|rust|zig]
#   ./install-runtimes.sh  [node|fnm|bun|python|python2|uv|dotnet|pwsh|sdkman]
#   ./install-tools.sh     [fd|astgrep|cli|pd|secgo|secrust]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# 全量入口不转发过滤器:单项安装直接用对应分类脚本
bash "$HERE/install-compilers.sh"
bash "$HERE/install-runtimes.sh"
bash "$HERE/install-tools.sh"

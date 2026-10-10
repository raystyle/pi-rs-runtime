# 2026-10-08 基线构建与 fresh 验证

> 归档自 PROGRESS.md 历史节(文档解耦轮);当时的完整上下文以 git 历史为准。

## 里程碑

1. 基础镜像流水线:`image-defs/ubuntu.yaml`(distrobuilder,cloud 变体)+ `build-base-image.sh`,别名 `ubuntu-24.04-base`。
2. 分类脚本四件套:install-compilers(c/golang/rust/zig/nim/vcpkg)、install-runtimes(node/fnm/bun/uv/python/python2/duckdb/clickhouse/php/mono/dotnet/pwsh/sdkman)、install-libcache(八生态库缓存固化)、install-tools(20 组);install-all.sh 顺序串跑,前置批装 git 等隐式依赖并停掉自动升级计时器。
3. 评审吸收:grok 两份(八生态库清单+全平台编译矩阵)、claude 一份(环境体检)→ P0/P1 实施。
4. 共享缓存归 /opt 并 profile.d 导出(后被 ADR-0004 的非登录机制取代);家目录 .rustup/.cargo 兼容链。
5. pentest 组底线批、hashcat+pocl、frida 全链、nuclei 模板钉 /opt、词表、pwndbg gdbinit、时区上海+zh_CN。
6. red 组 AD 横向与 Web 批、库缓存八生态固化。
7. README 重写 + 三张安装面表 + 软件清单归档 12 分类。

## fresh 验证修复台账(17 坑,全部已修)

pipefail:`ls` 多 glob 缺操作数返回 2 致赋值退出(rust-lld、ghidra j21、nushell tag);`cmd | head` 类。set -e 语义:&& 链只有最后被执行的命令失败才退出(nuclei 模板循环 rmdir 案)。其他:cloud 镜像缺 git(unattended-upgrades 抢 dpkg 锁,前置批停计时器)、ast-grep 的 sg 与 shadow 撞名、cargo/rustup 旧布局假设($HOME/.cargo/env)、fnm 无 RUSTUP_HOME、p0 apt 批无容错(tuna 抖动)、api.github.com 限流 403(nushell/CyberChef 改 git ls-remote;duckdb 链兜底)、GitHub 直连间歇归零(nushell 重试)、ghauri 不在任何 PyPI(只发 git 仓)、bloodhound-python 无 entrypoint、CyberChef 资产名保留 v 前缀、kubectl 国内无镜像、三个克隆仓名错误(ticarpi/jwt_tool、GerbenJavado/LinkFinder、cddmp/enum4linux-ng)。

## 镜像源切换(实测后)

apt 阿里云;PyPI 阿里云;rustup/crates rsproxy.cn;maven 发行包阿里云;goproxy.cn 不动;npmmirror 不动;南大 golang/sury;华为 nuget/python2;tuna 仅 Adoptium。

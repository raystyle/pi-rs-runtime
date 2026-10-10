# 安装面清单 · 编译器(`install-compilers.sh`)

组卡只写机制;逐件事实(版本/来源/落点/离线/坑)在 [items/compilers/](../items/compilers/)。

## 组机制

- 逐组函数 `install_<组>`,幂等判据多为 `have <命令>` 或版本比对;**配置写入一律在早退判据之前**(复发坑,AGENTS.md Must)
- Go tarball 带 sha256 实时校验(golang.google.cn/dl JSON);rustup 走 rsproxy;nightly toolchain 由 bof 组按需装(coffee-ldr 用),不在 rust 组
- zig 发行包无国内镜像,直下无验签(known-issues);nim 走 choosenim init.sh;vcpkg `--depth 1` 克隆 + bootstrap
- 家目录兼容链:`~/.cargo`→/opt/cargo、`~/.rustup`→/opt/rustup、`~/.cache/cargo-zigbuild`→/opt/cargo-zigbuild-cache(piopt 共享可写,ADR-0005)
- rust 组 `/opt/cargo/config.toml`:crates 索引替换 + `[net] offline=true` 离线快失败默认(ADR-0004)

## 册索引

[c-toolchain(21 apt+FASM)](../items/compilers/c-toolchain.md) · [golang](../items/compilers/golang.md) · [rust](../items/compilers/rust.md) · [zig](../items/compilers/zig.md) · [nim](../items/compilers/nim.md) · [vcpkg](../items/compilers/vcpkg.md)

返回 [安装面清单](index.md)。

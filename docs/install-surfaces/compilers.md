# 安装面清单 · 编译器（`install-compilers.sh`）

组列中文名与脚本键对照：C 工具链=`c`、Go 语言工具链=`golang`、Rust 工具链=`rust`、Zig 编译器=`zig`、Nim 编译器=`nim`、C/C++ 包管理器=`vcpkg`。返回 [安装面清单索引](index.md)。

## C 工具链（`c`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| build-essential、clang、lldb、gdb、cmake、ninja-build、pkg-config、autoconf、automake、libtool、m4、clang-format、clang-tidy、valgrind、strace、ltrace、ccache、musl-tools、zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | Ubuntu noble 源（tuna） |
| FASM | 1.73.32（`FASM_VERSION`） | [flatassembler.net](https://flatassembler.net) |

```bash
# build-essential 等 21 包
apt-get install -y --no-install-recommends build-essential clang lldb gdb cmake ninja-build pkg-config autoconf automake libtool m4 clang-format clang-tidy valgrind strace ltrace ccache musl-tools zlib1g-dev libssl-dev libffi-dev
# FASM:解到 /opt/fasm 并链接
curl -fSL https://flatassembler.net/fasm-${FASM_VERSION}.tgz
ln -sf /opt/fasm/fasm/fasm.x64 /usr/local/bin/fasm
```

## Go 语言工具链（`golang`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| Go 工具链 | 1.27.1（`GOLANG_VERSION`） | [go.dev/dl](https://go.dev/dl/)（发行包经南大镜像 `GO_DOWNLOAD`） |
| dlv、gopls、golangci-lint | `@latest` 未钉 | [go-delve/delve](https://github.com/go-delve/delve)、golang.org/x-tools、[golangci/golangci-lint](https://github.com/golangci/golangci-lint) |
| 跳板/代理库预热（goproxy、smux、yamux、quic-go、net/proxy、go-socks5 等 6 库） | `go mod tidy` 取最新 | 各库官方仓（经 `GOPROXY`） |

```bash
# Go 工具链:sha256 取 https://golang.google.cn/dl/?mode=json 校验
curl -fSL ${GO_DOWNLOAD}/go1.27.1.linux-amd64.tar.gz
tar -C /usr/local -xzf
go env -w GOPROXY=${GOPROXY} GOSUMDB=${GOSUMDB}
# dlv、gopls、golangci-lint:装完链到 /usr/local/bin
go install github.com/go-delve/delve/cmd/dlv@latest
go install golang.org/x/tools/gopls@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
# 跳板/代理库预热:临时 module 写依赖后执行,进模块缓存
GOFLAGS=-mod=mod go mod tidy && go build ./...
```

## Rust 工具链（`rust`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| rustup、stable toolchain | 随源最新 | [rustup.rs](https://rustup.rs)（经 tuna `RUSTUP_UPDATE_ROOT`） |
| llvm-tools、rustfmt、clippy、rust-analyzer | 随工具链 | [rust-lang.org](https://www.rust-lang.org)（经 tuna） |
| nightly toolchain | 随源最新 | rust-lang.org（经 tuna） |
| rust-script、cargo-zigbuild、cargo-audit | cargo 未钉 | [rust-lang/rust-script](https://github.com/rust-lang/rust-script)、[rust-cross/cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)、[rustsec/rustsec](https://github.com/rustsec/rustsec)（cargo-audit） |
| 件 crate 生态预热（ureq、tokio、rustls、regex 等 29 个） | `cargo fetch` 取最新 | crates.io（经 tuna sparse） |

```bash
# rustup、stable toolchain:RUSTUP_HOME=/opt/rustup、CARGO_HOME=/opt/cargo
curl -fSL ${RUSTUP_UPDATE_ROOT}/dist/x86_64-unknown-linux-gnu/rustup-init
./rustup-init -y --default-toolchain stable --profile minimal
# llvm-tools、rustfmt、clippy、rust-analyzer:rust-lld 链到 /usr/local/bin
rustup component add llvm-tools rustfmt clippy rust-analyzer
# nightly toolchain:BOF 组 coffee-ldr 构建用
rustup toolchain install nightly --profile minimal
# rust-script、cargo-zigbuild、cargo-audit:crates 索引指 tuna sparse
cargo install rust-script --locked
cargo install cargo-zigbuild --locked
cargo install cargo-audit --locked
# 件 crate 生态预热:临时 crate 写 Cargo.toml 依赖后执行,进 registry 缓存
cargo fetch --quiet
```

## Zig 编译器（`zig`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| zig | 0.16.0（`ZIG_VERSION`）；0.15.2 副本供 BOF 工具链 | [ziglang.org/download](https://ziglang.org/download/) |

```bash
# zig
curl -fSL https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz
tar -C /opt/zig -xJf --strip-components=1
ln -sf /opt/zig/zig /usr/local/bin/zig
```

## Nim 编译器（`nim`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| choosenim、nim stable 工具链 | 安装器最新；stable 随安装日 | [nim-lang.org](https://nim-lang.org)（[choosenim](https://github.com/nim-lang/choosenim) 官方安装器；noble apt 的 nim 停 1.6.x 过旧不取） |

```bash
# nim:CHOOSENIM_DIR=/opt/nim;最新工具链 bin 整批链 /usr/local/bin;profile.d 写 PATH
curl -fsSL https://nim-lang.org/choosenim/init.sh | sh -s -- -y
ln -sf /opt/nim/toolchains/nim-*/bin/* /usr/local/bin/
```

## C/C++ 包管理器（`vcpkg`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| vcpkg 本体与 12 库（`VCPKG_PKGS`） | `--depth 1` 未钉 | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) |

```bash
# vcpkg 本体与 12 库
apt-get install flex bison
git clone --depth 1 https://github.com/microsoft/vcpkg /opt/vcpkg
./bootstrap-vcpkg.sh -disableMetrics
vcpkg install openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara
```

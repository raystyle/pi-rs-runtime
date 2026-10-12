# C 工具链

> C/C++ 编译、调试与逆向行为分析全家桶(21 个 apt 包)+ FASM 汇编器 ｜ 状态:已装 ｜ 组:`install-compilers.sh c`

## 版本

- 21 个 apt 包走 noble 随源,安装带 `--no-install-recommends`,版本随镜像源快照。
- FASM 锁定 `FASM_VERSION=1.73.32`(`install_c` 内默认值,环境变量可覆盖)。
- FASM 官方 tarball 直下,无校验和。

## 来源与安装

- apt 批走 Ubuntu noble 源。镜像是阿里云,由 `image-defs/ubuntu.yaml` 写入。
- FASM 在 Ubuntu 源没有。
- FASM 从 [flatassembler.net](https://flatassembler.net) 取 `fasm-${FASM_VERSION}.tgz`,直下解到 `/opt/fasm`。
- 脚本:`scripts/install-compilers.sh` 的 `install_c`。

## 文件

- apt 件归 dpkg 标准面(`/usr/bin` 等)。入口名即包内命令;FASM 被包装的程序是 `/opt/fasm/fasm/fasm.x64`;`/usr/local/bin/fasm` 软链指向 `fasm.x64`;`fasm.x64` 不存在时,该软链回退指向 32 位 `fasm`。

## 配置

- 本组不写任何配置文件;ccache 用各用户默认 `~/.cache/ccache`,未固化进 `/opt`。

## 离线行为

- 支持:编译器版本面。关闭 eth0 后,`gcc --version && clang --version && fasm -v` 可读出版本。记录见 [offline.md](../../offline.md) 验证节。
- 未验证:实际编译链接,含 musl 静态链与 FASM 汇编。二进制、头文件与库全在本地盘,无网络调用。
- 支持:离线 `apt install` 新件立即失败。`/var/lib/apt/lists` 已清。边界见 [offline.md](../../offline.md)。

## 限制

- FASM 包内顶层是 `fasm/` 目录;amd64 必须链 `fasm.x64`。包内 `fasm` 是 32 位。
- nasm 不在本组。它归 `install-tools.sh` 的 `install_analysis`,按锁定版本从源码构建(脚本注释规定)。
- apt 批天然幂等;FASM 靠 `have fasm` 早退;组内无配置写入,不触「配置写入放早退前」。

## 参见

- [offline.md](../../offline.md)

## rctl 收录行

- rctl: fasm kind=compiler path=/opt/fasm note=FASM 汇编器本体
- rctl: aarch64-linux-gnu-g++-13 kind=compiler path=/usr/bin/aarch64-linux-gnu-g++-13 note=arm64 交叉链(静态编译)
- rctl: arm-linux-gnueabihf-g++-13 kind=compiler path=/usr/bin/arm-linux-gnueabihf-g++-13 note=armhf 交叉链
- rctl: mipsel-linux-gnu-g++-13 kind=compiler path=/usr/bin/mipsel-linux-gnu-g++-13 note=mips 小端交叉链(IoT/路由)
- rctl: mips-linux-gnu-g++-13 kind=compiler path=/usr/bin/mips-linux-gnu-g++-13 note=mips 大端交叉链

## 成员清单

21 个 apt 包 + FASM。

| 件 | 版本 | 用途 |
|---|---|---|
| build-essential | noble 随源 | 元包,带入 gcc/g++/make/dpkg-dev |
| clang、lldb | noble 随源 | LLVM 编译器与调试器 |
| gdb | noble 随源 | GNU 调试器 |
| cmake、ninja-build、pkg-config | noble 随源 | 构建系统、构建器、库探测 |
| autoconf、automake、libtool、m4 | noble 随源 | autotools 链 |
| clang-format、clang-tidy | noble 随源 | 格式化与静态检查 |
| valgrind、strace、ltrace | noble 随源 | 逆向与行为分析常规件(脚本注释规定) |
| ccache | noble 随源 | 编译缓存 |
| musl-tools | noble 随源 | musl 静态链接(`musl-gcc`) |
| zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | 压缩/TLS/FFI 开发头 |
| FASM | 1.73.32(`FASM_VERSION`) | flat 汇编器,Ubuntu 源无包,官方 tarball 直下 |

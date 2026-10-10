# C 工具链

> C/C++ 编译、调试与逆向行为分析全家桶(21 个 apt 包)+ FASM 汇编器 ｜ 状态:已装 ｜ 组:`install-compilers.sh c`

- **版本钉**:21 个 apt 包 noble 随源(`--no-install-recommends`,版本随镜像源快照);FASM `FASM_VERSION=1.73.32`(`install_c` 内默认值,env 可覆盖),官方 tarball 直下、无校验和
- **来源与安装**:apt 批走 Ubuntu noble 源(阿里云镜像,`image-defs/ubuntu.yaml` 钉入);FASM 在 Ubuntu 源没有,[flatassembler.net](https://flatassembler.net) 的 `fasm-${FASM_VERSION}.tgz` 直下解 `/opt/fasm`。脚本面:`scripts/install-compilers.sh` `install_c`

成员表(21 包 + FASM):

| 件 | 版本钉 | 用途 |
|---|---|---|
| build-essential | noble 随源 | 元包,带入 gcc/g++/make/dpkg-dev |
| clang、lldb | noble 随源 | LLVM 编译器与调试器 |
| gdb | noble 随源 | GNU 调试器 |
| cmake、ninja-build、pkg-config | noble 随源 | 构建系统、构建器、库探测 |
| autoconf、automake、libtool、m4 | noble 随源 | autotools 链 |
| clang-format、clang-tidy | noble 随源 | 格式化与静态检查 |
| valgrind、strace、ltrace | noble 随源 | 逆向与行为分析常规件(脚本注释口径) |
| ccache | noble 随源 | 编译缓存 |
| musl-tools | noble 随源 | musl 静态链接(`musl-gcc`) |
| zlib1g-dev、libssl-dev、libffi-dev | noble 随源 | 压缩/TLS/FFI 开发头 |
| FASM | 1.73.32(`FASM_VERSION`) | flat 汇编器,Ubuntu 源无包,官方 tarball 直下 |

- **落点**(批量机制):apt 件归 dpkg 标准面(`/usr/bin` 等,入口名即包内命令);FASM 真身 `/opt/fasm/fasm/fasm.x64`,`/usr/local/bin/fasm` 软链(fasm.x64 不存在时回退链 32 位 `fasm`)
- **配置与缓存**:无(本组不写任何配置文件;ccache 用各用户默认 `~/.cache/ccache`,未固化进 /opt)
- **离线行为**:✅ 断网冒烟覆盖编译器版本面(78/0,口径见 [离线面验证节](../../offline.md))。验证:`ip link set eth0 down` 后 `gcc --version && clang --version && fasm -v`。实际编译链接(含 musl 静态链、FASM 汇编)断网实做 ☐ [推断:二进制、头文件与库全在本地盘,无网络调用];`apt install` 新件离线快失败(`/var/lib/apt/lists` 已清,属设计,见 [offline.md 边界节](../../offline.md))
- **坑与留痕**:FASM 包内顶层是 `fasm/` 目录,amd64 必须链 `fasm.x64`(包内 `fasm` 是 32 位);nasm 不在本组,归 install-tools.sh p0 组源码钉版(脚本注释口径);幂等:apt 批天然幂等,FASM 靠 `have fasm` 早退——组内无配置写入,不触「早退前写配置」纪律

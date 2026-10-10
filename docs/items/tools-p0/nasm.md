# nasm(含 ndisasm)

> x86/x64 汇编器与反汇编器 ｜ 状态:已装 ｜ 组:`install-tools.sh p0`

- **版本钉**:3.02(默认值写在 `install_p0` 内,不在 common.sh;`NASM_VERSION` 环境变量可覆盖);幂等判据 `nasm -v | grep -q "version 3.02$"`——当前版本与钉版一致才跳过,改 NASM_VERSION 即触发重装(幂等+可升级,脚本注释);tarball 无校验和,官网直下
- **来源与安装**:[nasm.us](https://www.nasm.us/) releasebuilds 源码 tar.xz(`https://www.nasm.us/pub/nasm/releasebuilds/3.02/nasm-3.02.tar.xz`;无国内镜像,包小直连)→ `./configure --prefix=/usr/local && make -j$(nproc) && make install`;`install-tools.sh p0` 段。不走 apt:noble apt 版停在 2.16.01(脚本注释)
- **落点**:`make install` 落 /usr/local/bin/nasm 与 /usr/local/bin/ndisasm
- **配置与缓存**:无
- **离线行为**:☐ [推断:] 纯本地汇编器,运行期无网络依赖;未进归档断网冒烟逐件明细。建议验证:`ip link set eth0 down` 后 `printf 'bits 64\nsection .text\nnop\n' > /tmp/n.asm && nasm -f elf64 /tmp/n.asm -o /tmp/n.o` 退 0
- **坑与留痕**:[known-issues](../../known-issues.md) 口径「nasm 另有 sha256 校验」与脚本不符——当前安装段无校验步骤,以脚本为准(直下不校验),留痕待改文档或补校验;组册见 [p0.md](p0.md)

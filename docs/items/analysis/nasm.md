# nasm

> x86/x64 汇编器与反汇编器,含 ndisasm ｜ 状态:已装 ｜ 组:`install-tools.sh analysis`

## 版本

- 版本 3.02。
- 默认值写在 `install_analysis` 内,不在 common.sh。
- 环境变量 `NASM_VERSION` 可覆盖。
- 幂等判据:`nasm -v | grep -q "version 3.02$"`。
- 当前版本与锁定版本一致才跳过。改 `NASM_VERSION` 会触发重装。
- tarball 无校验和。
- 从官网直接下载。无国内镜像。包小,直连。

## 来源与安装

- 上游:[nasm.us](https://www.nasm.us/) releasebuilds。
- URL:`https://www.nasm.us/pub/nasm/releasebuilds/3.02/nasm-3.02.tar.xz`。
- 脚本:`install-tools.sh` 的 `install_analysis`。
- 构建:`./configure --prefix=/usr/local && make -j$(nproc) && make install`。
- 不使用 apt 包。noble 的 apt 版停在 2.16.01。

## 文件

| 路径 | 内容 |
| --- | --- |
| /usr/local/bin/nasm | `make install` 写入的汇编器 |
| /usr/local/bin/ndisasm | `make install` 写入的反汇编器 |

## 配置

- 无。

## 离线行为

- 未验证。
- 运行期无网络依赖。
- 关闭 eth0 后,`printf 'bits 64\nsection .text\nnop\n' > /tmp/n.asm && nasm -f elf64 /tmp/n.asm -o /tmp/n.o` 退出码 0 为判定命令。

## 限制

- [known-issues.md](../../known-issues.md) 写 nasm 另有 sha256 校验。
- 当前安装段没有校验步骤。
- 以脚本为准:直接下载,不校验。

## 参见

- [analysis.md](analysis.md)
- [known-issues.md](../../known-issues.md)
- [offline.md](../../offline.md)

## rctl 面,机器行

- rctl: nasm kind=tool path=/usr/local/bin/nasm
- rctl: ndisasm kind=tool path=/usr/local/bin/ndisasm note=反汇编面

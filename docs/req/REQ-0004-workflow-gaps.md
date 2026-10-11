# REQ-0004 工作流驱动补缺(交叉编译链/stego/web 泄漏/反序列化/SSTI/mobile)

> 状态:implemented ｜ 提出:2026-10-11 ｜ 研究:grok prt-10(八项裁定+kill-chain×品类矩阵+交叉链细化) ｜ 前置:REQ-0003

## 需求

R1 交叉编译链:四套 g++-13(arm64/armhf/mips/mipsel,不装 crossbuild 元包)+ i386(libc6-dev-i386 头道;实证坑:gcc-multilib 与 cross 包打包互斥)
R2 stego 面:stegseek 0.6(release deb+sha256 钉,libmhash2/libmcrypt4/libjpeg62 依赖)、outguess(apt)、zsteg 0.2.14(gem)
R3 web 泄漏/生成器:phpggc(clone,wrapper 写死 php8.3)、git-dumper 1.0.9(uv tool)
R4 SSTI:SSTImap(独立 /opt/sstimap-venv,requirements 钉旧 requests 不进 re-venv;tplmap 上游停维护不装)
R5 mobile:apkid 3.1.0(uv tool 独立,yara-python-dex 依赖)
R6 注入:commix(clone,python3 wrapper);foremost(apt,无菜单签名雕刻)
R7 不做(tplmap/crunch/crossbuild-essential-*/bettercap/firmware-mod-kit,grok prt-10 判)
R8 P2 留置:fenjing(禁 mcp extra)/stegsnow/pngcheck/riscv64 交叉链

## trace(实现回填)

- T1 REQ 立单(2026-10-11)
- T2 pins 全套(git-dumper/apkid/zsteg/phpggc/commix/SSTImap/STEGSEEK 版本+sha256)
- T3 cross 组(compilers)+pentest 段九件(stego 四/web 三/注入/SSTI)
- T4 实例装+实证:四架构 g++-13 ✓、aarch64 -static 出真 ELF、gcc -m32 出 i386 ELF、九件断网全过(坑:gcc-multilib 与 cross 包打包互斥→i386 走 libc6-dev-i386 头道;交叉命令带 -13 代号;stegseek 资产名 stegseek_0.6-1.deb 无 arch 段)
- T5 册认领 13 行+catalog+REQ 回填;P2 留置(fenjing/stegsnow/pngcheck/riscv64)

## 验收判据

- 四架构静态编译实证(aarch64 -static 出 ELF)+ gcc -m32 通;九件新工具 --version/-l/--help 断网过

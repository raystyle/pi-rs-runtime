# 逆向分析稳定链(re 组册)

> 逆向工程稳定链:系统库 22 项 + rizin/rz-ghidra/sigdb 源码编译 + `/opt/re-venv` 五库 ｜ 状态:已装 ｜ 组:`install-tools.sh re`

- **版本钉**:系统库 22 项 apt noble 随源;rizin / rz-ghidra / sigdb 均 `git clone --depth 1` 未钉提交(rz-ghidra 的 ghidra git 子模块提交钉死匹配的 ghidra ref);re-venv 五库 PyPI 未钉。未钉口径留痕 [known-issues](../../known-issues.md)
- **来源与安装**:脚本段 `scripts/install-tools.sh` `install_re()`;apt 批镜像源阿里云(`image-defs/ubuntu.yaml` 写 deb822,2026-10-09 实测由 tuna 切换,注记在 `scripts/lib/common.sh`);rizin/rz-ghidra/sigdb 经 `${GITHUB_MIRROR}https://github.com/rizinorg/…` 克隆源码编译(meson/cmake,见下);re-venv 由 uv 建(`install-runtimes.sh uv` 提供,`/usr/local/bin/uv`),包走 PyPI 阿里云镜像(`PIP_INDEX`,构建期经 common.sh 导出 `UV_CONFIG_FILE=/etc/uv/uv-online.toml` 拿回在线面)
- **落点/配置与缓存**(批量机制):rizin `meson install` 落 /usr/local(`/usr/local/bin/rizin` 连同 rz-* 配套 CLI,库进 `/usr/local/lib/x86_64-linux-gnu`,装后 `ldconfig`);rz-ghidra 插件装进 rizin 运行时报告的插件目录(取法 `rizin -qc 'e dir.plugins'`,取不到兜底 `/usr/local/lib/x86_64-linux-gnu/rizin/plugins`);sigdb 数据 `meson --prefix=/usr/local` 落 `/usr/local/share/rizin/sigdb`(装失败只告警不中断);re-venv 固化 `/opt/re-venv`(`RE_VENV`,`uv venv` 建;离线缓存层登记见 [docs/offline.md](../../offline.md) §1);无 wrapper、无 per-user 配置。幂等判据:`have rizin`、`rizin -qc 'Lc' /bin/ls | grep -qi ghidra`、sigdb 三目录存在性、`[ -x "$RE_VENV/bin/python" ]`
- **离线行为**:☐ [推断:]readelf/objdump/eu-readelf/yara/cstool/file/binwalk 与 rizin(含 rz-ghidra 反编译)、re-venv 五库 import 均纯本地不触网,未进断网冒烟清单逐项实证。验证:`ip link set eth0 down` 后 `rizin -qc 'Lc' /bin/ls | grep -i ghidra` 与 `/opt/re-venv/bin/python -c 'import capstone,keystone,unicorn,lief,yara'` 退 0;断网向 venv 拉新件按 uv 默认面 `offline=true` 亚秒快失败(机制见 [docs/offline.md](../../offline.md) §4)
- **坑与留痕**:裁定:不装 apt 的 radare2、不装 knife/rsleigh/Ghidrust,Keystone/Unicorn 走 venv 不走 apt(`install_re()` 头注);`libzip-dev` 必给——缺了 meson 会去 libzip.org 拉子项目,国内必失败;rz-ghidra 必须 `--recurse-submodules --shallow-submodules`,自己按版本号克隆 ghidra 会 API 不匹配(core_ghidra.cpp 编译错);`-DUSE_SYSTEM_PUGIXML=ON` 用系统包绕过 third-party pugixml 子模块;rz_core.pc 的 plugindir 是相对路径,pkg-config 直取会装进 CWD 相对目录再被 rm 掉;sigdb 已改版为纯数据仓库(elf/pe + meson),旧 install.sh 不存在;Python 件不进系统 python3 的隔离裁定见 [ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md);p0 组往同一 `/opt/re-venv` 追加 flare-floss/oletools/netexec(见 [install-surfaces/tools.md](../../install-surfaces/tools.md) p0 节),venv 是共享研究环境、非本组独占;install-surfaces 与 software-inventory 的「tuna」口径已漂移(2026-10-09 切阿里云),件级事实以本册为准

## 成员表

成员计数:apt 22 包 + 源码编译 3 件 + venv 1 个(内 5 库)。构建期冒烟核对 `readelf objdump eu-readelf yara cstool file binwalk` 七入口在位。

### 系统库 22 项(apt noble 随源,`install_re()` 一批装)

| 包 | 提供 | 用途 |
|---|---|---|
| binutils | readelf、objdump 等 | ELF 静态分析 |
| elfutils | eu-readelf 等 | ELF 后端工具 |
| file | file | 文件类型识别 |
| bsdmainutils | BSD 系小工具集 | 构建/分析杂项依赖 |
| binwalk | binwalk | 固件镜像扫描与解包 |
| yara | yara | 样本特征规则扫描 |
| libyara-dev | yara 头文件/库 | yara 开发面 |
| libzip-dev | libzip | rizin 构建依赖(缺了 meson 去 libzip.org 拉子项目,必给) |
| libpugixml-dev | pugixml | rz-ghidra `USE_SYSTEM_PUGIXML=ON` 用系统包 |
| libcapstone-dev | capstone 头文件/库 | 反汇编开发面 |
| capstone-tool | cstool | capstone CLI |
| meson | meson | rizin/sigdb 构建系统 |
| ninja-build | ninja | meson 后端 |
| cmake | cmake | rz-ghidra 构建 |
| pkg-config | pkg-config | 依赖探测 |
| git | git | 源码克隆 |
| gcc | gcc | C 编译 |
| g++ | g++ | C++ 编译 |
| python3 | python3 | 运行时 |
| python3-pip | pip | 系统 pip(逆向件不进系统 python3,只作底座) |
| python3-venv | venv 模块 | venv 底座 |
| zlib1g-dev | zlib 头文件/库 | 压缩库开发面 |

### 源码编译三件(经 GITHUB_MIRROR 克隆,`--depth 1` 未钉)

| 件 | 来源 | 构建 | 落点 |
|---|---|---|---|
| rizin | [rizinorg/rizin](https://github.com/rizinorg/rizin)([rizin.re](https://rizin.re)) | meson setup/compile/install(--buildtype=release) | /usr/local |
| rz-ghidra | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra)(ghidra 走 git 子模块钉 ref) | cmake Release + USE_SYSTEM_PUGIXML=ON + RIZIN_INSTALL_PLUGINDIR | rizin 插件目录 |
| sigdb | [rizinorg/sigdb](https://github.com/rizinorg/sigdb)(纯数据仓库) | meson --prefix=/usr/local | /usr/local/share/rizin/sigdb |

### /opt/re-venv 五库(PyPI 未钉,`VIRTUAL_ENV=$RE_VENV uv pip install`)

| 库 | 角色 |
|---|---|
| capstone | 反汇编 |
| keystone-engine | 汇编 |
| unicorn | 模拟执行 |
| lief | 解析改写 PE/ELF/Mach-O |
| yara-python | 规则扫描 |

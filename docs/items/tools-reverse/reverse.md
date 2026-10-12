# 逆向分析稳定链:reverse 组册

> 逆向工程稳定链:系统库 22 项 + rizin/rz-ghidra/sigdb 源码编译 + `/opt/re-venv` 五库 ｜ 状态:已装 ｜ 组:`install-tools.sh reverse`

## 版本

- 系统库 22 项随 apt noble 源冻结,即软件源锁定。见 [known-issues.md](../../known-issues.md)。
- rizin、rz-ghidra、sigdb 由 pins.sh 的 `GIT_PIN[rizinorg/…]` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- rz-ghidra 的 ghidra 子模块 ref 跟随该锁定提交里的 `.gitmodules`。
- re-venv 五库由 pins.sh 的 `PYPI_PIN` 锁定版本。
- capstone 5.0.9。
- keystone-engine 0.9.2。
- unicorn 2.1.4。
- lief 1.0.0。
- yara-python 4.5.4。
- 解析日 2026-10-10。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_reverse`。
- apt 批的镜像是阿里云。`image-defs/ubuntu.yaml` 写入 deb822。
- 镜像注记在 `scripts/lib/common.sh`。
- rizin、rz-ghidra、sigdb 经 `${GITHUB_MIRROR}https://github.com/rizinorg/…` 克隆源码后编译。
- rizin 与 sigdb 用 meson。rz-ghidra 用 cmake。
- re-venv 由 uv 创建。uv 来自 `install-runtimes.sh` 的 uv 组,入口是 `/usr/local/bin/uv`。
- 包走 PyPI 的阿里云镜像 `PIP_INDEX`。
- 构建期 common.sh 导出 `UV_CONFIG_FILE=/etc/uv/uv-online.toml`,使用在线配置。
- 幂等判据之一是 `have rizin`。
- 幂等判据之一是 `rizin -qc 'Lc' /bin/ls | grep -qi ghidra`。
- 幂等判据之一是 sigdb 三个目录存在。
- 幂等判据之一是 `[ -x "$RE_VENV/bin/python" ]`。

## 文件

- rizin 经 `meson install` 装到 `/usr/local`。
- `/usr/local/bin/rizin` 与配套的 rz-* CLI 在这一次安装里一起出现。
- 库装到 `/usr/local/lib/x86_64-linux-gnu`。装完执行 `ldconfig`。
- rz-ghidra 插件装进 rizin 运行时报告的插件目录。
- 插件目录的取法是 `rizin -qc 'e dir.plugins'`。
- 取不到时,兜底 `/usr/local/lib/x86_64-linux-gnu/rizin/plugins`。
- sigdb 用 `meson --prefix=/usr/local`,数据落在 `/usr/local/share/rizin/sigdb`。
- sigdb 安装失败只告警,不中断本组。
- re-venv 在 `/opt/re-venv`,变量名 `RE_VENV`,由 `uv venv` 创建。
- 离线缓存层的登记见 [offline.md](../../offline.md)。

## 配置

- 无 wrapper。
- 无按用户分开的配置。

## 离线行为

- 支持 rz-ghidra 加载。关闭 eth0 后,以 root 执行 `rizin -qc 'Lc' /bin/ls | grep -i ghidra` 退 0。
- 此时 rizin 版本是 0.10.0,反编译面已加载。
- 支持五库导入。同一断网条件下,`/opt/re-venv/bin/python -c 'import capstone,keystone,unicorn,lief,yara'` 退 0。
- 未验证逐项:readelf、objdump、eu-readelf、yara、cstool、file、binwalk。它们只做本地分析。
- 断网后向 venv 安装未缓存的包时,uv 默认 `offline=true`,在亚秒内失败。见 [offline.md](../../offline.md)。

## 限制

- 不安装 apt 的 radare2。
- 不安装 knife、rsleigh、Ghidrust。
- Keystone 与 Unicorn 走 venv,不走 apt。这是 `install_reverse` 开头的规则。
- `libzip-dev` 必须安装。缺少它时,meson 会到 libzip.org 拉取子项目,在国内会失败。
- rz-ghidra 必须使用 `--recurse-submodules --shallow-submodules`。
- 按版本号自行克隆 ghidra 时,API 对不上,`core_ghidra.cpp` 编译失败。
- `-DUSE_SYSTEM_PUGIXML=ON` 使用系统 pugixml,不拉取 third-party 子模块。
- `rz_core.pc` 的 plugindir 是相对路径。直接用 pkg-config 的值会装进当前目录的相对路径,随后被删掉。
- sigdb 现在是纯数据仓库,内容是 elf/pe,用 meson 安装。旧的 `install.sh` 不存在。
- Python 件不装进系统 python3。
- analysis 组向同一个 `/opt/re-venv` 追加 flare-floss、oletools、netexec。见 [tools.md](../../install-surfaces/tools.md) 的 analysis 节。
- 这个 venv 是共享的研究环境,不是本组独占。
- [tools.md](../../install-surfaces/tools.md) 与 [software-inventory.md](../../software-inventory.md) 仍写 tuna。
- apt 镜像的件级事实以本册为准:阿里云。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [tools.md](../../install-surfaces/tools.md)
- [angr.md](angr.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: rz-bin kind=tool path=/usr/local/bin/rz-bin
- rctl: rz-asm kind=tool path=/usr/local/bin/rz-asm
- rctl: rz-ax kind=tool path=/usr/local/bin/rz-ax
- rctl: rz-diff kind=tool path=/usr/local/bin/rz-diff
- rctl: rz-find kind=tool path=/usr/local/bin/rz-find
- rctl: rz-gg kind=tool path=/usr/local/bin/rz-gg
- rctl: rz-hash kind=tool path=/usr/local/bin/rz-hash
- rctl: rz-run kind=tool path=/usr/local/bin/rz-run
- rctl: rz-sign kind=tool path=/usr/local/bin/rz-sign
- rctl: rz-test kind=tool path=/usr/local/bin/rz-test
- rctl: rz-ar kind=tool path=/usr/local/bin/rz-ar
- rctl: rizin kind=tool path=/usr/local/bin/rizin note=rizin 本尊,rz-ghidra 反编译面经它出(pdg)
- rctl: rz-ghidra kind=tool path=/usr/local/lib/x86_64-linux-gnu/rizin/plugins/core_ghidra.so note=rizin 反编译插件,analysis/asm/core 三 so 加 rz_ghidra_sleigh 数据同域
- rctl: yara-rules kind=data path=/opt/yara-rules note=yara 规则集

## 成员清单

- 成员计数:apt 22 包 + 源码编译 3 件 + venv 1 个(内 5 库)。
- 构建期冒烟核对 `readelf`、`objdump`、`eu-readelf`、`yara`、`cstool`、`file`、`binwalk` 七个入口在位。

### 系统库 22 项

apt noble 随源,由 `install_reverse` 一批安装。

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

### 源码编译三件

经 `GITHUB_MIRROR` 克隆,`GIT_PIN` 锁定提交。

| 件 | 来源 | 构建 | 路径 |
|---|---|---|---|
| rizin | [rizinorg/rizin](https://github.com/rizinorg/rizin)([rizin.re](https://rizin.re)) | meson setup/compile/install(--buildtype=release) | /usr/local |
| rz-ghidra | [rizinorg/rz-ghidra](https://github.com/rizinorg/rz-ghidra)(ghidra 走 git 子模块锁定 ref) | cmake Release + USE_SYSTEM_PUGIXML=ON + RIZIN_INSTALL_PLUGINDIR | rizin 插件目录 |
| sigdb | [rizinorg/sigdb](https://github.com/rizinorg/sigdb)(纯数据仓库) | meson --prefix=/usr/local | /usr/local/share/rizin/sigdb |

### /opt/re-venv 五库

PyPI 锁定版本 `PYPI_PIN`。命令是 `VIRTUAL_ENV=$RE_VENV uv pip install`。

| 库 | 角色 |
|---|---|
| capstone | 反汇编 |
| keystone-engine | 汇编 |
| unicorn | 模拟执行 |
| lief | 解析改写 PE/ELF/Mach-O |
| yara-python | 规则扫描 |

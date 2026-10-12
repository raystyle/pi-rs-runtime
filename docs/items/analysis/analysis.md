# 安全分析工具集(analysis 安装组)

> apt 批、impacket 与 nasm 特例、re-venv 批、GitHub 版本锁定批 ｜ 状态:已装 ｜ 组:`install-tools.sh analysis`

## 版本

- apt 20 包使用 noble 源的版本,不另写锁定版本。源是阿里云镜像。
- impacket 与 nasm 的锁定值不在本册。见 [impacket.md](impacket.md) 与 [nasm.md](nasm.md)。
- re-venv 批与 GitHub 批的逐件锁定值不在本册。见各件册。

## 来源与安装

- 脚本:`install-tools.sh` 的 `install_analysis`。
- apt 批、re-venv 批、GitHub 版本锁定批分三步执行。
- impacket 与 nasm 在 apt 批之后、re-venv 批之前执行,不计入这三步。
- impacket:先卸 apt 的 `python3-impacket`,再用 uv 装上游版。见 [impacket.md](impacket.md)。
- nasm:按官网按锁定版本从源码构建编译。见 [nasm.md](nasm.md)。
- GitHub 批经 `GITHUB_MIRROR`。默认 `proxy.ohmygh.com`。规定见 [params.md](../../params.md)。
- apt 20 包是 Ubuntu 打包,版本随 noble 源。入口用包的常规命令名。
- 脚本末尾的核对循环确认以下命令在 PATH:checksec、patchelf、ROPgadget、nmap、sqlmap、tshark、john、hashid。
- apt 批 20 包的逐项表在成员清单。

## 文件

- apt 包由 dpkg 写入系统路径,含 `/usr/bin`。
- 本段导出 `UV_TOOL_BIN_DIR=/usr/local/bin`。
- 本段导出 `UV_TOOL_DIR=/opt/uv-tools`。
- uv tool 的 shim 在 `/usr/local/bin`。本体在 `/opt/uv-tools/<名>`。
- re-venv 件的本体在 `/opt/re-venv/bin`。
- floss、olevba、oleid、netexec 四个入口用 `ln -sf` 链到 `/usr/local/bin`。
- GitHub 批锁定在 `/opt/<名>` 的有:jadx、apktool、capa、capa-rules、yara-rules、SecLists。
- GitHub 批直接拷到 `/usr/local/bin` 的有:pdfid.py、pdf-parser.py。

## 配置

- 本组不写运行期配置。
- 本组不固化缓存。
- 构建期 `RE_VENV=/opt/re-venv`,定义在 common.sh。
- 构建期在线面使用 `UV_CONFIG_FILE=/etc/uv/uv-online.toml`。
- 构建期设 `PIP_NO_INDEX=false`。
- 运行期默认离线,失败立即返回。见 [offline.md](../../offline.md) 第 4 节。
- netexec 缺包时改用 git 源。
- flare-floss 与 oletools 失败时,以 `--no-cache` 重试。
- 组尾的自检循环打印已在位的件。

## 离线行为

- 未验证到逐件命令。
- apt 20 包是本地分析件,运行期不依赖外网。
- nmap 与 sqlmap 的扫描需要到目标的网络。
- tcpdump 与 tshark 抓本网需要到目标的网络。
- mitmproxy 拦截需要到目标的网络。
- 外网断开且内网可达时,上述对目标的动作仍可用。
- eth0 关闭后,这些工具退化为本地文件处理。
- 发布门禁的断网冒烟覆盖渗透与分析工具面。逐件命令不在本册。
- 关闭 eth0 后,`checksec --file=/bin/ls && ssdeep /bin/ls` 退出码 0 为判定命令。

## 限制

- apt 批整批带 `|| echo`,失败不退出。
- apt 批、re-venv 批、GitHub 批相互独立。
- apt 源是阿里云,写在 `image-defs/ubuntu.yaml`。
- `install_analysis` 的日志仍写「TUNA」。这是换源前的文案。
- 源以 yaml 与 common.sh 的注释为准。
- nasm 不走 apt,因为 apt 版停在 2.16.01。
- pwn 与 ROPgadget 只用系统 `/usr/bin/python3`。这是 apt 面,noble 上为 4.12.0/7.4。
- re-venv 不装 pwn。
- pip 版 pwn 会覆盖 dist-packages,造成两套版本。
- PyPI 上名为 pwn 的包是空包,不安装。
- 脚本安装或克隆共 34 件。
- 这 34 件的构成:apt 20、impacket、nasm、re-venv 批 3 件、GitHub 批 9 件。

## 参见

- [impacket.md](impacket.md)
- [nasm.md](nasm.md)
- [params.md](../../params.md)
- [offline.md](../../offline.md)

## rctl 收录行
- rctl: apkid kind=tool path=/usr/local/bin/apkid note=APK 加壳/编译器识别(uv tool 3.1.0,yara-python-dex 独立)

## 成员清单

apt 批 20 包,noble 随源,Ubuntu 打包。入口为包的常规命令名。
| 包 | 入口 | 用途 |
|---|---|---|
| gdb-multiarch | gdb | 多架构程序调试 |
| qemu-user-static | binfmt_misc 注册(qemu-*-static) | 用户态异架构 ELF 模拟执行 |
| python3-pwntools | pwn 等 + `import pwn` | CTF/pwn 漏洞利用开发框架 |
| python3-ropgadget | ROPgadget | ROP gadget 搜索 |
| checksec | checksec | 二进制保护属性检查(NX/PIE/Canary/RELRO) |
| patchelf | patchelf | 改写 ELF 解释器与 RPATH |
| xxd | xxd | 十六进制转储与回写 |
| squashfs-tools | mksquashfs/unsquashfs | SquashFS 固件镜像解包与重打包 |
| nmap | nmap | 端口扫描与服务识别 |
| sqlmap | sqlmap | SQL 注入自动检测与利用 |
| tcpdump | tcpdump | 命令行抓包 |
| tshark | tshark | Wireshark 命令行抓包与协议解析 |
| mitmproxy | mitmproxy/mitmdump/mitmweb | HTTP/HTTPS 中间人代理 |
| python3-scapy | `import scapy`(python3 库) | 数据包构造与嗅探库 |
| upx-ucl | upx | 可执行文件加壳与脱壳 |
| 7zip | 7zz | 多格式压缩解压 |
| libimage-exiftool-perl | exiftool | 文件元数据读取 |
| ssdeep | ssdeep | 模糊哈希与相似度比对 |
| john | john | John the Ripper 口令破解 |
| hashid | hashid | 哈希类型识别 |

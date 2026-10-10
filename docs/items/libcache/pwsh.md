# PowerShell 模块缓存(/opt/psmodules)

> Save-PSResource 固化 8 个 PSGallery 模块(含传递依赖),全 shell 可 Import-Module ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh pwsh`(前置 `install-runtimes.sh pwsh`)

- **版本钉**:未钉——PSGallery 无国内镜像,构建期直连取最新(Save-PSResource 含依赖解析);升级重跑本组
- **来源与安装**:PSGallery 经 inbox PSResourceGet `Save-PSResource -Path /opt/psmodules -TrustRepository -Quiet`(带 `-ErrorAction SilentlyContinue`,Gallery 国内不稳,部分失败重跑可补);脚本段 `scripts/install-libcache.sh install_pwsh`;pwsh 未装则早退(先跑 runtimes pwsh 组)

  | 模块 | 用途 |
  |---|---|
  | Posh-SSH | SSH/SFTP/端口转发会话 |
  | powershell-yaml | YAML 读写 |
  | ImportExcel | Excel 读写(无需 Office) |
  | PowerHTML | HTML 解析(HtmlAgilityPack 封装) |
  | Pester | 测试框架 |
  | PSScriptAnalyzer | 脚本静态分析 |
  | Microsoft.PowerShell.SecretManagement | 密钥管理抽象层 |
  | Microsoft.PowerShell.SecretStore | 本地密钥仓 |

- **落点**:`/opt/psmodules/<模块>/`;逐模块软链进 `/usr/local/share/powershell/Modules/`(pwsh 默认系统模块路径)
- **配置与缓存**:`/etc/profile.d/psmodules.sh` 写 `export PSModulePath=/opt/psmodules:${PSModulePath:-}`——只是登录 shell 备份面;非登录 shell(incus exec)不读 profile.d,链进系统模块路径才是真机制,全 shell 可见;模块面是只读消费面,保持 755 不走共享写(权限模型见 [offline.md](../../offline.md) §5)
- **离线行为**:☐ [推断:]模块字节已在本地,Import-Module 不访问网络;链接机制在 2026-10-10 离线轮修过(断网冒烟 78/0,见 [diary](../../diary/2026-10-10-offline-rounds.md)),但冒烟未单列 pwsh 模块导入断言。验证:`ip link set eth0 down` 后 `pwsh -NoProfile -Command "Import-Module Posh-SSH; Get-Module"`
- **坑与留痕**:旧 PackageManagement(Save-Module)在 noble + pwsh 7.4 上段错误(实证),必须走 inbox PSResourceGet 的 Save-PSResource

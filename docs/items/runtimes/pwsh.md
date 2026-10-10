# PowerShell(pwsh)

> 跨平台 PowerShell 运行时(AD/Windows 自动化与脚本样本分析) ｜ 状态:已装 ｜ 组:`install-runtimes.sh pwsh` + `install-libcache.sh pwsh`(模块固化)

- **版本钉**:软钉——MS 仓 apt 浮动即钉,`powershell-lts` 随 packages.microsoft.com 仓(pins.sh 无钉位,留痕 [known-issues](../../known-issues.md));lts 包不可用时 `||` 退回 `powershell`
- **来源与安装**:[PowerShell/PowerShell](https://github.com/PowerShell/PowerShell) → MS apt 仓(国内无镜像);`install_dotnet_repo` 按 `/etc/os-release` 的 VERSION_ID 取 packages-microsoft-prod.deb 注册仓(**只为 pwsh 注册,dotnet 走 Ubuntu noble 源**),然后 `apt-get install -y powershell-lts || apt-get install -y powershell`
- **落点**:apt 包直装,`pwsh` 入口随包进 PATH;模块固化 `/opt/psmodules`(libcache pwsh 组 `Save-PSResource` 含依赖:Posh-SSH、powershell-yaml、ImportExcel、PowerHTML、Pester、PSScriptAnalyzer、Microsoft.PowerShell.SecretManagement、Microsoft.PowerShell.SecretStore),逐个软链进 `/usr/local/share/powershell/Modules`(pwsh 默认系统模块路径,全 shell 可见)
- **配置与缓存**:`/etc/profile.d/psmodules.sh` export `PSModulePath=/opt/psmodules:…`(libcache 组写)仅作登录 shell 备份面;非登录 shell(incus exec)不读 profile.d,运行期靠系统模块路径软链([known-issues](../../known-issues.md));PSGallery 无国内镜像,构建期直连,`Save-PSResource` 部分失败重跑可补
- **离线行为**:✅ 本体为本地运行时;模块面经系统模块路径软链断网可见(离线轮缺口① PSModulePath 失效的修复项,修复后冒烟 78/0,机制见 [offline.md](../../offline.md) §1)。验证:`ip link set eth0 down` 后 `pwsh -NoProfile -Command "Get-Module -ListAvailable"` 列出 /opt/psmodules 各模块
- **坑与留痕**:旧 PackageManagement(`Save-Module`)在 noble + pwsh 7.4 上段错误,固化走 inbox 的 PSResourceGet(`Save-PSResource`);模块固化前置守卫 `have pwsh`——pwsh 未装时 libcache pwsh 组直接跳过(先跑 install-runtimes.sh pwsh)

# PowerShell:pwsh

> 跨平台 PowerShell 运行时(AD/Windows 自动化与脚本样本分析) ｜ 状态:已装 ｜ 组:`install-runtimes.sh pwsh` + `install-libcache.sh pwsh`(模块固化)

## 版本

- 软钉。MS 仓的 apt 包浮动即钉。
- `powershell-lts` 随 packages.microsoft.com 仓。pins.sh 无钉位。见 [known-issues.md](../../known-issues.md)。
- lts 包不可用时,`||` 退回安装 `powershell`。

## 来源与安装

- 上游:[PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)。
- 安装走 MS apt 仓。国内无镜像。
- `install_dotnet_repo` 按 `/etc/os-release` 的 `VERSION_ID` 取 packages-microsoft-prod.deb,注册该仓。
- 该仓只为 pwsh 注册。dotnet 走 Ubuntu noble 源。
- 然后执行 `apt-get install -y powershell-lts || apt-get install -y powershell`。

## 文件

- apt 包直装。`pwsh` 入口随包进入 PATH。
- 发行树在 `/opt/microsoft/powershell/<版本>`。这是 apt 包自带布局,不是本仓脚本创建的。
- 模块固化在 `/opt/psmodules`。libcache pwsh 组用 `Save-PSResource` 拉取,含依赖。
- 每个模块软链进 `/usr/local/share/powershell/Modules`。这是 pwsh 默认的系统模块路径,全部 shell 可见。

| 模块 |
| --- |
| Posh-SSH |
| powershell-yaml |
| ImportExcel |
| PowerHTML |
| Pester |
| PSScriptAnalyzer |
| Microsoft.PowerShell.SecretManagement |
| Microsoft.PowerShell.SecretStore |

## 配置

- `/etc/profile.d/psmodules.sh` 导出 `PSModulePath=/opt/psmodules:…`。该文件由 libcache 组写。
- 它只是登录 shell 的备份面。
- 非登录 shell(`incus exec`)不读 profile.d。运行期靠系统模块路径上的软链。见 [known-issues.md](../../known-issues.md)。
- PSGallery 无国内镜像。构建期直连。
- `Save-PSResource` 部分失败时,重跑可以补齐。

## 离线行为

- 支持:本体是本地运行时。
- 支持:模块经系统模块路径软链,断网可见。机制见 [offline.md](../../offline.md) 第 1 节。
- 验证:关闭 eth0 后,`pwsh -NoProfile -Command "Get-Module -ListAvailable"` 列出 `/opt/psmodules` 的各模块。

## 限制

- 旧 PackageManagement 的 `Save-Module` 在 noble 加 pwsh 7.4 上段错误。
- 固化改走 inbox 的 PSResourceGet,命令是 `Save-PSResource`。
- 模块固化的前置守卫是 `have pwsh`。pwsh 未装时,libcache pwsh 组直接跳过。
- 先跑 `install-runtimes.sh` 的 pwsh 组。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [pwsh 库缓存](../libcache/pwsh.md)

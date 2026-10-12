# PowerShell 模块缓存:/opt/psmodules

> Save-PSResource 固化 8 个 PSGallery 模块(含传递依赖),全 shell 可 Import-Module ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh pwsh`(前置 `install-runtimes.sh pwsh`)

## 版本

- 模块未钉版。
- PSGallery 无国内镜像。
- pins.sh 也没有模块映射。
- 构建期直连,取当时的最新版。
- Save-PSResource 含依赖解析。
- 不产生锁文件。
- `/opt/psmodules` 即镜像侧快照。
- pwsh 本体是软钉:MS 仓 apt 浮动。
- 见 [known-issues.md](../../known-issues.md)。
- 升级:重跑本组。

## 来源与安装

- PSGallery 经 inbox 的 PSResourceGet。
- 命令是 `Save-PSResource -Path /opt/psmodules -TrustRepository -Quiet`。
- 带 `-ErrorAction SilentlyContinue`。
- Gallery 在国内不稳定。
- 部分失败后,重跑可以补上。
- 脚本:`scripts/install-libcache.sh` 的 `install_pwsh`。
- pwsh 未安装时,本组直接返回。
- 需要先跑 runtimes 的 pwsh 组。

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

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/psmodules/<模块>/ | 模块本体 |
| /usr/local/share/powershell/Modules/ | 逐模块符号链接;pwsh 默认系统模块路径 |

## 配置

- `/etc/profile.d/psmodules.sh` 写 `export PSModulePath=/opt/psmodules:${PSModulePath:-}`。
- 该文件只是登录 shell 的备份。
- 非登录 shell(`incus exec`)不读 profile.d。
- 链进系统模块路径之后,全部 shell 都能看见模块。
- 模块面是只读消费面,保持 755。
- 不走共享写。
- 权限模型见 [offline.md](../../offline.md) 第 5 节。

## 离线行为

- 未验证:模块字节已在本地,Import-Module 不访问网络。
- 链接机制使断网后模块仍然可见。
- 断网冒烟没有单独断言 pwsh 模块导入。
- 验证:关闭 eth0 后,`pwsh -NoProfile -Command "Import-Module Posh-SSH; Get-Module"`。

## 限制

- 旧的 PackageManagement(`Save-Module`)在 noble 加 pwsh 7.4 上发生段错误。
- 必须走 inbox PSResourceGet 的 `Save-PSResource`。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

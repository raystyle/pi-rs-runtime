# .NET 库缓存:NuGet /opt/nuget-packages + ilspycmd

> 16 个 NuGet 库包 + 8 RID self-contained runtime pack 固化进 /opt/nuget-packages;ilspycmd 反编译 CLI ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh dotnet`(前置 `install-runtimes.sh dotnet`,dotnet-sdk-10.0)

## 版本

- pins.sh 以 `NUGET_PIN[<包id>]` 锁定版本。
- 16 个库包加 ilspycmd,共 17 个键。
- 例:`NUGET_PIN[dnlib]` = 4.5.0。
- 例:`NUGET_PIN[ilspycmd]` = 11.1.0.9782。
- 解析日 2026-10-10。
- `dotnet add package --version` 与 `dotnet tool install --version` 把锁定值写进文件。
- 库包写入 `/opt/dotnet-prewarm/*.csproj`。
- ilspycmd 写入 /opt/dotnet-tools。
- 缺少锁定版本即失败,不静默改用别的版本。
- 升级:执行 `scripts/resolve-pins.sh`。
- csproj 即锁文件,已入库 `scripts/lock/dotnet/`。
- 有锁时拷入后直接 restore。
- 再生执行 `scripts/sync-locks.sh`。
- 8 个 RID runtime pack 的版本随 SDK。

## 来源与安装

- NuGet 使用华为 v3 镜像 `NUGET_MIRROR`。
- root 与 ubuntu 的 NuGet.Config 在 `<clear/>` 之后只留这个源。
- 该配置由 runtimes 的 dotnet 组写入。
- 预热工程:`dotnet new classlib -o /opt/dotnet-prewarm --framework net10.0`。
- 创建失败时回退默认框架。
- 脚本:`scripts/install-libcache.sh` 的 `install_dotnet`。

16 个库包:

| 包 | 用途 |
|---|---|
| dnlib | .NET 程序集读写 |
| AsmResolver / AsmResolver.PE / AsmResolver.DotNet | 程序集与 PE 解析 |
| Iced | x86 汇编/反汇编 |
| Mono.Cecil | 程序集读写 |
| ICSharpCode.Decompiler | 反编译引擎(ilspycmd 上游) |
| CommandLineParser / System.CommandLine | CLI 参数解析 |
| YamlDotNet / Newtonsoft.Json | 序列化 |
| BouncyCastle.Cryptography | 密码学 |
| System.DirectoryServices.Protocols | LDAP/AD |
| Microsoft.NETFramework.ReferenceAssemblies | 无 Windows 参照机也能编 .NET Framework 目标 |
| Microsoft.Data.Sqlite | SQLite ADO.NET |
| SharpZipLib | 压缩归档 |

8 个 RID(self-contained runtime pack,逐次 `dotnet restore -r <rid>`):linux-x64、linux-arm64、linux-musl-x64、linux-musl-arm64、win-x64、win-arm64、osx-x64、osx-arm64。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/nuget-packages | 构建期 export `NUGET_PACKAGES` 指向这里 |
| /opt/dotnet-prewarm | 预热工程;重跑时 rm -rf 后重建 |
| /opt/dotnet-tools/ilspycmd | ilspycmd 工具 |
| /usr/local/bin/ilspycmd | 指向工具的符号链接 |

## 配置

- 离线取件走 NuGet.Config 的 `fallbackPackageFolders`,指向 /opt/nuget-packages。
- root 与 ubuntu 各一份该配置。
- 这是 NuGet 的离线机制,与 SDK 的 NuGetFallbackFolder 相同。
- 不依赖 shell 环境变量。
- 运行期不再持久导出 `NUGET_PACKAGES`。
- global 与 fallback 指向同一路径时,登录后的 restore 会写入固化仓。
- ubuntu 在这种情况下还会权限失败。
- `/etc/profile.d/dotnet.sh` 只留 `DOTNET_CLI_TELEMETRY_OPTOUT=1`。
- nuget fallback 是只读消费面,保持 755。
- 见 [offline.md](../../offline.md) 第 5 节。

## 离线行为

- 支持:断网 `dotnet restore` 在断网冒烟批中覆盖,见 [offline.md](../../offline.md) 的验证节。
- fallback folder 直接取固化件,不访问网络。
- 验证:关闭 eth0 后,`cd /opt/dotnet-prewarm && dotnet restore`。

## 限制

- dotnet 未安装时,本组直接返回。
- 需要先跑 runtimes 的 dotnet 组。
- 单个 `dotnet add` 失败时打印并继续,不中断。
- restore 与逐个 RID 的 restore 分步执行。
- 每一步失败都打印,不中断另一步。

## 参见

- [offline.md](../../offline.md)

## rctl 收录行

- rctl: ilspycmd kind=tool path=/usr/local/bin/ilspycmd env=逆向环境 note=.NET 反编译 CLI(NUGET_PIN 单独锁定,装在 /opt/dotnet-tools)
- rctl: dotnet-prewarm kind=cache path=/opt/dotnet-prewarm note=restore 预热工程(csproj 锁)
- rctl: microsoft kind=cache path=/opt/microsoft note=dotnet sdk 安装目录
- rctl: nuget.exe kind=tool path=/opt/nuget.exe note=NuGet 命令行(独立件)

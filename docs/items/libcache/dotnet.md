# .NET 库缓存(NuGet /opt/nuget-packages + ilspycmd)

> 16 个 NuGet 库包 + 8 RID self-contained runtime pack 固化进 /opt/nuget-packages;ilspycmd 反编译 CLI ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh dotnet`(前置 `install-runtimes.sh dotnet`,dotnet-sdk-10.0)

- **版本钉**:pins.sh 钉版(`NUGET_PIN[<包id>]`,16 库包 + ilspycmd 共 17 键,如 `NUGET_PIN[dnlib]`=4.5.0、`NUGET_PIN[ilspycmd]`=11.1.0.9782;解析日 2026-10-10),`dotnet add package --version` / `dotnet tool install --version` 把钉值写进 `/opt/dotnet-prewarm/*.csproj` 与 /opt/dotnet-tools(缺钉即响不静默漂),升级跑 scripts/resolve-pins.sh;csproj 即锁文件,在镜像侧,repo 侧回收是 PROGRESS.md 待办 3;8 RID runtime pack 版本随 SDK
- **来源与安装**:NuGet 华为 v3 镜像(`NUGET_MIRROR`;root 与 ubuntu 的 NuGet.Config `<clear/>` 后只留它,runtimes dotnet 组写);预热工程 `dotnet new classlib -o /opt/dotnet-prewarm --framework net10.0`(失败回退默认框架);脚本段 `scripts/install-libcache.sh install_dotnet`

  16 库包:

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

  8 RID(self-contained runtime pack,逐 `dotnet restore -r <rid>`):linux-x64、linux-arm64、linux-musl-x64、linux-musl-arm64、win-x64、win-arm64、osx-x64、osx-arm64

- **落点**:`/opt/nuget-packages`(构建期 export `NUGET_PACKAGES` 指向);`/opt/dotnet-prewarm`(预热工程,重跑 rm -rf 重建);`/opt/dotnet-tools/ilspycmd`;`/usr/local/bin/ilspycmd` 软链
- **配置与缓存**:离线取件走 NuGet.Config `fallbackPackageFolders` → /opt/nuget-packages(root+ubuntu 各一份,NuGet 官方离线机制,同 SDK NuGetFallbackFolder,不依赖 shell env);**不再持久导出 NUGET_PACKAGES**——global 与 fallback 同路径会让登录 restore 写固化仓,ubuntu 还会权限失败(grok G3);`/etc/profile.d/dotnet.sh` 只留 `DOTNET_CLI_TELEMETRY_OPTOUT=1`;nuget fallback 是只读消费面,保持 755([offline.md](../../offline.md) §5)
- **离线行为**:✅ 断网 `dotnet restore` 在断网冒烟批覆盖(见 [offline.md](../../offline.md) 验证节),fallback folder 直取固化件不触网。验证:`ip link set eth0 down` 后 `cd /opt/dotnet-prewarm && dotnet restore`
- **坑与留痕**:dotnet 未装早退(先跑 runtimes dotnet 组);单包 `dotnet add` 失败 tolerant(回 echo 不中断),restore 与逐 RID restore 分步各自留 echo

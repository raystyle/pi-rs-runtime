# .NET SDK(dotnet)

> .NET 编译/运行链与 NuGet 包生态 ｜ 状态:已装 ｜ 组:`install-runtimes.sh dotnet` + `install-libcache.sh dotnet`(库固化)

- **版本钉**:`DOTNET_SDK=dotnet-sdk-10.0`(lib/common.sh;apt 包名钉大版本,小版本随 noble 源;8.0 将于 2026-11 停止支持)
- **来源与安装**:[dot.net](https://dot.net) → Ubuntu noble 自带源 `apt-get install -y dotnet-sdk-10.0`(noble 源经 tuna;MS 仓 24.04 起不提供 .NET,packages.microsoft.com 仓只为 [pwsh](pwsh.md) 注册)
- **落点**:apt 包直装,`dotnet` 入口随包进 PATH;固化库 `/opt/nuget-packages`(libcache dotnet 组预热工程 restore:dnlib/AsmResolver/Iced/Mono.Cecil/ICSharpCode.Decompiler/Newtonsoft.Json 等 16 包 + linux/win/osx 八 RID runtime pack;ilspycmd 全局工具落 `/opt/dotnet-tools` 并链 `/usr/local/bin/ilspycmd`)
- **配置与缓存**:`/etc/profile.d/dotnet.sh` 只 export `DOTNET_CLI_TELEMETRY_OPTOUT=1`;root 与 ubuntu 各一份 `~/.nuget/NuGet/NuGet.Config`:packageSources `<clear/>` 后只留华为云 v3(`NUGET_MIRROR=https://repo.huaweicloud.com/repository/nuget/v3/index.json`,实证 200;azure.cn 旧 CDN 已解析失败),`fallbackPackageFolders` 加 `prewarm=/opt/nuget-packages`——NuGet 官方离线机制(同 SDK NuGetFallbackFolder),restore 直接从固化目录取件;per-user 配置文件非登录 shell(incus exec)也生效,这是它比 env 强的点
- **离线行为**:✅ 断网 restore 实证(断网冒烟 78/0 覆盖 nuget restore,口径见 [offline.md](../../offline.md) §验证)。验证:`ip link set eth0 down` 后 `cd /opt/dotnet-prewarm && dotnet restore` 退 0;固化目录是只读消费面,保持 755 不进 piopt 共享写([offline.md](../../offline.md) §5)
- **坑与留痕**:**运行期不再导出 NUGET_PACKAGES**——那会把 global-packages 与 fallback 指成同一目录,登录 restore 会往固化仓写,ubuntu 还权限失败(grok G3;裁定见 [ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));libcache 构建期临时 `export NUGET_PACKAGES=/opt/nuget-packages` 仅为预热 restore,不落成运行期配置;NuGet http-cache(约 0.5 GB)被 clean-image.sh 清掉,可再生,不影响 fallback 取件

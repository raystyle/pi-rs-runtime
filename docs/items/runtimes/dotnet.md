# .NET SDK:dotnet

> .NET 编译/运行链与 NuGet 包生态 ｜ 状态:已装 ｜ 组:`install-runtimes.sh dotnet` + `install-libcache.sh dotnet`(库固化)

## 版本

- `DOTNET_SDK=dotnet-sdk-10.0`(`lib/common.sh`)。
- apt 包名锁定大版本。小版本随 noble 源。
- 8.0 将于 2026-11 停止支持。

## 来源与安装

- 上游:[dot.net](https://dot.net)。
- Ubuntu noble 自带源:`apt-get install -y dotnet-sdk-10.0`。
- noble 源经 tuna。
- MS 仓从 24.04 起不提供 .NET。packages.microsoft.com 仓只为 [pwsh 册](pwsh.md) 注册。

## 文件

- apt 包直装。`dotnet` 入口随包进入 PATH。
- 固化库在 `/opt/nuget-packages`。
- libcache dotnet 组的预热工程 restore 覆盖 dnlib、AsmResolver、Iced、Mono.Cecil、ICSharpCode.Decompiler、Newtonsoft.Json 等 16 个包。
- 另有 linux、win、osx 共八个 RID 的 runtime pack。
- ilspycmd 全局工具落在 `/opt/dotnet-tools`,并链到 `/usr/local/bin/ilspycmd`。

## 配置

- `/etc/profile.d/dotnet.sh` 只导出 `DOTNET_CLI_TELEMETRY_OPTOUT=1`。
- root 与 ubuntu 各有一份 `~/.nuget/NuGet/NuGet.Config`。
- packageSources 先 `<clear/>`,然后只留华为云 v3。
- `NUGET_MIRROR=https://repo.huaweicloud.com/repository/nuget/v3/index.json`。该地址响应 HTTP 200。
- azure.cn 旧 CDN 已解析失败。
- `fallbackPackageFolders` 增加 `prewarm=/opt/nuget-packages`。
- 这是 NuGet 的官方离线机制,与 SDK 的 NuGetFallbackFolder 相同。restore 直接从固化目录取件。
- per-user 配置文件在非登录 shell(`incus exec`)也生效。这一点比环境变量强。

## 离线行为

- 支持:断网 restore。记录见 [offline.md](../../offline.md) 验证节。
- 验证:关闭 eth0 后,`cd /opt/dotnet-prewarm && dotnet restore` 退出码 0。
- 固化目录是只读消费面,保持 755,不进 piopt 共享写。见 [offline.md](../../offline.md) 第 5 节。

## 限制

- 运行期不导出 `NUGET_PACKAGES`。
- 导出它会把 global-packages 与 fallback 指成同一目录。
- 登录 shell 的 restore 会往固化仓写。ubuntu 还会因权限失败。
- libcache 在构建期临时 `export NUGET_PACKAGES=/opt/nuget-packages`,只为预热 restore,不写成运行期配置。
- NuGet http-cache 约 0.5 GB,被 `clean-image.sh` 清掉。它可再生,不影响 fallback 取件。

## 参见

- [offline.md](../../offline.md)
- [pwsh 册](pwsh.md)
- [dotnet 库缓存](../libcache/dotnet.md)

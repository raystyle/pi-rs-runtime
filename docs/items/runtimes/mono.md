# Mono

> 老 .NET Framework 项目的构建与运行链:mono 运行时 + xbuild + .NET 4.x 引用程序集 ｜ 状态:已装 ｜ 组:`install-runtimes.sh mono`

## 版本

- `mono-devel` 与 `mono-xbuild` 为 noble 源冻结,即软件源锁定。见 [known-issues.md](../../known-issues.md)。
- `nuget.exe` 未锁定版本。从 dist.nuget.org 的 latest 直下,无校验和。pins.sh 未收该锁定项。

## 来源与安装

- 来源:[mono-project](https://www.mono-project.com) 的 Ubuntu 打包。
- 安装命令:`apt-get install mono-devel mono-xbuild`。
- apt 源随 `image-defs/ubuntu.yaml`,当前是阿里云。
- 脚本 log 与 install-surfaces 仍写 tuna。这两处与现行源不一致。
- `nuget.exe` 从 `https://dist.nuget.org/win-x86-commandline/latest/nuget.exe` 直下。
- 它用于还原 packages.config 型老项目。noble apt 没有 nuget 包。
- 脚本:`scripts/install-runtimes.sh` 的 `install_mono`。

## 文件

- `/usr/bin/mono` 与 `/usr/bin/xbuild` 是 apt 被包装的程序。
- `/opt/nuget.exe` 只下载,不建 wrapper。
- 调用方式是 `mono /opt/nuget.exe`。

## 配置

- 脚本不写 mono 配置。
- nuget.exe 的源配置未设,默认 nuget.org。
- `/opt/nuget-packages` 这个 fallback 属于 dotnet SDK,与 mono 无关。

## 离线行为

- 支持:`mono /opt/nuget.exe help` 在本地退出码 0,版本 NuGet 7.9.0.83,usage 面可出。
- `mono` 与 `xbuild` 编译需要网络。mono 面无固化仓兜底。
- `nuget.exe restore` 拉取未缓存包需要网络。这是边界。

## 限制

- noble 没有 msbuild 包(Debian #1033828,wontfix)。
- 经典 csproj 只能用 xbuild。这写在脚本 log 里。
- SDK 风格的新项目走 dotnet 组(`install-runtimes.sh dotnet`),与 mono 分工。
- noble 下用 mono、xbuild、dotnet 构建 .NET Framework 的调研笔记在 `/tmp/pi-rs-dotnetfx-plan.md`。
- projectzero 组的 tyranid 三件套等 .NET 参考项目只克隆,当作参考代码,用到再编。脚本是 `scripts/install-tools.sh` 的 projectzero 组。

## 参见

- [known-issues.md](../../known-issues.md)
- [dotnet 册](dotnet.md)

## rctl 面,机器行

- rctl: mono kind=runtime path=/usr/bin/mono note=运行时本尊(xbuild 同域;nuget.exe 行归 libcache/dotnet 册)

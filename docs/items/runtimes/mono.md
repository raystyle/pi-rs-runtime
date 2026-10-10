# Mono

> 老 .NET Framework 项目的构建与运行链:mono 运行时 + xbuild + .NET 4.x 引用程序集 ｜ 状态:已装 ｜ 组:`install-runtimes.sh mono`

- **版本钉**:`mono-devel`、`mono-xbuild` noble 源冻结即钉(软钉,留痕 [known-issues](../../known-issues.md));`nuget.exe` 未钉(dist.nuget.org latest 直下,无校验和,pins.sh 未收钉位)
- **来源与安装**:[mono-project](https://www.mono-project.com) 的 Ubuntu 打包,`apt-get install mono-devel mono-xbuild`(apt 源随 `image-defs/ubuntu.yaml`,当前为阿里云——脚本 log 与 install-surfaces 写的 tuna 已漂移);`nuget.exe` 从 `https://dist.nuget.org/win-x86-commandline/latest/nuget.exe` 直下,还原 packages.config 型老项目用(noble apt 无 nuget 包)(`scripts/install-runtimes.sh` `install_mono`)
- **落点**:`/usr/bin/mono`、`/usr/bin/xbuild`(apt 真身);`/opt/nuget.exe`(脚本只下载不建 wrapper,经 `mono /opt/nuget.exe` 调用——[推断:]常规用法)
- **配置与缓存**:无(脚本不写 mono 配置;nuget.exe 源配置未设,默认 nuget.org;`/opt/nuget-packages` fallback 是 dotnet SDK 的面,与 mono 无关)
- **离线行为**:☐ [推断:]`mono`/`xbuild` 运行与编译本地完成不触网;`nuget.exe restore` 拉未缓存包需联网,mono 面无固化仓兜底;断网冒烟未单独覆盖本件。验证:`ip link set eth0 down` 后 `mono --version` 与 `xbuild /version`
- **坑与留痕**:noble 没有 msbuild 包(Debian #1033828 wontfix),经典 csproj 只能用 xbuild——脚本 log 留痕;SDK 风格新项目走 dotnet 组(install-runtimes.sh dotnet),与 mono 分工;noble 下 mono/xbuild/dotnet 构建 .NET Framework 的调研留档在 `/tmp/pi-rs-dotnetfx-plan.md`(grok 方案,不留库,pz 组注释引用);pz 组 tyranid 三件套等 .NET 参考项目用户裁定(2026-10-08)只克隆当参考代码、用到再编(`scripts/install-tools.sh` pz 组)

# Project Zero 工具参考:projectzero 组册

> Windows 沙箱攻击面分析 / .NET 后渗透源码参考(NtObjectManager/NtApiDotNet 系) ｜ 状态:参考克隆 ｜ 组:`install-tools.sh projectzero`

## 版本

- 四仓都由 pins.sh 的 `GIT_PIN` 锁定提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;解析日 2026-10-10;oleviewdotnet 带 submodules 做浅克隆;NtApiDotNet 是嵌套子模块。浅克隆会把它拉丢;`clone_pin` 的第三参 `submodules` 用来拉这个子模块。
- 克隆统一经 `GITHUB_MIRROR`。规定见 [params.md](../../params.md)。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_projectzero`。
- 四仓的版本、来源与路径在文末成员清单。
- 有 dotnet 时,尽力执行 `dotnet build sandbox-attacksurface-analysis-tools.sln -c Release`。
- 构建输出被丢弃。成功或失败只 echo,不阻塞本组。

## 文件

- 四个目录直接放在 `/opt` 下。
- 它们不放进 `/opt/c2dev-ref`、`/opt/payload-ref`、`/opt/tradecraft-ref`。
- 幂等判据是 `-d <目录>/.git`。
- `/opt/pz-sandbox-tools` 的 `.git` 不在时,先 `rm -rf` 再重新克隆。

## 配置

- 无配置写入。

## 离线行为

- 支持读取已在盘上的参考库。见 [offline.md](../../offline.md);四仓在运行时依赖 Windows,通过 p/invoke 调用 ntdll;在 Linux 容器里,价值是 syscall 与结构的源码参考;读这些文件不访问网络。
- 关闭 eth0 后,`ls /opt/pz-sandbox-tools /opt/oleviewdotnet` 退 0。

## 限制

- dotnet build 的成败不作为安装是否完成的判据;多目标、旧 framework 的工程在 noble 上经常失败。脚本只 echo 这个结果;编译失败不影响把源码当作参考。
- 这些 .NET 项目只作参考代码。后渗透要用时再编译。见 [known-issues.md](../../known-issues.md)。
- mono、xbuild、dotnet 10 的构建步骤不在本仓;tyranid 三件与 sandbox 工具同一类:Windows 参考,在 Linux 上主要使用源码。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [params.md](../../params.md)

## 成员清单

| 仓 | 版本 | 来源 | 路径 |
|---|---|---|---|
| sandbox-attacksurface-analysis-tools | GIT_PIN 锁定 sha | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools) | /opt/pz-sandbox-tools(有 dotnet 时尽力 `dotnet build` Release) |
| DotNetToJScript | GIT_PIN 锁定 sha | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) | /opt/DotNetToJScript |
| windows-logical-eop-workshop | GIT_PIN 锁定 sha | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) | /opt/windows-logical-eop-workshop(EOP 教材) |
| oleviewdotnet | GIT_PIN 锁定 sha(含子模块浅克隆) | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) | /opt/oleviewdotnet |

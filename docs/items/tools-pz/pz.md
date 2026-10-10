# Project Zero 工具参考(pz 组册)

> Windows 沙箱攻击面分析 / .NET 后渗透源码参考(NtObjectManager/NtApiDotNet 系) ｜ 状态:参考克隆 ｜ 组:`install-tools.sh pz`

- **版本钉**:四仓全部 pins.sh `GIT_PIN` 钉 sha(clone_pin,幂等:HEAD==钉即跳过;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;oleviewdotnet 带 submodules 浅克隆(NtApiDotNet 是嵌套子模块,浅克隆会拉丢,clone_pin 第三参 submodules);统一经 GITHUB_MIRROR(口径见 [params.md](../../params.md))
- **来源与安装**:`scripts/install-tools.sh install_pz` 段。成员表:

| 仓 | 版本 | 来源 | 落点 |
|---|---|---|---|
| sandbox-attacksurface-analysis-tools | GIT_PIN 钉 sha | [googleprojectzero/sandbox-attacksurface-analysis-tools](https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools) | /opt/pz-sandbox-tools(有 dotnet 时尽力 `dotnet build` Release) |
| DotNetToJScript | GIT_PIN 钉 sha | [tyranid/DotNetToJScript](https://github.com/tyranid/DotNetToJScript) | /opt/DotNetToJScript |
| windows-logical-eop-workshop | GIT_PIN 钉 sha | [tyranid/windows-logical-eop-workshop](https://github.com/tyranid/windows-logical-eop-workshop) | /opt/windows-logical-eop-workshop(EOP 教材) |
| oleviewdotnet | GIT_PIN 钉 sha(含子模块浅克隆) | [tyranid/oleviewdotnet](https://github.com/tyranid/oleviewdotnet) | /opt/oleviewdotnet |

- **落点**(批量机制):`/opt` 直挂四目录(不在 [ADR-0002](../../adr/ADR-0002-reference-clone-three-axis.md) 三轴内);幂等判据 `-d <目录>/.git`;pz-sandbox-tools 不在时 rm -rf 重克隆
- **配置与缓存**:有 dotnet 时尽力 `dotnet build sandbox-attacksurface-analysis-tools.sln -c Release`(输出吞掉,成败只 echo 不阻塞);无配置写入
- **离线行为**:✅ 断网冒烟「参考库在位」覆盖(78/0,见 [offline.md](../../offline.md) §验证);四仓运行时强依赖 Windows(p/invoke ntdll),Linux 容器里价值是 syscall/结构文档级源码参考,读盘无网络依赖。验证:`ip link set eth0 down` 后 `ls /opt/pz-sandbox-tools /opt/oleviewdotnet` 退 0
- **坑与留痕**:dotnet build 成败未登记,[推断:] 多目标旧 framework 在 noble 上常见失败(脚本注释口径,源码参考不受影响);用户裁定(2026-10-08):这些 .NET 项目只当参考代码,后渗透用到时再编(留痕 [known-issues](../../known-issues.md));noble mono/xbuild/dotnet10 构建路径有 grok 调研方案(`/tmp/pi-rs-dotnetfx-plan.md`,链接口径,全文不入库);tyranid 三件套与 sandbox 工具同属性——Windows 参考系,Linux 下源码价值为主

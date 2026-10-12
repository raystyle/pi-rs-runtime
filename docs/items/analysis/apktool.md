# apktool

> APK 反编译与重打包 ｜ 状态:已装 ｜ 组:`install-tools.sh analysis`

## 版本

- `APKTOOL_VERSION=2.12.0`。脚本带该默认值。环境变量可覆盖。
- 从 GitHub release 按该版本下载。
- 无校验和。

## 来源与安装

- 上游:[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool)。项目站:[apktool.org](https://apktool.org)。
- 脚本:`install-tools.sh` 的 `install_analysis`。
- 经 `GITHUB_MIRROR` 下载 `apktool_2.12.0.jar`。
- 文件存为 `/opt/apktool/apktool.jar`。
- 幂等判据:`have apktool`。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/apktool/apktool.jar | jar 本体 |
| /usr/local/bin/apktool | wrapper。`printf` 写出,`chmod +x` |

- wrapper 内容:`#!/bin/sh`,然后 `exec java -jar /opt/apktool/apktool.jar "$@"`。

## 配置

- 无工具配置。脚本不写配置文件。
- `java` 由 `install-runtimes.sh` 的 sdkman 组提供。
- `/usr/local/bin/java` 链接 sdkman current 的 temurin。

## 离线行为

- 未验证。
- jar 与 wrapper 都在本地路径。
- 关闭 eth0 后,`apktool --version` 退出码 0 为判定命令。

## 限制

- 无。

## 参见

- [analysis.md](analysis.md)
- [offline.md](../../offline.md)

# apktool

> APK 反编译与重打包 ｜ 状态:已装 ｜ 组:`install-tools.sh p0`

- **版本钉**:`APKTOOL_VERSION=2.12.0`(脚本默认,env 可覆盖);GitHub release 钉版直下,无校验和
- **来源与安装**:[iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool) releases([apktool.org](https://apktool.org))→ `apktool_2.12.0.jar` 经 GITHUB_MIRROR 直下存 `/opt/apktool/apktool.jar`;幂等判据 `have apktool`
- **落点**:jar 本体 `/opt/apktool/apktool.jar`;入口 `/usr/local/bin/apktool` 是 printf 写出的 wrapper:`#!/bin/sh` + `exec java -jar /opt/apktool/apktool.jar "$@"`(chmod +x)
- **配置与缓存**:无(脚本不写配置;`java` 依赖由 `install-runtimes.sh sdkman` 组提供,`/usr/local/bin/java` 链 sdkman current 的 temurin)
- **离线行为**:☐ [推断:jar 与 wrapper 全本地,运行不触网];逐件断网冒烟未单列登记。验证:`ip link set eth0 down` 后 `apktool --version` 退 0
- **坑与留痕**:无

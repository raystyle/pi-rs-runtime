# temurin JDK 多版本(8/11/17/21/25)

> Adoptium temurin 多主版本并存,sdkman 本地路径注册 ｜ 状态:已装(批量册) ｜ 组:`install-runtimes.sh sdkman`

- **版本钉**:主版本钉 `JAVA_VERSIONS="8 11 17 21 25"`(lib/common.sh;25 为新 LTS);小版本由 pins.sh `TEMURIN_PIN_8/11/17/21/25` 钉(当前 8u504b01 / 11.0.32.1_1 / 17.0.20.1_1 / 21.0.12.1_1 / 25.0.4.1_1;解析日 2026-10-10,空钉回退 tuna Adoptium 目录 listing 取最新),升级跑 scripts/resolve-pins.sh
- **来源与安装**:[adoptium.net](https://adoptium.net) temurin → tuna `ADOPTIUM_MIRROR=$TUNA/Adoptium`(阿里云无 Adoptium 镜像);tarball 解 `/opt/jdk/temurin-<ver>`(`--strip-components=1`),再 `sdk install java <ver>-tem /opt/jdk/temurin-<ver>` 以本地路径注册进 [sdkman](sdkman.md);循环最后一个主版本(25)`sdk default java` 成默认
- **落点**(批量机制):`/opt/jdk/temurin-<小版本>/` 一主版本一目录;sdkman `candidates/java/<ver>-tem` 指本地路径、`candidates/java/current` 指默认版;`/usr/local/bin/java`、`/usr/local/bin/javac` 软链 current(非登录 shell 直可用);架构映射 amd64→x64、arm64→aarch64

| 主版本 | sdkman 坐标 | 小版本取法 | 默认 |
|---|---|---|---|
| 8 | `<ver>-tem` | TEMURIN_PIN_8(空钉回退目录取最新) | |
| 11 | `<ver>-tem` | 同上 | |
| 17 | `<ver>-tem` | 同上 | |
| 21 | `<ver>-tem` | 同上 | |
| 25 | `<ver>-tem` | 同上 | ✅(循环最后一个) |

- **配置与缓存**(批量机制):`JAVA_HOME` 由 `/etc/profile.d/sdkman.sh` 兜底为 `candidates/java/current`(见 [sdkman](sdkman.md));JDK 本体无库缓存——Java 依赖固化在 `/opt/m2`,属 [maven](maven.md) 册(install-libcache.sh java 组)
- **离线行为**:✅ 本地编译/运行不触网;断网冒烟 78/0 含 `mvn -o` 离线构建(走默认 JDK,口径见 [offline.md](../../offline.md) §验证)。验证:`ip link set eth0 down` 后 `java -version && javac -version` 退 0
- **坑与留痕**:幂等判据双查——`/opt/jdk/temurin-<ver>` 目录存在跳过下载、`sdk list java` 已见 `<ver>-tem` 跳过注册;tuna 上架新小版本时重跑会并存多小版本(目录名含小版本),旧目录不自动清;目录 listing 取不到件时该主版本跳过不中断(`continue`),下轮补

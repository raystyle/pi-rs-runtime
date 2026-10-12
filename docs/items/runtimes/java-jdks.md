# temurin JDK 多版本:8/11/17/21/25

> Adoptium temurin 多主版本并存(批量册),sdkman 本地路径注册 ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman`

## 版本

- 主版本号 `JAVA_VERSIONS="8 11 17 21 25"`(`lib/common.sh`)。25 为新 LTS。
- 小版本由 pins.sh 的 `TEMURIN_PIN_8/11/17/21/25` 锁定。
- 当前值为 8u504b01、11.0.32.1_1、17.0.20.1_1、21.0.12.1_1、25.0.4.1_1(解析日 2026-10-10)。
- 未写锁定版本回退到 tuna Adoptium 目录 listing,取最新。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。

## 来源与安装

- 上游:[adoptium.net](https://adoptium.net) 的 temurin。
- 镜像:`ADOPTIUM_MIRROR=$TUNA/Adoptium`。阿里云没有 Adoptium 镜像。
- tarball 解到 `/opt/jdk/temurin-<ver>`(`--strip-components=1`)。
- 再执行 `sdk install java <ver>-tem /opt/jdk/temurin-<ver>`,以本地路径注册进 [sdkman 册](sdkman.md)。
- 循环的最后一个主版本(25)执行 `sdk default java`,成为默认。
- 架构映射:amd64 到 x64,arm64 到 aarch64。

## 文件

- `/opt/jdk/temurin-<小版本>/` 是一主版本一目录。
- sdkman 的 `candidates/java/<ver>-tem` 指向本地路径。
- `candidates/java/current` 指向默认版。
- `/usr/local/bin/java` 与 `/usr/local/bin/javac` 软链到 current。非登录 shell 可以直接用。

## 配置

- `JAVA_HOME` 由 `/etc/profile.d/sdkman.sh` 兜底为 `candidates/java/current`。见 [sdkman 册](sdkman.md)。
- JDK 本体无库缓存。
- Java 依赖固化在 `/opt/m2`,属 [maven 册](maven.md)(`install-libcache.sh` 的 java 组)。

## 离线行为

- 支持:本地编译与运行不访问网络。
- `mvn -o` 的离线构建走默认 JDK。记录见 [offline.md](../../offline.md) 验证节,细节在 [maven 册](maven.md)。
- 验证:关闭 eth0 后,`java -version && javac -version` 退出码 0。

## 限制

- 幂等判据分两步。`/opt/jdk/temurin-<ver>` 目录存在则跳过下载。
- `sdk list java` 已见 `<ver>-tem` 则跳过注册。
- tuna 上架新小版本时,重跑会并存多个小版本。目录名含小版本。旧目录不自动清除。
- 目录 listing 取不到件时,该主版本 `continue` 跳过,不中断其余主版本。
- 该次执行不安装被跳过的主版本。再次执行该组时安装。

## 参见

- [sdkman 册](sdkman.md)
- [maven 册](maven.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: javac kind=runtime path=/usr/local/bin/javac note=JDK 编译器入口

## 成员清单

| 主版本 | sdkman 坐标 | 小版本取法 | 默认 |
|---|---|---|---|
| 8 | `<ver>-tem` | TEMURIN_PIN_8(未写锁定版本回退目录取最新) | |
| 11 | `<ver>-tem` | 同上 | |
| 17 | `<ver>-tem` | 同上 | |
| 21 | `<ver>-tem` | 同上 | |
| 25 | `<ver>-tem` | 同上 | 过,(循环最后一个) |

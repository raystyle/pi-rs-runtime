# maven

> Java 构建与依赖管理(本地仓 /opt/m2 双用户共享) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman` 内直装 + `install-libcache.sh java`(依赖固化)

## 版本

- `MAVEN_VERSION=3.9.16`(`lib/common.sh`)。

## 来源与安装

- 上游:[maven.apache.org](https://maven.apache.org) 的发行包。
- 镜像:`MAVEN_MIRROR=$ALIYUN/apache/maven`(common.sh 的当前默认)。
- 文件 `apache-maven-3.9.16-bin.tar.gz` 解到 `/opt/maven`(`--strip-components=1`)。
- `mvn` 链到 `/usr/local/bin`。
- 幂等判据:`have mvn`。

## 文件

- 安装目录 `/opt/maven`。
- 入口 `/usr/local/bin/mvn`。
- 本地仓 `/opt/m2`。
- libcache java 组的预热工程在 `/opt/maven-prewarm`。
- `versions:resolve-ranges` 把 `[0,)` 区间解析成精确版本,写回 pom。
- 然后 `dependency:go-offline` 拉取字节。
- 默认 profile 是 BC、ASM、Jackson、Spring、hutool 等当前安全版。
- study profile 锁定 fastjson、log4j-core、shiro 等 CVE 复现坐标。
- smali 与 baksmali 3.0.10 经 GMaven。坐标见 [known-issues.md](../../known-issues.md)。

## 配置

- `/opt/maven/conf/settings.xml` 是安装目录级配置,对所有调用生效,不依赖 shell。
- `localRepository=/opt/m2`。
- mirror 名 `aliyunmaven`,`mirrorOf=central`,url 为 `MAVEN_DEP_MIRROR=https://maven.aliyun.com/repository/public`。
- 非交互 shell 没有 `JAVA_HOME`。构建脚本从 [sdkman 册](sdkman.md) 的 current 推导。

## 离线行为

- 不做默认离线配置。maven 没有干净的「配置离线,再由 CLI 覆盖」这一对。见 [offline.md](../../offline.md) 第 4 节。
- 支持:手工 `mvn -o`。root 与 ubuntu 均可。
- 验证:关闭 eth0 后,`cd /opt/maven-prewarm && mvn -o -B -DskipTests package` 退出码 0。

## 限制

- `localRepository` 锁定在 `/opt/m2`。若留默认 `~/.m2`,root 与 ubuntu 各有一份,离线都用不上。
- settings.xml 写在安装目录,不写 `~/.m2/settings.xml`,这样非登录 shell(`incus exec`)也能读到。
- `mirrorOf=central` 不拦截 pom 里显式声明的 GMaven 仓。smali 坐标靠这个仓。
- 预热 pom 由 heredoc 写出。heredoc 里的 shell 注释会进入 pom,Maven 报 Non-parseable POM。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [sdkman 册](sdkman.md)
- [java 库缓存](../libcache/java.md)

## rctl 面,机器行

- rctl: mvn kind=runtime path=/usr/local/bin/mvn note=maven 入口名

## rctl 面,机器行

- rctl: maven-prewarm kind=cache path=/opt/maven-prewarm note=maven 预热工程(构建期解析缓存)

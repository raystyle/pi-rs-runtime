# Java 库缓存:maven /opt/m2 + smali/baksmali CLI

> Java 依赖字节固化进 /opt/m2(默认 profile 安全新版 + study profile CVE 复现坐标)+ smali/baksmali dex 汇编/反汇编 CLI ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh java`(前置 `install-runtimes.sh sdkman` 的 maven 与 JDK)

## 版本

- 默认 profile 的 16 件写 `[0,)` 区间。
- 构建日执行 `mvn versions:resolve-ranges`,把区间解析成精确版本。
- 解析结果写回 `/opt/maven-prewarm/pom.xml`。
- 写回的 pom 即锁文件。
- 重跑时该解析是幂等的。
- 锁已入库 `scripts/lock/java/pom.xml`。
- 有锁时直接 `dependency:go-offline` 消费。
- 再生执行 `scripts/sync-locks.sh`。
- `dependency:go-offline` 把字节拉进 /opt/m2。
- smali 与 smali-baksmali 锁定 3.0.10。
- study profile 的 8 件全部锁定精确旧版。

## 来源与安装

- Maven Central 经阿里云镜像。
- 镜像写在 `/opt/maven/conf/settings.xml` 的 `mirrorOf=central`,即 `MAVEN_DEP_MIRROR`。
- google/smali 发布在 GMaven(maven.google.com)。
- 两个 pom 都显式声明 `<repository><id>gmaven</id>`。
- settings 的 `mirrorOf=central` 不拦截这个仓库。
- 脚本:`scripts/install-libcache.sh` 的 `install_java`。

默认 profile 依赖(18 件):

| 坐标 | 版本 |
|---|---|
| org.bouncycastle:bcprov-jdk18on / bcpkix-jdk18on | `[0,)` 构建日解析 |
| org.ow2.asm:asm / asm-commons / asm-util | 同上 |
| org.javassist:javassist | 同上 |
| com.fasterxml.jackson.core:jackson-databind | 同上 |
| com.google.code.gson:gson | 同上 |
| org.springframework:spring-core / spring-beans / spring-context | 同上 |
| com.nimbusds:nimbus-jose-jwt | 同上 |
| org.jsoup:jsoup | 同上 |
| com.squareup.okhttp3:okhttp | 同上 |
| cn.hutool:hutool-all | 同上 |
| info.picocli:picocli | 同上 |
| com.android.tools.smali:smali / smali-baksmali(GMaven) | 3.0.10 锁定版本,dexlib2 经传递依赖带入 |

study profile(`-Pstudy`,activeByDefault=false,CVE 复现坐标,8 件精确锁定):

| 坐标 | 版本 | 研究指向 |
|---|---|---|
| com.alibaba:fastjson | 1.2.47 / 1.2.68 / 1.2.83 | autotype 反序列化绕过链多版本对照 |
| org.apache.logging.log4j:log4j-core | 2.14.1 | Log4Shell(CVE-2021-44228,影响面 2.0-beta9~2.14.1) |
| org.apache.shiro:shiro-core | 1.2.4 | Shiro-550 rememberMe 反序列化(CVE-2016-4437) |
| commons-collections:commons-collections | 3.2.1 | 反序列化 gadget 链经典版 |
| commons-io:commons-io / commons-codec:commons-codec | 2.20.0 / 1.20.0 | 配套对照锁定版本 [推断:] |

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/m2 | maven 本地仓 |
| /opt/maven-prewarm/pom.xml | 解析后的锁定版本工程 |
| /opt/smali-cli/pom.xml | mini-pom;copy-dependencies 落到 /opt/smali/lib;解析基本使用 /opt/m2 缓存 |
| /opt/smali/lib | smali/baksmali thin jar,加 17 个传递依赖 jar |
| /usr/local/bin/smali、/usr/local/bin/baksmali | sh wrapper,`java -cp "/opt/smali/lib/*"`,分别启动 `com.android.tools.smali.smali.Main` 与 `baksmali.Main` |

## 配置

- `/opt/maven/conf/settings.xml` 由 runtimes 的 sdkman 组写入。
- 其中 `<localRepository>` 固定为 `/opt/m2`。
- 该文件不依赖 shell。
- root 与 ubuntu 共用这一份本地仓。
- 非交互 shell 没有 JAVA_HOME。
- 脚本从 sdkman 的 current 推出 JAVA_HOME。

## 离线行为

- 支持:断网冒烟批覆盖 `mvn -o`,见 [offline.md](../../offline.md) 的验证节。
- study profile 的字节与默认 profile 同一批进入 /opt/m2。
- 支持:smali 与 baksmali 的断网往返。
- 验证:关闭 eth0 后,`cd /opt/maven-prewarm && mvn -o -q dependency:resolve`。
- 验证:关闭 eth0 后执行 `printf '.class public LA;\n.super Ljava/lang/Object;\n' > a.smali && smali assemble a.smali -o a.dex && baksmali disassemble a.dex`。
- maven 不做默认离线。
- 原因是没有「配置离线,再用 CLI 覆盖」这一对开关。
- 离线构建手工加 `-o`。
- 边界见 [offline.md](../../offline.md) 第 4 节。

## 限制

- `org.jf:dexlib2` 在阿里云与华为镜像上没有该件。
- 对这些镜像的请求返回 404。
- smali 的坐标是 GMaven 的 `com.android.tools.smali`。
- 不是 Maven Central 的 `com.google.smali`。
- 锁定 3.0.10 之后,dexlib2 经传递依赖回到 /opt/m2。
- 说明见 [known-issues.md](../../known-issues.md)。
- 官方 fat jar 只能源码构建,且限于 JDK 11。
- 因此使用 thin jar、依赖 jar 和 classpath wrapper。
- 在 heredoc 里写 shell 注释会进入 pom.xml。
- 结果是 Non-parseable POM。
- 默认 profile 与 study profile 分两次执行 mvn。
- 每一次失败都不中断另一次。
- study 失败不影响默认 profile。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: smali kind=tool path=/usr/local/bin/smali env=逆向环境 note=smali 汇编 CLI(/opt/smali-cli 挂钩)
- rctl: baksmali kind=tool path=/usr/local/bin/baksmali env=逆向环境
- rctl: smali-home kind=ref path=/opt/smali note=smali 仓克隆(smali-cli 装配源)

# Java 库缓存(maven /opt/m2 + smali/baksmali CLI)

> Java 依赖字节固化进 /opt/m2(默认 profile 安全新版 + study profile CVE 复现坐标)+ smali/baksmali dex 汇编/反汇编 CLI ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh java`(前置 `install-runtimes.sh sdkman` 的 maven 与 JDK)

- **版本钉**:默认 profile 16 件写 `[0,)` 区间,构建日 `mvn versions:resolve-ranges` 解析成精确版本写回 `/opt/maven-prewarm/pom.xml`(写回的 pom 即锁文件,重跑幂等;锁文件在镜像侧,repo 侧回收是 PROGRESS.md 待办 3),再 `dependency:go-offline` 把字节拉进 /opt/m2;smali/smali-baksmali 钉 3.0.10;study profile 8 件全钉精确旧版
- **来源与安装**:Maven Central 经阿里云镜像(`/opt/maven/conf/settings.xml` 的 `mirrorOf=central`,即 `MAVEN_DEP_MIRROR`);google/smali 发布在 GMaven(maven.google.com),两个 pom 均显式声明 `<repository><id>gmaven</id>`——settings 的 `mirrorOf=central` 不拦它;脚本段 `scripts/install-libcache.sh install_java`

  默认 profile 依赖(18 件):

  | 坐标 | 钉版 |
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
  | com.android.tools.smali:smali / smali-baksmali(GMaven) | 3.0.10 钉版,dexlib2 经传递依赖带入 |

  study profile(`-Pstudy`,activeByDefault=false,CVE 复现坐标,8 件精确钉):

  | 坐标 | 版本 | 研究指向 |
  |---|---|---|
  | com.alibaba:fastjson | 1.2.47 / 1.2.68 / 1.2.83 | autotype 反序列化绕过链多版本对照 |
  | org.apache.logging.log4j:log4j-core | 2.14.1 | Log4Shell(CVE-2021-44228,影响面 2.0-beta9~2.14.1) |
  | org.apache.shiro:shiro-core | 1.2.4 | Shiro-550 rememberMe 反序列化(CVE-2016-4437) |
  | commons-collections:commons-collections | 3.2.1 | 反序列化 gadget 链经典版 |
  | commons-io:commons-io / commons-codec:commons-codec | 2.20.0 / 1.20.0 | 配套对照钉版 [推断:] |

- **落点**:`/opt/m2`(maven 本地仓);`/opt/maven-prewarm/pom.xml`(解析后钉版工程);`/opt/smali-cli/pom.xml`(mini-pom,copy-dependencies 落 /opt/smali/lib,解析基本吃 /opt/m2 缓存);`/opt/smali/lib`(smali/baksmali thin jar + 17 个传递依赖 jar);`/usr/local/bin/smali`、`/usr/local/bin/baksmali`(sh wrapper,`java -cp "/opt/smali/lib/*"` 分别起 `com.android.tools.smali.smali.Main` 与 `baksmali.Main`)
- **配置与缓存**:`/opt/maven/conf/settings.xml`(runtimes sdkman 组写)写死 `<localRepository>/opt/m2</localRepository>`——不依赖 shell,root/ubuntu 共用一份本地仓;非交互 shell 没有 JAVA_HOME,脚本从 sdkman current 推
- **离线行为**:✅ 断网 `mvn -o` 在断网冒烟批覆盖(见 [offline.md](../../offline.md) 验证节);study profile 字节同批进 /opt/m2。✅ smali/baksmali 断网 roundtrip 实证。验证:`ip link set eth0 down` 后 `cd /opt/maven-prewarm && mvn -o -q dependency:resolve`;`printf '.class public LA;\n.super Ljava/lang/Object;\n' > a.smali && smali assemble a.smali -o a.dex && baksmali disassemble a.dex`。maven 不做默认离线(没有干净的「配置离线+CLI 覆盖」对),手工 `-o`,边界见 [offline.md](../../offline.md) §4
- **坑与留痕**:`org.jf:dexlib2` 国内镜像(aliyun/华为)全无件(实证 404)——google 已把 smali 迁到 GMaven `com.android.tools.smali`(非 Maven Central 的 com.google.smali,早先留痕有误),钉 3.0.10 后 dexlib2 经传递依赖回 /opt/m2,来龙去脉见 [known-issues](../../known-issues.md);官方 fat jar 只源码构建且限 JDK11,故走 thin jar+依赖 jar+classpath wrapper;heredoc 里写 shell 注释会混进 pom.xml 致 Non-parseable POM(实证,见 [diary](../../diary/2026-10-10-offline-rounds.md));默认与 study profile 分两次 mvn 各自 tolerant,study 失败不影响默认

# maven

> Java 构建与依赖管理(本地仓 /opt/m2 双用户共享) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman` 内直装 + `install-libcache.sh java`(依赖固化)

- **版本钉**:`MAVEN_VERSION=3.9.16`(lib/common.sh)
- **来源与安装**:[maven.apache.org](https://maven.apache.org) 发行包 → 阿里云 `MAVEN_MIRROR=$ALIYUN/apache/maven`(common.sh 当前默认)`apache-maven-3.9.16-bin.tar.gz` 解 `/opt/maven`(`--strip-components=1`),`mvn` 链 `/usr/local/bin`;幂等判据 `have mvn`
- **落点**:`/opt/maven`;`/usr/local/bin/mvn`;本地仓 `/opt/m2`(libcache java 组 `/opt/maven-prewarm` 工程固化:`versions:resolve-ranges` 把 `[0,)` 区间解析成精确版本写回 pom,再 `dependency:go-offline` 拉字节;默认 profile 为 BC/ASM/Jackson/Spring/hutool 等当前安全版,study profile 钉 fastjson/log4j-core/shiro 等 CVE 复现坐标;smali/baksmali 3.0.10 经 GMaven,坐标留痕见 [known-issues](../../known-issues.md))
- **配置与缓存**:`/opt/maven/conf/settings.xml`(安装目录级,对所有调用生效,不依赖 shell):`localRepository=/opt/m2` + mirror `aliyunmaven`(`mirrorOf=central`,url `MAVEN_DEP_MIRROR=https://maven.aliyun.com/repository/public`);非交互 shell 无 JAVA_HOME,构建脚本从 [sdkman](sdkman.md) current 推
- **离线行为**:不做默认离线配置(maven 无干净「配置离线+CLI 覆盖」对,见 [offline.md](../../offline.md) §4);✅ 手工 `mvn -o` 断网实证(冒烟 78/0 覆盖,root/ubuntu 双视角)。验证:`ip link set eth0 down` 后 `cd /opt/maven-prewarm && mvn -o -B -DskipTests package` 退 0
- **坑与留痕**:localRepository 钉 /opt/m2 的裁定——留默认 `~/.m2` 则 root 与 ubuntu 各一份,离线都救不了;settings.xml 写安装目录而非 `~/.m2/settings.xml` 正是为非登录 shell(incus exec)生效([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));`mirrorOf=central` 不拦 pom 显式声明的 GMaven 仓(smali 坐标靠它);预热 pom 的 heredoc 里写 bash 注释曾混进产物致 Non-parseable POM(血泪教训,见 [diary 2026-10-10](../../diary/2026-10-10-offline-rounds.md))

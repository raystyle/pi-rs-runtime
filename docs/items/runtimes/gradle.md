# gradle

> JVM 构建链(共享可写家目录 /opt/gradle-home) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman` 内直装

- **版本钉**:`GRADLE_VERSION=8.14.3`(lib/common.sh)
- **来源与安装**:[gradle.org](https://gradle.org) 发行包 → 阿里云 distributions 镜像 `https://mirrors.aliyun.com/gradle/distributions/v8.14.3/gradle-8.14.3-bin.zip`,unzip 落 `/opt/gradle/gradle-8.14.3/`,`gradle` 链 `/usr/local/bin`;幂等判据 `have gradle`
- **落点**:`/opt/gradle/gradle-*/`;`/usr/local/bin/gradle`;家目录 `/opt/gradle-home`(内含 `init.d/mirrors.gradle`)
- **配置与缓存**:`/etc/profile.d/gradle.sh` export `GRADLE_USER_HOME=/opt/gradle-home`(登录 shell 面);非登录 shell(incus exec)不读 profile.d,兜底靠 root 与 ubuntu 的 `~/.gradle` 软链到 /opt/gradle-home(gradle 默认家目录位);家目录要可写(daemon/锁),`shared_writable_cache` 走 piopt 共同组 + 默认 ACL,**不 1777**(任意用户可写就能换掉 root 下次用的缓存,grok F1;权限模型裁定见 [ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md));`init.d/mirrors.gradle` 双段盖镜像:`allprojects` repositories 指阿里云 public + gradle-plugin,`settingsEvaluated` 的 pluginManagement 指阿里云 gradle-plugin + gradlePluginPortal()——只改 allprojects 盖不住 settings 的 pluginManagement
- **离线行为**:不做默认离线配置([offline.md](../../offline.md) §4),手工 `gradle --offline`;☐ [推断:]断网 `gradle --offline` 构建未专项实证——libcache 无 gradle 组,`/opt/gradle-home` 无依赖预热,离线构建仅限缓存已有件;注意 `./gradlew` 会按 distributionUrl 重新下载发行包,离线期用系统 `gradle` 命令。验证:`ip link set eth0 down` 后 `gradle --version` 退 0(构建面待实证)
- **坑与留痕**:GRADLE_USER_HOME env 在非登录 shell 失效是离线轮缺口①,家目录软链兜底由此而来([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));软链指向 root 755 曾致 ubuntu AccessDenied,实证 setgid 单独压不住 umask 022(新子目录 g=r-x),压住 umask 的是默认 ACL,`setfacl` 缺失时 `shared_writable_cache` 直接 return 1 不静默降级([ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md))

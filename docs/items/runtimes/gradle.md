# gradle

> JVM 构建链(共享可写家目录 /opt/gradle-home) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman` 内直装

## 版本

- `GRADLE_VERSION=8.14.3`(`lib/common.sh`)。

## 来源与安装

- 上游:[gradle.org](https://gradle.org) 的发行包。
- 镜像:`https://mirrors.aliyun.com/gradle/distributions/v8.14.3/gradle-8.14.3-bin.zip`。
- unzip 落到 `/opt/gradle/gradle-8.14.3/`;`gradle` 链到 `/usr/local/bin`;幂等判据:`have gradle`。

## 文件

- 发行目录 `/opt/gradle/gradle-*/`;入口 `/usr/local/bin/gradle`;家目录 `/opt/gradle-home`,内含 `init.d/mirrors.gradle`。

## 配置

- `/etc/profile.d/gradle.sh` 导出 `GRADLE_USER_HOME=/opt/gradle-home`。这是登录 shell 面。
- 非登录 shell(`incus exec`)不读 profile.d。
- 兜底是 root 与 ubuntu 的 `~/.gradle` 软链到 `/opt/gradle-home`。这是 gradle 的默认家目录位。
- 家目录要可写,因为有 daemon 与锁;`shared_writable_cache` 走 piopt 共同组,加默认 ACL;不使用 1777。任意用户可写就能换掉 root 下次用的缓存;权限模型见 [offline.md](../../offline.md) 第 5 节;`init.d/mirrors.gradle` 用两段盖镜像。
- `allprojects` 的 repositories 指向阿里云 public 与 gradle-plugin。
- `settingsEvaluated` 的 pluginManagement 指向阿里云 gradle-plugin 与 `gradlePluginPortal()`。
- 只改 allprojects 盖不住 settings 里的 pluginManagement。

## 离线行为

- 不做默认离线配置。见 [offline.md](../../offline.md) 第 4 节;手工使用 `gradle --offline`;支持:关闭 eth0 后,`gradle --version` 退出码 0。
- 未验证:断网 `gradle --offline` 构建。libcache 没有 gradle 组。`/opt/gradle-home` 没有依赖预热。离线构建只覆盖缓存里已经有的件。
- `./gradlew` 会按 distributionUrl 重新下载发行包。离线期用系统 `gradle` 命令。

## 限制

- 非登录 shell 读不到 `GRADLE_USER_HOME`。家目录软链是这个缺口的兜底;软链目标若是 root 拥有的 755 目录,ubuntu 访问返回 AccessDenied;setgid 单独压不住 umask 022。新子目录的组权限是 `g=r-x`;压住 umask 的是默认 ACL;`setfacl` 缺失时,`shared_writable_cache` 直接返回 1,不静默降级。

## 参见

- [offline.md](../../offline.md)
- [sdkman 册](sdkman.md)

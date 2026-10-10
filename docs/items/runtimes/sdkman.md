# sdkman 本体

> 多版本 Java 工具链管理入口(`sdk` 命令) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman`

- **版本钉**:官方安装器最新(`get.sdkman.io` 直下,未钉);装后 sed 幂等改写 etc/config 三键:`sdkman_auto_env=true`、`sdkman_auto_selfupdate=false`、`sdkman_auto_answer=true`
- **来源与安装**:[sdkman.io](https://sdkman.io) → `curl -fSL https://get.sdkman.io` 得安装器,`SDKMAN_DIR=/usr/local/sdkman bash sdkman-init.sh` 安装;先 apt 装 `unzip zip`(安装器与候选包解包依赖);幂等判据:`/usr/local/sdkman` 目录已存在则跳过安装器
- **落点**:`/usr/local/sdkman`(bin/、etc/config、candidates/);[temurin JDK](java-jdks.md) 以本地路径注册进 `candidates/java/`;maven/gradle 不走 sdkman 候选,直装 /opt(见 [maven](maven.md)、[gradle](gradle.md))
- **配置与缓存**:`/etc/profile.d/sdkman.sh` export `SDKMAN_DIR=/usr/local/sdkman`、source `sdkman-init.sh`、`JAVA_HOME` 兜底为 `$SDKMAN_DIR/candidates/java/current`;profile.d 只是登录 shell 面,非登录 shell(incus exec)用 `/usr/local/bin/java`、`javac` 软链(指 candidates/java/current,装 JDK 时建立)
- **离线行为**:☐ [推断:]已装候选的 `sdk use`/`sdk current` 是纯本地文件操作,且 auto_selfupdate=false 不触网;`sdk install` 从远端候选拉新件需网——本镜像 java 走 tuna 直拉 tarball + 本地路径注册,不依赖 sdkman 在线面。验证:`ip link set eth0 down` 后 `sdk current` 列出现任候选
- **坑与留痕**:`sdkman-init.sh` 与 `sdk` 主脚本引用未绑定变量,与 `set -u` 冲突——安装脚本内 `set +u` 包裹 source 与 `sdk current`;关 auto_selfupdate 是离线优先裁定的一环(运行期配置不静默自改,[ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md))

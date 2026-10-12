# sdkman 本体

> 多版本 Java 工具链管理入口(`sdk` 命令) ｜ 状态:已装 ｜ 组:`install-runtimes.sh sdkman`

## 版本

- 安装器本体未锁定。pins.sh 未收锁定项。从 `get.sdkman.io` 直下,随官方最新。
- JDK 侧 temurin 小版本由 pins.sh 的 `TEMURIN_PIN_8/11/17/21/25` 锁定。见 [temurin JDK 册](java-jdks.md)。
- 装后用 sed 幂等改写 `etc/config` 的三个键。

| 键 | 值 |
| --- | --- |
| sdkman_auto_env | true |
| sdkman_auto_selfupdate | false |
| sdkman_auto_answer | true |

## 来源与安装

- 上游:[sdkman.io](https://sdkman.io);`curl -fSL https://get.sdkman.io` 取得安装器。
- 安装命令:`SDKMAN_DIR=/usr/local/sdkman bash sdkman-init.sh`。
- 先用 apt 安装 `unzip` 与 `zip`。安装器与候选包解包依赖它们;幂等判据:`/usr/local/sdkman` 目录已存在则跳过安装器。

## 文件

- 根目录 `/usr/local/sdkman`,含 `bin/`、`etc/config`、`candidates/`。
- [temurin JDK 册](java-jdks.md) 以本地路径注册进 `candidates/java/`。
- maven 与 gradle 不走 sdkman 候选,直装到 `/opt`。见 [maven 册](maven.md) 与 [gradle 册](gradle.md)。

## 配置

- `/etc/profile.d/sdkman.sh` 导出 `SDKMAN_DIR=/usr/local/sdkman`。
- 同一文件 source `sdkman-init.sh`。
- `JAVA_HOME` 兜底为 `$SDKMAN_DIR/candidates/java/current`。
- profile.d 只是登录 shell 面。
- 非登录 shell(`incus exec`)使用 `/usr/local/bin/java` 与 `/usr/local/bin/javac`。二者软链到 `candidates/java/current`,在装 JDK 时建立。

## 离线行为

- 未验证:已装候选的 `sdk use` 与 `sdk current`。二者是本地文件操作。`auto_selfupdate=false` 不访问网络。
- `sdk install` 从远端候选拉新件,需要网络;本镜像的 java 从 tuna 直拉 tarball,再以本地路径注册,不依赖 sdkman 的在线面;判定:关闭 eth0 后执行 `sdk current`,期望列出任一已装候选。

## 限制

- `sdkman-init.sh` 与 `sdk` 主脚本引用未绑定变量,与 `set -u` 冲突;安装脚本用 `set +u` 包裹 source 与 `sdk current`;关闭 `auto_selfupdate` 是离线优先的一环。运行期配置不自行改写。

## 参见

- [java-jdks 册](java-jdks.md)
- [maven 册](maven.md)
- [gradle 册](gradle.md)
- [offline.md](../../offline.md)

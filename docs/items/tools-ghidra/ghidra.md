# Ghidra

> NSA 开源软件逆向套件:GUI + analyzeHeadless 无头反编译与静态分析 ｜ 状态:已装 ｜ 组:`install-tools.sh ghidra`

## 版本

- `GHIDRA_VERSION=12.1.3`、`GHIDRA_DATE=20260817`、`GHIDRA_SHA256=93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54`,三者配套锁定在 `scripts/lib/common.sh`;换版本同步换(规定见 [docs/params.md](../../params.md))。
- SHA-256 取自官方发布页;zip 下载后 `sha256sum -c` 校验,失败即 exit 1。

## 来源与安装

- 上游:[ghidra-sre.org](https://ghidra-sre.org)([NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) releases)。
- 官方 releases 无国内镜像;GitHub 直下,不经 GITHUB_MIRROR:`Ghidra_12.1.3_build/ghidra_12.1.3_PUBLIC_20260817.zip`,unzip 进 /opt/ghidra。
- 脚本:`scripts/install-tools.sh` 的 `install_ghidra`。
- 硬依赖 64 位 JDK 21(temurin 21 由 `install-runtimes.sh sdkman` 预装,tuna Adoptium 源);找不到 JDK 21 直接 exit 1。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/ghidra/ghidra_12.1.3_PUBLIC/ | 发行树;脚本按 `ls -d /opt/ghidra/ghidra_*/` 首命中取 |
| /usr/local/bin/ghidraRun → <gdir>ghidraRun | GUI 入口 |
| /usr/local/bin/analyzeHeadless → <gdir>support/analyzeHeadless | 无头分析链 |

- analyzeHeadless 用法:`analyzeHeadless /tmp/ghidra-proj MyProj -import /path/to/bin`。

## 配置

- `<gdir>support/launch.properties` 写 `JAVA_HOME_OVERRIDE=<JDK 21 路径>`,固定 JDK 21,防多版本共存时被默认 JDK(25)抢占。
- JDK 21 取 `ls -d /opt/jdk/temurin-21* /usr/local/sdkman/candidates/java/21*` 首命中。
- 已有该键则 sed 改写,否则追加;写在早退判据 `[ ! -d /opt/ghidra ]` 之外,重跑必校准。
- 运行期项目与缓存无固化。

## 离线行为

- 未验证:GUI 与 analyzeHeadless 均为本地 JVM 进程,不触网。
- 验证:关闭 eth0 后 `analyzeHeadless /tmp/ghidra-proj MyProj -import /bin/ls -deleteProject` 跑完退出码 0。
- 离线机制总表见 [docs/offline.md](../../offline.md)。

## 限制

- `ls` 多 glob 有一个布局不存在即返回 2;pipefail 下赋值会失败退出,JDK 21 取值带 `|| true` 兜底。
- ghidra 是锁定版本带 sha256 校验的件,对照 [known-issues.md](../../known-issues.md) 的「无校验和件」清单属例外。

## 参见

- [docs/params.md](../../params.md)
- [docs/offline.md](../../offline.md)

## rctl 收录行

- rctl: ghidraRun kind=tool path=/usr/local/bin/ghidraRun
- rctl: analyzeHeadless kind=tool path=/usr/local/bin/analyzeHeadless note=无头分析入口

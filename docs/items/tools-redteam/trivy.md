# trivy

> 容器/文件系统漏洞与配置扫描器 ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `TRIVY_VERSION` = v0.75.0(解析日 2026-10-10);未写锁定版本时,回退 `api.github.com` 取 latest tag;`.deb` 经 `GITHUB_MIRROR` 直接下载;升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[aquasecurity/trivy](https://github.com/aquasecurity/trivy)。
- 从 releases 下载 `.deb`,再 `dpkg -i`;被包装的程序安装到 `/usr/bin/trivy`。

## 文件

- `/usr/bin/trivy` 是被包装的程序;`/usr/local/bin/trivy` 是 wrapper;`/usr/local/bin` 在 PATH 前段,wrapper 压过被包装的程序;漏洞库与 Java 库在 `/opt/trivy-db`。

## 配置

- 构建期用 `--download-db-only` 把漏洞库烘焙到 `/opt/trivy-db`;构建期用 `--download-java-db-only` 把 Java 库烘焙到同一目录。
- 烘焙调用 `/usr/bin/trivy`。wrapper 会注入跳过更新,与 `--download-*-only` 冲突。
- 0.75 没有 `--download-checks-only`;`TRIVY_SKIP_CHECK_UPDATE` 留给识别该变量的版本;wrapper 默认 `TRIVY_CACHE_DIR=/opt/trivy-db`;wrapper 默认 `TRIVY_SKIP_DB_UPDATE=true`;wrapper 默认 `TRIVY_SKIP_JAVA_DB_UPDATE=true`;wrapper 默认 `TRIVY_SKIP_CHECK_UPDATE=true`。
- 参数中出现精确的 `--download-*` 时,wrapper 改为直接执行 `/usr/bin/trivy`。
- `/etc/profile.d/trivy.sh` 只导出 `TRIVY_CACHE_DIR=/opt/trivy-db`。
- 该文件是 export 的备份。跳过更新由 wrapper 注入。

## 离线行为

- 支持扫描。
- 关闭 eth0 后,`trivy fs --scanners vuln /etc/hostname` 退 0。
- `/opt/trivy-db` 是构建日的快照;回到有网环境后,重跑 redteam 组会刷新该库。

## 限制

- `.deb` 无校验和。见 [known-issues.md](../../known-issues.md)。
- alias 在非交互 shell(`incus exec`)中不生效。
- 没有 wrapper 时,离线首次运行返回 FATAL `first run cannot skip downloading DB`。
- 跳过数据库下载的行为写在 wrapper 文件里;0.75 起,`--skip-db-update` 不是 root 级持久旗标,只能用环境变量;`--download-*` 按完整旗标匹配;按子串匹配会把路径 `fs ./download-db-only-notes` 误判成下载旗标。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: trivy-db kind=data path=/opt/trivy-db note=漏洞库快照(缺它 trivy 离线 FATAL;构建日快照)

# trivy

> 容器/文件系统漏洞与配置扫描器 ｜ 状态:已装 ｜ 组:`install-tools.sh red`

- **版本钉**:GitHub release latest tag(api.github.com 取),`.deb` 经 GITHUB_MIRROR 直下,无校验和(留痕 known-issues)
- **来源与安装**:[aquasecurity/trivy](https://github.com/aquasecurity/trivy) releases → `dpkg -i` 落 `/usr/bin/trivy`
- **落点**:`/usr/bin/trivy` 真身;`/usr/local/bin/trivy` wrapper(PATH 前段压过真身)
- **配置与缓存**:漏洞库+Java 库构建期烘焙到 `/opt/trivy-db`(`--download-db-only`、`--download-java-db-only`;0.75 无 --download-checks-only,实证);wrapper 注入 `TRIVY_CACHE_DIR=/opt/trivy-db` + `TRIVY_SKIP_DB_UPDATE/TRIVY_SKIP_JAVA_DB_UPDATE/TRIVY_SKIP_CHECK_UPDATE=true`;`/etc/profile.d/trivy.sh` 仅留 export 备份
- **离线行为**:✅ 断网扫描实证(`trivy fs --scanners vuln /etc/hostname`);库是构建日快照,回有网环境重跑 red 组刷新。验证:`ip link set eth0 down` 后上述命令退 0
- **坑与留痕**:alias 在非交互 shell(incus exec)不生效,曾离线 FATAL "first run cannot skip downloading DB"——行为修正必须落 wrapper 文件([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));0.75 起 `--skip-db-update` 不是 root 持久旗标(只能 env);`--download-*` 按精确旗标直通真身,子串匹配会误伤 `fs ./download-db-only-notes` 这类路径(grok 评审)

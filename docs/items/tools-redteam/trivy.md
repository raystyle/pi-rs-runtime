# trivy

> 容器/文件系统漏洞与配置扫描器 ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `TRIVY_VERSION` = v0.75.0(解析日 2026-10-10);未写锁定版本时,回退 `api.github.com` 取 latest tag;`.deb` 经 `GITHUB_MIRROR` 直接下载;升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[aquasecurity/trivy](https://github.com/aquasecurity/trivy)。
- 从 releases 下载 `.deb`,再 `dpkg -i`;被包装的程序安装到 `/usr/bin/trivy`。

## 文件

- `/usr/bin/trivy` 直通(无 wrapper);漏洞库不烤镜像(2026-10-14 瘦身批,2.9G;后续走 MCP 漏洞库服务),首扫在线拉到默认缓存位。

## 配置

- 无 wrapper 与 profile 面(db 不烤后旧道全撤);需要固化库时自设 `TRIVY_CACHE_DIR`。

## 离线行为

- 二进制本地;漏洞扫描需库,离线首扫会快失败(库不烤,2026-10-14 瘦身批)。
- 断网判定改为 `trivy --version` 退 0;在线环境首扫自动拉库。

## 限制

- `.deb` 无校验和。见 [known-issues.md](../../known-issues.md)。
- alias 在非交互 shell(`incus exec`)中不生效。
- 离线首次运行返回 FATAL `first run cannot skip downloading DB`(库不烤后属预期快失败);要离线扫,先用有网环境拉库或后续接 MCP 漏洞库服务。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: trivy-db kind=data path=/opt/trivy-db note=漏洞库(不烤镜像,2026-10-14 瘦身批;后续 MCP)

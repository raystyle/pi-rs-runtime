# jadx

> Java/Android 反编译,DEX/APK 到 Java ｜ 状态:已装 ｜ 组:`install-tools.sh analysis`

## 版本

- `JADX_VERSION=1.5.3`。脚本带该默认值。环境变量可覆盖。
- 从 GitHub release 按该版本下载。
- 无校验和。

## 来源与安装

- 上游:[skylot/jadx](https://github.com/skylot/jadx)。
- 脚本:`install-tools.sh` 的 `install_analysis`。
- 经 `GITHUB_MIRROR` 下载 `jadx-1.5.3.zip`。
- zip 解到 `/opt/jadx`。
- 幂等判据:`have jadx`。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/jadx | zip 根。布局是 `bin/` 与 `lib/`,没有版本目录 |
| /opt/jadx/bin/jadx | 被链接的程序 |
| /opt/jadx/bin/jadx-gui | 同 zip 内的图形入口。未链出 |
| /usr/local/bin/jadx | 软链,目标 `/opt/jadx/bin/jadx` |

## 配置

- 无工具配置。脚本不写配置文件。
- `java` 由 `install-runtimes.sh` 的 sdkman 组提供。
- `/usr/local/bin/java` 链接 sdkman current 的 temurin。

## 离线行为

- 未验证。
- CLI 与 `lib/` 都在本地路径。反编译不访问网络。
- 关闭 eth0 后,`jadx --version` 退出码 0 为判定命令。

## 限制

- 无。

## 参见

- [analysis.md](analysis.md)
- [offline.md](../../offline.md)

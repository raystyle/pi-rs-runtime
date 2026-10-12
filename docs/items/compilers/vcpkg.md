# vcpkg

> C/C++ 库包管理器 + 12 个常用库源码编译集(RE/安全方向实用集) ｜ 状态:已装 ｜ 组:`install-compilers.sh vcpkg`

## 版本

- `GIT_PIN[microsoft/vcpkg]` = e456309491fd875487bf02b8a0dca76c1b1b00cc(解析日 2026-10-10)。
- `clone_pin` 的幂等判据:HEAD 等于该锁定提交则跳过;升级:运行 `scripts/resolve-pins.sh`,再重跑本组;12 个库的版本随 ports 树。同一锁定 sha 把 ports 树锁定;bootstrap 产出的 vcpkg 二进制随该锁定提交;`VCPKG_PKGS` 默认集如下,环境变量可覆盖。

| 库 |
| --- |
| openssl |
| zlib |
| curl |
| sqlite3 |
| libpcap |
| fmt |
| spdlog |
| nlohmann-json |
| rapidjson |
| cpp-httplib |
| mbedtls |
| yara |

## 来源与安装

- 克隆 [microsoft/vcpkg](https://github.com/microsoft/vcpkg) 到 `/opt/vcpkg`。
- 该克隆不经 `GITHUB_MIRROR`,直连 GitHub;`./bootstrap-vcpkg.sh -disableMetrics` 编出本体;先用 apt 安装 flex 与 bison。libpcap 等库的源码构建依赖它们;然后执行 `vcpkg install $VCPKG_PKGS`,逐库源码编译,耗时较长;脚本:`scripts/install-compilers.sh` 的 `install_vcpkg`。

## 文件

- 本体在 `/opt/vcpkg`,含 ports 树与 bootstrap 二进制;库产物在 `installed/` 下,按 triplet 分目录;`/usr/local/bin/vcpkg` 软链指向本体。

## 配置

- `/etc/profile.d/vcpkg.sh` 写入 `VCPKG_ROOT=/opt/vcpkg` 与 PATH。
- 该文件只是登录 shell 的备份面。`incus exec` 的非登录 shell 不读它。说明见 [known-issues.md](../../known-issues.md)。
- 二进制缓存与资产缓存未配置。量大时可设 `VCPKG_BINARY_SOURCES` 或 `X_VCPKG_ASSET_SOURCES`。这是脚本头注释里的规定。

## 离线行为

- 未验证:已装的 12 个库被离线构建消费。头文件与库都是 `installed/` 里的本地文件。
- 未验证:`vcpkg install <新库>` 在断网时失败。ports 树在仓内,源 tarball 走各上游,GitHub 居多。
- 判定:关闭 eth0 后执行 `vcpkg install <未装的库>`,期望立即报错。

## 限制

- 本体克隆与库资产下载都不经 `GITHUB_MIRROR`,直连 GitHub。这是脚本头注释里的规定。
- 克隆失败时先检查 git 是否存在。install-all 的前置批会安装 git。脚本报错原文说明这一点。
- boost 与 grpc 编译时长过高,规定不进默认清单(脚本注释);HEAD 等于锁定的提交则 `clone_pin` 跳过;HEAD 偏离锁定提交则 `rm -rf` 后重取锁定版本;bootstrap 每次重跑。已经引导过则快速通过。

## 参见

- [known-issues.md](../../known-issues.md)
- [offline.md](../../offline.md)

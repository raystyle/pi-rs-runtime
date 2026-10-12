# Zig 编译器

> Zig 工具链(C 交叉编译器;cargo-zigbuild 的 apple-darwin 链接桩) ｜ 状态:已装 ｜ 组:`install-compilers.sh zig` + `install-libcache.sh zig`

## 版本

- `ZIG_VERSION=0.16.0`(`scripts/lib/common.sh`,环境变量可覆盖)。
- 幂等判据:`zig version` 匹配 `^0.16.0` 即跳过。
- tarball 无校验和,未验签。说明见 [known-issues.md](../../known-issues.md)。

## 来源与安装

- 来源:[ziglang.org/download](https://ziglang.org/download/)。国内无镜像,直下。
- 文件名:`zig-<x86_64|aarch64>-linux-0.16.0.tar.xz`。dpkg 架构 amd64 映射 x86_64,arm64 映射 aarch64。其余架构 `exit 1`。
- 解包:`tar --strip-components=1` 进入 `/opt/zig`。
- 脚本:`install-compilers.sh` 的 `install_zig`。
- 库固化见 [libcache zig-cache 册](../libcache/zig-cache.md)。

## 文件

- 本体目录 `/opt/zig`,程序 `/opt/zig/zig`。
- `/usr/local/bin/zig` 软链指向该程序。
- `/opt/zig-0.15.2` 是 bof 组为 bof-launcher 安装的专用副本。上游锁定 0.15.2。系统 0.16 可能编不过该副本。它不属于本组。

## 配置

- `/etc/profile.d/zig.sh` 导出 `ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache`。这是登录 shell 的备份面。
- 包缓存固化五库:zlib、zstd、sqlite3、mbedtls、libxml2。zon hash 锁定在 `/opt/zig-prewarm/build.zig.zon`。
- `~/.cache/zig` 软链到 `/opt/zig-cache`。属 piopt 组,带默认 ACL,共享可写。
- 上述缓存归 libcache 组。机制见 [offline.md](../../offline.md) 与 [libcache zig-cache 册](../libcache/zig-cache.md)。
- 权限模型见 [offline.md](../../offline.md) 第 5 节。

## 离线行为

- 支持:关闭 eth0 后,`zig version` 可读出版本。记录见 [offline.md](../../offline.md) 验证节。
- 支持:断网编译写入 `/opt/zig-cache`。root 与 ubuntu 均可。
- 验证:关闭 eth0 后,`mkdir /tmp/zt && cd /tmp/zt && zig init && zig build` 退出码 0。
- 未验证:`zig fetch` 拉新包在断网时失败。zig 无快失败配置,不在五生态默认面。
- 固化五库的离线消费见 [libcache zig-cache 册](../libcache/zig-cache.md)。

## 限制

- `/etc/profile.d/zig.sh` 写在早退判据之后。zig 已装时,重跑本组不补写该文件。
- 配置写入放早退前的规则见 [golang 册](golang.md)。
- zig 发行包无国内镜像,直下,并且未做 minisig 验签。公钥说明见 [known-issues.md](../../known-issues.md)。
- 0.16 的 `zig fetch` 必须先 `zig init`。
- `git+` 过不了 ohmygh 代理,改用 tarball。
- 旧 tag 的 zon 字符串名会被拒绝。
- 这三条 `zig fetch` 行为的消费面在 [libcache zig-cache 册](../libcache/zig-cache.md)。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [golang 册](golang.md)
- [libcache zig-cache 册](../libcache/zig-cache.md)

## rctl 收录行

- rctl: zig kind=compiler path=/opt/zig note=zig 工具链本体

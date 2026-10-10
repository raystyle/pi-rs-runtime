# Zig 编译器

> Zig 工具链(C 交叉编译器;cargo-zigbuild 的 apple-darwin 链接桩) ｜ 状态:已装 ｜ 组:`install-compilers.sh zig` + `install-libcache.sh zig`(库固化册:[libcache/zig](../libcache/zig.md))

- **版本钉**:`ZIG_VERSION=0.16.0`(scripts/lib/common.sh,env 可覆盖);幂等判据 `zig version` 匹配 `^0.16.0` 即跳过;tarball 无校验和、未验签(留痕 [known-issues](../../known-issues.md))
- **来源与安装**:[ziglang.org/download](https://ziglang.org/download/) 直下(国内无镜像):`zig-<x86_64|aarch64>-linux-0.16.0.tar.xz`(dpkg 架构 amd64/arm64 映射,其余 exit 1)→ `tar --strip-components=1` 解进 /opt/zig;安装面 `install-compilers.sh` 的 `install_zig`
- **落点**:`/opt/zig`(本体 `/opt/zig/zig`);`/usr/local/bin/zig` 软链。另有 `/opt/zig-0.15.2`:bof 组为 bof-launcher 装的专用副本(上游钉 0.15.2,系统 0.16 可能编不过),不属本组
- **配置与缓存**:`/etc/profile.d/zig.sh` 导出 `ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache`(登录 shell 备份面);包缓存固化(zlib/zstd/sqlite3/mbedtls/libxml2 五库,zon hash 钉 `/opt/zig-prewarm/build.zig.zon`)、`~/.cache/zig → /opt/zig-cache` 默认位软链与 piopt 组+默认 ACL 共享写,均归 libcache 组——机制见 [offline.md](../../offline.md) 与 [libcache zig 册](../libcache/zig.md),权限裁定 [ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md)
- **离线行为**:✅ 断网 `zig version`(断网冒烟覆盖编译器版本面,当轮 78/0 全绿;[offline.md](../../offline.md) 验证节);✅ 断网编译写 /opt/zig-cache,root/ubuntu 双视角实证([ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md),纯离线轮)。验证:`ip link set eth0 down` 后 `mkdir /tmp/zt && cd /tmp/zt && zig init && zig build` 退 0。☐ [推断:] `zig fetch` 拉新包断网即败(zig 无快失败配置,不在五生态默认面);固化五库的离线消费见 [libcache zig 册](../libcache/zig.md)
- **坑与留痕**:`/etc/profile.d/zig.sh` 写在早退判据之后,zig 已装时重跑本组不补写(golang 组「配置写入放早退前」口径见 [golang 册](golang.md));zig 发行包无国内镜像直下且未做 minisig 验签,公钥留痕 [known-issues](../../known-issues.md);0.16 的 `zig fetch` 行为坑(须先 `zig init`、git+ 过不了 ohmygh 代理改 tarball、旧 tag zon 字符串名被拒)归 [libcache zig 册](../libcache/zig.md)

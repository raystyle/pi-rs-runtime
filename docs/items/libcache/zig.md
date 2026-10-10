# Zig 库缓存(allyourcodebase 五库 /opt/zig-cache)

> 交叉编译常用 C 库五件 zig fetch 固化进 /opt/zig-cache,离线 zig build 按 hash 直取 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh zig`(前置 `install-compilers.sh zig`,0.16.0)

- **版本钉**:五库均钉主干 heads 的构建日快照 tarball(`archive/refs/heads/{master,main}.tar.gz`);zon hash 以镜像内 zig 0.16 现场算为准,`zig fetch --save` 把依赖名与 hash 写进 `/opt/zig-prewarm/build.zig.zon`;不钉 tag——zlib 旧 tag 的 zon 字符串名被 0.16 拒(实证);锁文件(zon hash)已入库 `scripts/lock/zig/build.zig.zon`,有锁走 `zig build --fetch` 按 zon 补缓存,再生跑 `scripts/sync-locks.sh`
- **来源与安装**:allyourcodebase 系 GitHub 仓 tarball 经 `GITHUB_MIRROR`(实证 ohmygh 代理不支持 git smart-http,`git+` 全失败,只有 tarball 能过代理);每库三次重试;脚本段 `scripts/install-libcache.sh install_zig`;zig 未装早退(先跑 compilers zig 组)

  | 库 | 仓 | 分支 |
  |---|---|---|
  | zlib | allyourcodebase/zlib | master |
  | zstd | allyourcodebase/zstd | master |
  | sqlite3 | allyourcodebase/sqlite3 | main |
  | mbedtls | allyourcodebase/mbedtls | main |
  | libxml2 | allyourcodebase/libxml2 | master |

- **落点**:`/opt/zig-cache`(`ZIG_GLOBAL_CACHE_DIR`,包在 `p/` 子目录);`/opt/zig-prewarm`(zig init 模板工程,build.zig.zon 存五库 hash)
- **配置与缓存**:`/etc/profile.d/zig.sh` export `ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache`(compilers zig 组写);非登录 shell(incus exec)读不到 env——`/root/.cache/zig` 与 `/home/ubuntu/.cache/zig` 软链到 /opt/zig-cache 兜底默认缓存位(clean-image.sh 对软链有守卫不删);zig 缓存要可写(z/ 编译产物),`shared_writable_cache /opt/zig-cache`:共同组 piopt(root+ubuntu)+ chgrp -R + g+rwX + 目录 setgid + 默认 ACL 压 umask,**不 1777**——任意用户可写就能换掉 root 下次构建要用的缓存;裁定与实证见 [ADR-0005](../../adr/ADR-0005-shared-writable-cache-piopt-acl.md)
- **离线行为**:✅ 断网编译 root/ubuntu 双视角实证(ADR-0005 终审;冒烟「缓存构建断网能编」覆盖,见 [offline.md](../../offline.md) §1)。验证:`ip link set eth0 down` 后 root 与 ubuntu 各 `zig build` 一个依赖五库的工程(hash 命中 /opt/zig-cache,不访问网络)
- **坑与留痕**:0.16 起 `zig fetch` 要求 cwd 是包(实证报 no build.zig)——先 `zig init` 出模板再 fetch;**缺一库即断**:任一库三次重试全败即 `return 1`(早期 fetch 全败被静默吞,固化出 4 KB 空壳;空目录守卫太弱——旧条目还在就会放行,grok G2);cargo-zigbuild 缓存同形共享([offline.md](../../offline.md) §1)

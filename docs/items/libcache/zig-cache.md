# Zig 库缓存:allyourcodebase 五库 /opt/zig-cache

> 交叉编译常用 C 库五件 zig fetch 固化进 /opt/zig-cache,离线 zig build 按 hash 直取 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh zig`(前置 `install-compilers.sh zig`,0.16.0)

## 版本

- 五库都锁定主干 heads 的构建日快照 tarball:`archive/refs/heads/{master,main}.tar.gz`。
- zon hash 以镜像内 zig 0.16 现场计算为准。
- `zig fetch --save` 把依赖名与 hash 写进 `/opt/zig-prewarm/build.zig.zon`。
- 不锁定 tag。
- zlib 旧 tag 的 zon 字符串名会被 0.16 拒绝。
- 锁文件(zon hash)已入库 `scripts/lock/zig/build.zig.zon`。
- 有锁时走 `zig build --fetch`,按 zon 补缓存。
- 再生执行 `scripts/sync-locks.sh`。

## 来源与安装

- 来源是 allyourcodebase 系 GitHub 仓的 tarball,经 `GITHUB_MIRROR`。
- ohmygh 代理不支持 git smart-http。
- `git+` URL 全部失败。
- 只有 tarball 能通过该代理。
- 每库重试三次。
- 脚本:`scripts/install-libcache.sh` 的 `install_zig`。
- zig 未安装时,本组直接返回。
- 需要先跑 compilers 的 zig 组。

| 库 | 仓 | 分支 |
|---|---|---|
| zlib | allyourcodebase/zlib | master |
| zstd | allyourcodebase/zstd | master |
| sqlite3 | allyourcodebase/sqlite3 | main |
| mbedtls | allyourcodebase/mbedtls | main |
| libxml2 | allyourcodebase/libxml2 | master |

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/zig-cache | `ZIG_GLOBAL_CACHE_DIR`;包在 `p/` 子目录 |
| /opt/zig-prewarm | `zig init` 模板工程;build.zig.zon 存五库 hash |

## 配置

- `/etc/profile.d/zig.sh` 导出 `ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache`。
- 该文件由 compilers 的 zig 组写入。
- 非登录 shell(`incus exec`)读不到这个环境变量。
- `/root/.cache/zig` 与 `/home/ubuntu/.cache/zig` 符号链接到 /opt/zig-cache。
- 这两条链接兜住默认缓存位置。
- clean-image.sh 对符号链接有守卫,不删除它们。
- zig 缓存要可写,因为编译会写 `z/`。
- `shared_writable_cache /opt/zig-cache` 使用共同组 piopt(root 与 ubuntu)。
- 同一次调用还做 `chgrp -R`、`g+rwX`、目录 setgid,以及默认 ACL。
- 默认 ACL 压住 umask。
- 不使用 1777。
- 任意用户可写时,可以换掉 root 下次构建要用的缓存。
- 权限模型见 [offline.md](../../offline.md) 第 5 节。

## 离线行为

- 支持:root 与 ubuntu 都可以断网编译。
- 冒烟项「缓存构建断网能编」覆盖该行为。
- 见 [offline.md](../../offline.md) 第 1 节。
- 验证:关闭 eth0 后,root 与 ubuntu 各对一个依赖五库的工程执行 `zig build`。
- hash 命中 /opt/zig-cache 时,不访问网络。

## 限制

- 从 0.16 起,`zig fetch` 要求当前目录是一个包。
- 不是包时,报 no build.zig。
- 因此先 `zig init` 生成模板,再 fetch。
- 缺一库即停止:任一库三次重试都失败时,`return 1`。
- 五库顶层 zon 的 hash 只锁到库本体。
- 各库自己的 build.zig.zon 还声明上游源 URL。
- zlib 的上游是 github tarball。
- sqlite 的上游是 sqlite.org。
- libxml2 的上游是 gnome.org。
- zstd 与 mbedtls 的上游是 `git+https`。
- 这一层不在顶层 zon 锁里。
- 发布镜像 5e947cfcd98e 的 /opt/zig-cache 缺少这一层。
- 缺少时,断网 `zig build` 报 NameServerFailure。
- 有网时,在 /opt/zig-prewarm 执行一次 `zig build --fetch`,递归补齐全局缓存。
- 补齐之后,断网 `zig build` 的退出码是 0。
- gnome.org 与 sqlite.org 不是 GitHub,不走 `GITHUB_MIRROR`。
- 构建机需要能直连这两个站点。
- cargo-zigbuild 的缓存以同一形态共享,见 [offline.md](../../offline.md) 第 1 节。

## 参见

- [offline.md](../../offline.md)
- [zig 编译器册](../compilers/zig.md)

## rctl 收录行

- rctl: zig-cache kind=cache path=/opt/zig-cache note=五库固化缓存
- rctl: zig-prewarm kind=cache path=/opt/zig-prewarm note=五库预热工程(zon 锁)

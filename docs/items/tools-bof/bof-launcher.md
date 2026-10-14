# bof-launcher

> Zig 写的 BOF 加载器,Linux 下脱离 C2 直跑 BOF ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- `GIT_PIN[The-Z-Labs/bof-launcher]` = c9b600a93c72503900c1fc3792eda5aa5602f922。
- `clone_pin` 在 HEAD 等于锁定提交时跳过;解析日 2026-10-10;仓库锁定 zig 0.15.2;系统 zig 0.16 可能编译失败;因此使用专用副本 `/opt/zig-0.15.2`。
- 该副本从 ziglang.org 直接下载,没有验签。见 [known-issues.md](../../known-issues.md)。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 bof 组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_bof`;源码克隆到 `/opt/payload-ref/loaders/inproc/bof-launcher` 构建出二进制;构建树随 clean-image 清(2026-10-14 瘦身批),`/usr/local/bin/bof-launcher` 常驻。
- 构建命令是 `/opt/zig-0.15.2/zig build -Doptimize=ReleaseSafe`。
- 上游是库,提供 C API 与 Zig API,不是 CLI;可以运行的 BOF 执行器是示例二进制 `bof_lin_<arch>`;`install -m755` 把它装成 `/usr/local/bin/bof-launcher`;幂等判据是 `have bof-launcher`。已安装则整段跳过;zig 副本的判据是 `-x /opt/zig-0.15.2/zig`。

| 架构 | 示例二进制 |
| --- | --- |
| amd64 | bof_lin_x64 |
| arm64 | bof_lin_aarch64 |

## 文件

- 入口是 `/usr/local/bin/bof-launcher`。
- 源码与构建树构建期在 `/opt/payload-ref/loaders/inproc/bof-launcher`,成品镜像不随(瘦身批 2026-10-14)。
- 该目录属于 inproc 轴;zig 0.15.2 的专用副本在 `/opt/zig-0.15.2`;构建产物在源码树的 `zig-out/bin/`,随 inproc 轴一起归档。

## 配置

- 无运行期配置。

## 离线行为

- 支持确认源码在位。见 [offline.md](../../offline.md);未验证:加载本地 `.o` 并执行。脚本给出的命令是 `bof-launcher run bof.o`;该动作不依赖网络,尚未单独断网测量。
- 关闭 eth0 后,`ls /opt/payload-ref/loaders/inproc/bof-launcher/zig-out/bin` 退 0。

## 限制

- 上游是库,不是 CLI;装进 PATH 的是示例执行器 `bof_lin_<arch>`;zig 版本错配是构建失败的主要原因;专用副本与系统 zig 并存,互不影响;构建失败只 echo,不阻塞本组;BOF 运行还有 mingw 与 wine 这条路径。见 [wine.md](wine.md)。

## 参见

- [bof.md](bof.md)
- [wine.md](wine.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: zig-0.15.2 kind=cache path=/opt/zig-0.15.2 note=bof-launcher 专用 zig 版本副本(versioned-copy)

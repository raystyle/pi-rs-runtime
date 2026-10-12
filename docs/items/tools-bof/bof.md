# BOF 工具链:bof 组册

> Beacon Object File 工具链。mingw 交叉编译与脱离 C2 的加载器已装,源码是参考克隆 ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- mingw-w64 与 wine 随 noble 源冻结,即软件源锁定。见 [known-issues.md](../../known-issues.md)。
- 克隆仓由 pins.sh 的 `GIT_PIN` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- 解析日 2026-10-10。
- coffee-ldr 用 cargo nightly,`CRATE_PIN[coffee-ldr]` = 0.2.2。见 [coffee-ldr.md](coffee-ldr.md)。
- `BOF-CATALOG.md` 取 main 的 raw 文件,没有锁定提交。
- pins.sh 没有收录 `BOF-CATALOG.md` 的锁定项。
- GitHub 来源统一经 `GITHUB_MIRROR`。规定见 [params.md](../../params.md)。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_bof`。
- 进程内执行的加载器归档在 `payload-ref/loaders/inproc`。
- 后渗透内容归档在 `tradecraft-ref/bof`。内容是 BOF 源码集与目录。
- 这两处按工件角色分目录。
- 逐件版本、来源与路径在文末成员清单。已有专册的件,链接在表内。

## 文件

- `inproc` 是 `/opt/payload-ref/loaders/inproc`。
- COFFLoader 与 bof-launcher 的源码在该目录内原地构建。
- `bofref` 是 `/opt/tradecraft-ref/bof`。
- 这里放 atomic-bofs、TrustedSec 两套源码,以及目录文件。
- 克隆的幂等判据是 `-d <目录>/.git`。
- COFFLoader 的判据是存在 `COFFLoader64.exe`。
- 该文件不在时,`rm -rf` 后重新克隆并重新编译。
- `BOF-CATALOG.md` 每次重跑都重新下载。
- 这次下载失败不影响工具链。
- 脚本给出的用法是 `x86_64-w64-mingw32-gcc -c bof.c -o bof.o`。
- 然后执行 `coffee run bof.o`,或 `bof-launcher run bof.o`。
- Windows 侧执行 `wine64 COFFLoader64.exe <bof.o>`。

## 配置

- coffee-ldr 构建期导出 `RUSTUP_HOME=/opt/rustup`。
- 同时导出 `CARGO_HOME=/opt/cargo`。
- 这是借用 rust 组的共享目录。
- 无运行期配置写入。

## 离线行为

- 支持确认参考库在位。见 [offline.md](../../offline.md)。
- 未验证:mingw 交叉编译,以及 wine 或加载器跑本地 BOF。这些动作不依赖网络,尚未单独断网测量。
- 关闭 eth0 后,`ls /opt/tradecraft-ref/bof /opt/payload-ref/loaders/inproc` 退 0。

## 限制

- COFFLoader 的 standalone 依赖 Windows 类型 `BOOL` 与 `InternalFunctions`。
- Linux 上直接编译通不过。上游也不支持这条路径。
- Windows 版用交叉编译,在 wine 下使用。
- Linux 上直接跑 BOF 用 coffee 或 bof-launcher。
- atomic-bofs 是 rasta-mouse 的 COFF 独立运行 harness,带打包参数。
- TrustedSec 两套现役 BOF 源码仍在发布构建。
- atomic-bofs 的示例集替代不了这两套。
- wine64 包没有 PATH 命令的问题见 [wine.md](wine.md)。
- coffee-ldr 的 nightly 构建失败见 [coffee-ldr.md](coffee-ldr.md)。

## 参见

- [wine.md](wine.md)
- [coffee-ldr.md](coffee-ldr.md)
- [bof-launcher.md](bof-launcher.md)
- [entropia.md](entropia.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [params.md](../../params.md)

## 成员清单

@@BOF_TABLE@@

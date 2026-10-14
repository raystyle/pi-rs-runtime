# BOF 工具链:bof 组册

> Beacon Object File 工具链。mingw 交叉编译与脱离 C2 的加载器已装;参考源码树按 2026-10-14 瘦身批 不烤镜像 ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- mingw-w64 与 wine 随 noble 源冻结,即软件源锁定。见 [known-issues.md](../../known-issues.md)。
- 克隆仓由 pins.sh 的 `GIT_PIN` 锁定提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;解析日 2026-10-10。
- coffee-ldr 用 cargo nightly,`CRATE_PIN[coffee-ldr]` = 0.2.2。见 [coffee-ldr.md](coffee-ldr.md)。
- `BOF-CATALOG.md` 取 main 的 raw 文件,没有锁定提交;pins.sh 没有收录 `BOF-CATALOG.md` 的锁定项。
- GitHub 来源统一经 `GITHUB_MIRROR`。规定见 [params.md](../../params.md)。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_bof`;进程内执行的加载器归档在 `payload-ref/loaders/inproc`;后渗透内容归档在 `tradecraft-ref/bof`。内容是 BOF 源码集与目录;这两处按工件角色分目录;逐件版本、来源与路径在文末成员清单。已有专册的件,链接在表内。

## 文件

- bof-launcher 构建树在 `/opt/payload-ref/loaders/inproc`(构建完由 clean-image 清,二进制落 `/usr/local/bin/bof-launcher`);COFFLoader/atomic-bofs/TrustedSec BOF 源码集按 2026-10-14 瘦身批 不烤镜像(显式克隆可复得);用法是 `x86_64-w64-mingw32-gcc -c bof.c -o bof.o`;然后执行 `coffee run bof.o`,或 `bof-launcher run bof.o`(Windows 侧 COFFLoader 路径已随参考树移出)。

## 配置

- coffee-ldr 构建期导出 `RUSTUP_HOME=/opt/rustup`;同时导出 `CARGO_HOME=/opt/cargo`;这是借用 rust 组的共享目录;无运行期配置写入。

## 离线行为

- 支持确认参考库在位。见 [offline.md](../../offline.md)。
- 未验证:mingw 交叉编译,以及 wine 或加载器跑本地 BOF。这些动作不依赖网络,尚未单独断网测量。
- 关闭 eth0 后,`ls /opt/tradecraft-ref/bof /opt/payload-ref/loaders/inproc` 退 0。

## 限制

- Linux 上直接跑 BOF 用 coffee 或 bof-launcher;mingw 交叉编出的 Windows PE 用 wine 跑;wine64 包没有 PATH 命令的问题见 [wine.md](wine.md)。COFFLoader/atomic-bofs/TrustedSec 参考面已随瘦身批移出(后续走 MCP 数据服务)。
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

| 件 | 版本 | 来源 | 路径 |
|---|---|---|---|
| mingw-w64 | noble 随源 | Ubuntu noble 源(tuna) | /usr/bin/x86_64-w64-mingw32-gcc(交叉编译器) |
| wine | noble 随源( 9.0) | 见 [wine.md](wine.md) | /usr/bin/wine + /usr/local/bin/wine64 |
| COFFLoader | GIT_PIN 锁定 sha | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader) | /opt/payload-ref/loaders/inproc/COFFLoader(`make bof` 交叉编出 COFFLoader64.exe) |(参考面不烤镜像,显式克隆可复得)
| atomic-bofs | GIT_PIN 锁定 sha | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) | /opt/tradecraft-ref/bof/atomic-bofs |(参考面不烤镜像,显式克隆可复得)
| CS-Situational-Awareness-BOF | GIT_PIN 锁定 sha | [trustedsec/CS-Situational-Awareness-BOF](https://github.com/trustedsec/CS-Situational-Awareness-BOF) | /opt/tradecraft-ref/bof/CS-Situational-Awareness-BOF |
| CS-Remote-OPs-BOF | GIT_PIN 锁定 sha | [trustedsec/CS-Remote-OPs-BOF](https://github.com/trustedsec/CS-Remote-OPs-BOF) | /opt/tradecraft-ref/bof/CS-Remote-OPs-BOF |
| coffee-ldr | cargo nightly + CRATE_PIN 0.2.2 | 见 [coffee-ldr.md](coffee-ldr.md) | 未装上(构建失败留档) |
| bof-launcher | GIT_PIN 锁定 sha | 见 [bof-launcher.md](bof-launcher.md) | /usr/local/bin/bof-launcher + 源码 inproc 轴 |
| entropia(entc) | GIT_PIN 锁定 sha(v0.1-experimental) | 见 [entropia.md](entropia.md) | /usr/local/bin/entc + 源码 /opt/entropia(高级语言道,2026-10-11 加) |
| BOF-CATALOG.md | main raw(未锁定) | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) | /opt/tradecraft-ref/bof/BOF-CATALOG.md |

# BOF 工具链:bof 组册

> Beacon Object File 工具链:mingw 交叉编译 + 脱离 C2 的运行加载器 + BOF 源码与目录参考 ｜ 状态:已装(工具链)+ 参考克隆(源码) ｜ 组:`install-tools.sh bof`

- **版本**:mingw-w64 / wine noble 源冻结即锁定(软件源锁定, [known-issues](../../known-issues.md));克隆仓全部 pins.sh `GIT_PIN` 锁定 sha(clone_pin,幂等:HEAD==锁定的提交即跳过;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;coffee-ldr 走 cargo nightly 锁定 `CRATE_PIN[coffee-ldr]`=0.2.2(见 [coffee-ldr.md](coffee-ldr.md));BOF-CATALOG.md 取 main raw 未锁定(pins.sh 未收锁定项);GitHub 系统一经 GITHUB_MIRROR(规定见 [params.md](../../params.md))
- **来源与安装**:`scripts/install-tools.sh install_bof` 段。机制分工:进程内执行基底(loader)归档 `payload-ref/loaders/inproc`,后渗透内容(BOF 源码集与目录)归档 `tradecraft-ref/bof` 工件角色轴, 规定。成员表(有专册的链专册):

| 件 | 版本 | 来源 | 路径 |
|---|---|---|---|
| mingw-w64 | noble 随源 | Ubuntu noble 源(tuna) | /usr/bin/x86_64-w64-mingw32-gcc(交叉编译器) |
| wine | noble 随源( 9.0) | 见 [wine.md](wine.md) | /usr/bin/wine + /usr/local/bin/wine64 |
| COFFLoader | GIT_PIN 锁定 sha | [trustedsec/COFFLoader](https://github.com/trustedsec/COFFLoader) | /opt/payload-ref/loaders/inproc/COFFLoader(`make bof` 交叉编出 COFFLoader64.exe) |
| atomic-bofs | GIT_PIN 锁定 sha | [rasta-mouse/atomic-bofs](https://github.com/rasta-mouse/atomic-bofs) | /opt/tradecraft-ref/bof/atomic-bofs |
| CS-Situational-Awareness-BOF | GIT_PIN 锁定 sha | [trustedsec/CS-Situational-Awareness-BOF](https://github.com/trustedsec/CS-Situational-Awareness-BOF) | /opt/tradecraft-ref/bof/CS-Situational-Awareness-BOF |
| CS-Remote-OPs-BOF | GIT_PIN 锁定 sha | [trustedsec/CS-Remote-OPs-BOF](https://github.com/trustedsec/CS-Remote-OPs-BOF) | /opt/tradecraft-ref/bof/CS-Remote-OPs-BOF |
| coffee-ldr | cargo nightly + CRATE_PIN 0.2.2 | 见 [coffee-ldr.md](coffee-ldr.md) | 未装上(构建失败留档) |
| bof-launcher | GIT_PIN 锁定 sha | 见 [bof-launcher.md](bof-launcher.md) | /usr/local/bin/bof-launcher + 源码 inproc 轴 |
| entropia(entc) | GIT_PIN 锁定 sha(v0.1-experimental) | 见 [entropia.md](entropia.md) | /usr/local/bin/entc + 源码 /opt/entropia(高级语言道,2026-10-11 加) |
| BOF-CATALOG.md | main raw(未锁定) | [chryzsh/awesome-bof](https://github.com/chryzsh/awesome-bof) | /opt/tradecraft-ref/bof/BOF-CATALOG.md |

- **文件**(批量机制):`inproc=/opt/payload-ref/loaders/inproc`(COFFLoader、bof-launcher 源码原地构建),`bofref=/opt/tradecraft-ref/bof`(atomic-bofs、TrustedSec 两套、目录);克隆幂等判据 `-d <目录>/.git`,COFFLoader 判据 `-f COFFLoader64.exe`(不在则 rm -rf 重克隆重编),BOF-CATALOG.md 每次重跑重下(失败不影响工具链)。用法(脚本出口文案):`x86_64-w64-mingw32-gcc -c bof.c -o bof.o` 后 `coffee run bof.o` / `bof-launcher run bof.o`,Windows 侧 `wine64 COFFLoader64.exe <bof.o>`
- **配置与缓存**:coffee-ldr 构建期 export `RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo`(借 rust 组共享面);无运行期配置写入
- **离线行为**:过, 参考库在位属断网冒烟「参考库在位」覆盖(78/0,见 [offline.md](../../offline.md) §验证);未验 [推断:] mingw 交叉编译与 wine/loader 跑本地 BOF 均不依赖网络,未单独断网。验证:`ip link set eth0 down` 后 `ls /opt/tradecraft-ref/bof /opt/payload-ref/loaders/inproc` 退 0
- **限制**:COFFLoader 的 standalone 依赖 Windows 类型(BOOL/InternalFunctions),Linux 直编过不了上游也没支持,交叉编 Windows 版(wine 下用),Linux 直跑 BOF 用 coffee / bof-launcher(脚本注释规定);atomic-bofs 是 rasta-mouse 的 COFF 独立运行 harness(带打包参数);TrustedSec 现役 BOF 源码两套 2026-09 仍在出构建,atomic-bofs 示例集替代不了(脚本注释);wine64 包无 PATH 命令问题见 [wine.md](wine.md);coffee-ldr nightly 失败留档见 [coffee-ldr.md](coffee-ldr.md)

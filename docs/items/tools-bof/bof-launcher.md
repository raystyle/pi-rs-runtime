# bof-launcher

> Zig 写的 BOF 加载器,Linux 下脱离 C2 直跑 BOF ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

- **版本**:源码 pins.sh 锁定版本(`GIT_PIN[The-Z-Labs/bof-launcher]`=c9b600a93c72503900c1fc3792eda5aa5602f922,clone_pin 幂等:HEAD==锁定的提交即跳过;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;仓库锁定 zig 0.15.2,系统 zig 0.16 可能编不过,故用专用副本 `/opt/zig-0.15.2`(ziglang.org 直下无验签, [known-issues](../../known-issues.md))
- **来源与安装**:`scripts/install-tools.sh install_bof` 段:克隆源码到 `/opt/payload-ref/loaders/inproc/bof-launcher`(未装时 rm -rf 重克隆)到 `/opt/zig-0.15.2/zig build -Doptimize=ReleaseSafe` 到 上游是库(C/Zig API)不是 CLI,可跑的 BOF 执行器是示例二进制 `bof_lin_<arch>`(amd64到bof_lin_x64,arm64到bof_lin_aarch64),`install -m755` 装为 `/usr/local/bin/bof-launcher`;幂等判据 `have bof-launcher`(已装整段跳过),zig 副本判据 `-x /opt/zig-0.15.2/zig`
- **文件**:`/usr/local/bin/bof-launcher`;源码与构建树 `/opt/payload-ref/loaders/inproc/bof-launcher`( inproc 轴);zig 0.15.2 专用副本 `/opt/zig-0.15.2`
- **配置与缓存**:构建产物在源码树 `zig-out/bin/`(随 inproc 轴归档);无运行期配置
- **离线行为**:过, 源码在位属断网冒烟「参考库在位」覆盖(78/0,见 [offline.md](../../offline.md) §验证);未验 [推断:] 加载本地 .o 执行(`bof-launcher run bof.o`,脚本出口文案)不依赖网络,断网未做。验证:`ip link set eth0 down` 后 `ls /opt/payload-ref/loaders/inproc/bof-launcher/zig-out/bin` 退 0
## rctl 面,机器行:catalog 投影声明,audit 豁免依据

- rctl: zig-0.15.2 kind=cache path=/opt/zig-0.15.2 note=bof-launcher 专用 zig 版本副本(versioned-copy)

- **限制**:上游是库不是 CLI,装的是示例执行器 `bof_lin_<arch>`( [diary 2026-10-09](../../diary/2026-10-09-review-rounds.md));zig 版本错配是构建失败主因,专用副本与系统 zig 并存互不影响;构建失败只 echo 不阻塞(BOF 运行还有 mingw/wine 路径)

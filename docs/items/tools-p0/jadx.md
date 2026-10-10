# jadx

> Java/Android 反编译(DEX/APK → Java) ｜ 状态:已装 ｜ 组:`install-tools.sh p0`

- **版本钉**:`JADX_VERSION=1.5.3`(脚本默认,env 可覆盖);GitHub release 钉版直下,无校验和
- **来源与安装**:[skylot/jadx](https://github.com/skylot/jadx) releases → `jadx-1.5.3.zip` 经 GITHUB_MIRROR 直下解到 `/opt/jadx`;幂等判据 `have jadx`
- **落点**:`/opt/jadx`(zip 根布局是 `bin/jadx` + `lib/`,没有版本目录,脚本留痕);入口 `/usr/local/bin/jadx` 软链 → `/opt/jadx/bin/jadx`(同 zip 的 `bin/jadx-gui` 未链出)
- **配置与缓存**:无(脚本不写配置;`java` 依赖由 `install-runtimes.sh sdkman` 组提供,`/usr/local/bin/java` 链 sdkman current 的 temurin)
- **离线行为**:☐ [推断:CLI 与 lib 全本地,反编译不触网];逐件断网冒烟未单列登记。验证:`ip link set eth0 down` 后 `jadx --version` 退 0
- **坑与留痕**:无

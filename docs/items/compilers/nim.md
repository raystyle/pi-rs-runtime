# Nim 编译器

> OffensiveNim 等 maldev 模板的编译器(choosenim 官方安装器) ｜ 状态:已装 ｜ 组:`install-compilers.sh nim`

- **版本钉**:pins.sh 钉版(标量 `NIM_VERSION`=v2.2.12,choosenim 按钉装工具链;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;2.2.12 经 2026-10-09 构建轮容器实证(留痕 [diary](../../diary/2026-10-09-review-rounds.md));choosenim 本体 init.sh 直下未钉(pins.sh 未收钉位,空钉回退 stable 频道)
- **来源与安装**:[nim-lang.org](https://nim-lang.org) 的 [choosenim](https://github.com/nim-lang/choosenim):`curl -fsSL https://nim-lang.org/choosenim/init.sh | sh -s -- -y`,`CHOOSENIM_DIR=/opt/nim`;noble apt 的 nim 停 1.6.x 过旧不取;安装面 `install-compilers.sh` 的 `install_nim`
- **落点**:`/opt/nim`(choosenim 根:`bin/choosenim`、`toolchains/nim-<版本>/`);最新工具链(`sort -V` 取尾)的 `bin/*` 整批软链进 `/usr/local/bin`(nim、nimble 等;nim 经 /proc/self/exe 定位 stdlib,软链安全);choosenim 本体不链出,靠 profile.d 的 PATH 可见
- **配置与缓存**:`/etc/profile.d/nim.sh` 把 `/opt/nim/bin` 追加进 PATH(登录 shell 面);无 per-user 配置、无库缓存(libcache 八生态无 nim)
- **离线行为**:✅ 断网 `nim --version`(断网冒烟覆盖编译器版本面,当轮 78/0 全绿;[offline.md](../../offline.md) 验证节)。☐ [推断:] 本体编译纯本地无网络依赖,断网可编——验证:`ip link set eth0 down` 后 `echo 'echo "hi"' > /tmp/h.nim && nim c -r /tmp/h.nim` 退 0;☐ [推断:] `nimble` 拉新包断网即败(无固化缓存,nim 不在五生态快失败默认面)
- **坑与留痕**:整组装在 `! have nim` 守卫内且组尾 `true` 兜底:choosenim 失败(nim-lang.org 直连抖动)只 echo「下轮补」不阻塞流水线;已装后重跑本组不补写 profile.d/nim.sh、不补链(golang 组「配置写入放早退前」口径见 [golang 册](golang.md));非登录 shell(incus exec)读不到 /opt/nim/bin——choosenim 不可用,nim 本体经 /usr/local/bin 链出不受影响([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md) 非登录机制)

# wine(PE 验证路径)

> 在 Linux 下跑交叉编译出的 Windows PE(如 COFFLoader64.exe)的兼容层 ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

- **版本钉**:noble 随源(实证 wine 9.0,留痕 [diary 2026-10-09](../../diary/2026-10-09-review-rounds.md)),`apt-get install -y --no-install-recommends mingw-w64 wine64 wine`
- **来源与安装**:Ubuntu noble 源(tuna,[params.md](../../params.md) 口径),`scripts/install-tools.sh install_bof` 段;只 64 位不开 i386——wine 依赖 `wine64|wine32`,wine64 已满足故不拉 wine32
- **落点**:`/usr/bin/wine`(wine 包);`/usr/local/bin/wine64` 兜底软链 → `$(command -v wine)`(脚本 `have wine64 || { have wine && ln -sf … }`,幂等判据 `have wine64`);wine loader 本体在 `/usr/lib/wine/`
- **配置与缓存**:脚本不写配置;首跑 PE 时就地建 `~/.wine` prefix ☐ [推断:]
- **离线行为**:☐ [推断:] wine 跑原生 Windows PE 是纯本地动作不依赖网络(未单独断网实证);.NET PE 缺 mono 时会触发组件下载,属在线动作。验证:`ip link set eth0 down` 后 `wine64 --version` 退 0
- **坑与留痕**:noble 的 wine64 包不带 PATH 命令(实证 `dpkg -L` 无 `bin/`),`/usr/bin/wine` 在 wine 包里——只装 wine64 会出现「包装了却没有命令」;wine64 命令名由 wine 包链出,脚本再兜底软链 `/usr/local/bin/wine64`(实证留痕 [diary 2026-10-09](../../diary/2026-10-09-review-rounds.md));安装期 `wine64 --version` 不过只告警不阻塞(PE 验证路径缺,下轮补)

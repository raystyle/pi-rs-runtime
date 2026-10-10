# clean-chrome

> 定制 Chromium(云安全场景:`--auto-allow-devtools-connections`、`--remote-debugging-address`、bad-flags 黄条已剔除)｜ 状态:已装 ｜ 组:`install-tools.sh chrome`

- **版本钉**:pins.sh 标量 `CHROME_VERSION`(当前 155.0.8059.39,跟云端 latest 指针)+ `CHROME_SHA256` 锚;升级跑 `scripts/resolve-pins.sh`(解析器二段:先 latest 指针再边车 sha)
- **来源与安装**:云端安装道 `chrome.ohmygh.com/<版本>/chromium-<版本>-x86_64-unknown-linux-gnu.zip` + 同名 `.sha256` 边车(无 manifest;**非 GitHub 系,不走 GITHUB_MIRROR**);下载 → sha256 校验(不符即 return 1)→ 解到 `/opt/clean-chrome/<ver>` 并摊平顶层目录 → `.version` 标记幂等 → `/opt/clean-chrome/CURRENT` 写当前版(云端道 manifest 的最小复刻)
- **落点**:`/usr/local/bin/clean-chrome`(wrapper,恒 `--no-sandbox`,容器内核限制),`chrome`/`chromium` 同链;真身 `/opt/clean-chrome/<ver>/chrome`
- **配置与缓存**:无;运行期依赖(X 库/NSS/字体)由组内 apt 批兜底
- **离线行为**:✅ 断网可起(本地二进制,无更新检查);验证:断网后 `clean-chrome --version` 与 root/ubuntu 双视角 CDP 冒烟(vnc-screen.sh chrome)
- **坑与留痕**:本件跨机派单 prt-01 裁剪而来——browse CLI 因仓不可达(v0.34.0 资产 404,git 要凭证)暂缓(T1 挂起,总台裁定),「browse chrome install」语义由本组复刻;152-r5 与 155 的云上口径曾漂移,以 latest 指针实查为准(2026-10-10 实证 155 已上云);**实证坑**:clean-chrome 155 挂 `--remote-debugging-address` 就绑不了 CDP 端口(隔离变量实证;裸 `--remote-debugging-port` 默认绑回环,浏览面照走),Chrome 136+ 无独立 `--user-data-dir` 时 CDP 静默不开;对接见 [ADR-0007](../../adr/ADR-0007-clean-chrome-placement.md)、冒烟面 [tools-vnc/vnc.md](../tools-vnc/vnc.md)

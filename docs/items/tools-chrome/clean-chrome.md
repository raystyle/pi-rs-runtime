# clean-chrome

> 定制 Chromium,云安全场景参数面(auto-allow-devtools-connections,bad-flags 黄条已剔除) ｜ 状态:未装(组保留;显式执行 `install-tools.sh chrome` 可装) ｜ 组:`install-tools.sh chrome`

## 版本

- `CHROME_VERSION`(pins.sh 标量,当前 155.0.8059.39,跟踪云端 latest 指针)。
- `CHROME_SHA256` 锚定资产。
- 升级:运行 `scripts/resolve-pins.sh`;解析器先取 latest 指针,再取 sha256 边车。

## 来源与安装

- 云端安装道:`chrome.ohmygh.com/<版本>/chromium-<版本>-x86_64-unknown-linux-gnu.zip` 及同名 `.sha256` 边车;无 manifest。非 GitHub 系,不走 GITHUB_MIRROR。
- 步骤:
  1. 下载并按 sha256 校验;不符即返回 1。
  2. 解压到 `/opt/clean-chrome/<ver>`,摊平顶层目录。
  3. 写 `.version` 标记幂等。
  4. `/opt/clean-chrome/CURRENT` 指向当前版(云端道 manifest 的最小复刻)。

## 文件

| 路径 | 内容 |
| --- | --- |
| /usr/local/bin/clean-chrome | wrapper;恒带 `--no-sandbox`(容器内核限制) |
| chrome、chromium | 同链 |
| /opt/clean-chrome/<ver>/chrome | 被包装的程序 |

## 配置

- 无。运行期依赖(X 库、NSS、字体)由组内 apt 批兜底。

## 离线行为

- 支持:断网可起;本地二进制,无更新检查。
- 验证:断网后 `clean-chrome --version`;root 与 ubuntu 双视角 CDP 冒烟(vnc-screen.sh chrome)。

## 限制

- browse CLI 已合入(2026-10-14,独立 [browse](browse.md) 组在默认全量),自带 `browse chrome install` 托管面(同源 chrome.ohmygh.com,落 ~/.browse-rs);本组保持系统级单副本道,两组互不搬动,复用系统副本设 `BROWSE_CHROME=/opt/clean-chrome/CURRENT/chrome`。
- 152-r5 与 155 的云端版本记录曾漂移;以 latest 指针实查为准(2026-10-14 时 155.0.8059.39-gen8-r5 已上云,pins 已随)。
- clean-chrome 155 挂 `--remote-debugging-address` 时绑不了 CDP 端口(隔离变量);裸 `--remote-debugging-port` 默认绑回环,浏览面照走。
- Chrome 136+ 无独立 `--user-data-dir` 时 CDP 静默不开。

## 参见

- [browse.md](browse.md)
- [../tools-vnc/vnc.md](../tools-vnc/vnc.md)
- [docs/params.md](../../params.md)

## rctl 收录行

- rctl: clean-chrome kind=tool path=/usr/local/bin/clean-chrome note=定制 Chromium wrapper(恒 --no-sandbox;组保留不默认装)

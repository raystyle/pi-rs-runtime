# browse

> 浏览器 CLI:自研 Chromium 内核 + 油猴标准 userscript 运行时 + Rune 编排,daemon 保会话 ｜ 状态:已装 ｜ 组:`install-tools.sh browse`(默认全量)

## 版本

- pins.sh 标量 `BROWSE_VERSION`(当前 0.35.5)与 `BROWSE_SHA256`(Release 资产边车锚);升级跑 `scripts/resolve-pins.sh` 审 diff(解析器走 GitHub API latest + sha256 边车)。
- 引擎 clean-chrome 版本跟 `CHROME_VERSION` 锁(与 chrome 组共用标量);browse 自身有 `browse update` 自升道,本仓不消费(版本纪律走 pins)。

## 来源与安装

- 发行件:browse_rs GitHub Release `browse-v<版本>-x86_64-unknown-linux-gnu.tar.gz`(公开仓无凭证;README 记镜像 `browse.ohmygh.com/browse/…`,实测该镜像资产 404,以 GITHUB_MIRROR 前置 + GitHub 直连 + 宿主预推 `/root/<件名>` 三道)。
- 步骤:`install-tools.sh` 的 `install_browse`:sha256 校验 → 解 `/opt/browse/<ver>` → `.version` 幂等标记 → `/usr/local/bin/browse` 软链 → 引擎托管面 `BROWSE_CHROME_MIRROR=https://chrome.ohmygh.com browse chrome install <CHROME_VERSION>`(同版已在托管面即跳)。
- 运行期依赖:libnss3/libasound2t64 族 apt 批(组内自带)。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/browse/<ver>/browse | 被包装的程序(单二进制+双许可) |
| /usr/local/bin/browse | 入口软链 |
| ~/.browse-rs/chrome/<ver>/ | browse 托管面 clean-chrome(与 chrome 组 /opt/clean-chrome 互不搬动) |
| ~/.browse-rs/ | daemon 状态(会话/变量/活动标签/元素引用) |

## 配置

- 引擎发现序:显式 `BROWSE_CHROME` → 托管 pin → 祖先部署 → 系统常规路径;默认走托管 pin,复用 chrome 组系统副本设 `BROWSE_CHROME=/opt/clean-chrome/CURRENT/chrome`。
- 镜像可覆盖:`BROWSE_CHROME_MIRROR`(引擎下载)、`BROWSE_RELEASE_MIRROR`(自升道);attach-first:本机已有浏览器先附着,强制独立实例设 `BROWSE_NO_ATTACH=1`。
- 常用面:`browse up --headless` / `browse down`(daemon);`browse '<snippet>'` 单步方言;`browse --js`/`browse rune <file.rn> --vars k=v`(JS 与编排);`browse fetch <url> --markdown`;`browse cdp <Domain.method> --params`;`browse userscript install`;`browse --llms` 全量手册。

## 离线行为

- CLI 与引擎都是本地二进制,断网可起;页面加载与 chrome 托管面下载是运行期/构建期网络,不属于离线范围。
- 验证:断网 `browse --version`;headless 起 daemon + fetch 内网地址回环(2026-10-14 实测网关 /v1/models 过引擎取回)。

## 限制

- browse 托管面 clean-chrome 落各用户 `~/.browse-rs`(root 与 ubuntu 各一份,各约 900MB);要单副本复用 chrome 组道(见配置)。
- 引擎 spawn 恒 `--no-sandbox`(容器内核限制;browse 托管道自带)。
- 发行件三道里镜像道缺席(资产 404),弱网构建机走宿主预推。

## 参见

- [clean-chrome.md](clean-chrome.md)
- [../tools-vnc/vnc.md](../tools-vnc/vnc.md)
- [docs/params.md](../../params.md)

## rctl 收录行

- rctl: browse kind=tool path=/usr/local/bin/browse note=浏览器 CLI(Chromium 内核+userscript+Rune;daemon 保会话;引擎走 browse 托管面)

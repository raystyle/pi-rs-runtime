# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-10。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。治理合同见 [AGENTS.md](AGENTS.md),文档地图见 [docs/README.md](docs/README.md)。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活,断网冒烟为发布门禁),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库(ADR-0001)。

## 当前状态

- 线上镜像:**`0e22c3e18034`**(17.7 GB);历史发布链见 [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md) 尾部
- 镜像内唯一副本 scripts 在 /root/scripts;复跑/发布命令见 AGENTS.md Commands
- grok 钉版批终审(报告 /tmp/grok-pin-review.md + /tmp/grok-pin-final.md;首轮不放行 F3/G5):F1 clone_pin 重写(缺钉 return 1;原地仓 set-url+fetch+checkout --force,fetch 成功前不删树,宿主三案例实证);F2 缺钉漂 HEAD 收口(:-HEAD→:?);F3 git_latest_tag 管道重写(ref 级过滤带 $ 锚,预发布进不来;NU_VERSION=0.116.1);G1 gopls sed 删行;G2 依赖钉先裸赋值再引用,wrapper 只在 import 实证后写;G3 空钉正则 ^[A-Z0-9_]+;G4 nuget 稳定版过滤(全预发布包回退末位),dotnet 锁 csproj 经 sync-locks.sh 再生;G5 golang 早退判据已在此前批次修。二轮必修 F4:go 回退跨主版本写钉(amass/v4→v5.1.1 等四枚),改主版本过滤+gost 特例 HEAD 伪版本,重解析钉值正确且四件按钉编译实证过;G6 clone_pin 子模块成功标记。
- VNC 桌面批(2026-10-10,用户批 grok 配方):install-tools.sh 新 vnc 组(xfce4+tigervnc 三件+noVNC+websockify+fonts-noto-cjk+轻量面 xvfb/x11vnc 烘焙);vnc-screen.sh 重写双形态(轻量 Xvfb :99+x11vnc 5900;桌面 TigerVNC :1+noVNC 127.0.0.1:6080),口令首启随机生成打印一次(不落库),websockify/VNC 都只绑回环(宿主 proxy 引 6080);实证坑:noble tigervnc 的 vncpasswd 在 tigervnc-tools、TigerVNC 读 ~/.vnc/passwd 而 x11vnc 读 passfile(两份都写)。实证:noVNC 页面 200、5901/6080 双回环、jwt-tool/linkfinder 修复件同批
- grok 钉版批评审(F 3/G 5,报告 /tmp/grok-pin-review.md,全吸收):F1 clone_pin 重写(缺钉 return 1、原地仓换钉 fetch 成功前不删树、宿主三案例实证);F2 缺钉漂 HEAD 收口(pwndbg/ghauri 的 :-HEAD 改 :?);F3 git_latest_tag 管道重写(完整 ref 上先过滤带 $ 锚,预发布进不来;gopls 前缀顺序同修);G2 jwt_tool/LinkFinder wrapper 只在依赖实证可 import 后写;G3 空钉统计正则 ^[A-Z0-9_]+;G4 nuget 先滤稳定版(全预发布包回退末位),dotnet 锁 csproj 经 sync-locks.sh 再生
- phase B 锁文件入库(2026-10-10):`scripts/lock/` 六生态(go.mod+go.sum / Cargo.toml+Cargo.lock 重建 / package-lock.json / 解析后 pom / 钉版 csproj / build.zig.zon),从线上镜像收割;install-libcache.sh 六组有锁走锁消费(go build 用 go.sum / cargo fetch --locked / npm ci / mvn 解析后 pom / dotnet restore 钉版 csproj / zig build --fetch),无锁走原解析路径并打印「未锁」;新 `scripts/sync-locks.sh`(容器内再生+校验拉回,端到端实测零漂移)。PROGRESS 待办 3 销账。同批:golang 早退判据补 dlv/gopls/golangci-lint 存在性(残留态实证补装过);rust 组 rustup-init 守卫加执行探针(shim 空转不再卡死)
- 钉版轮 grok 终审二三事(全部合上):F5 secgo 查钉键带 /... 与 pins.sh 模块键不齐(amass/gau 实证缺钉)——消费键剥 /... 且 GO_SPECS 键与消费键逐一对账(宿主 miss=0);G2 余量 krbrelayx/enum4linux-ng wrapper 同补 import 闸;G6 clone_pin 子模块标记绑钉 sha。**教训:验证 grep 模式「缺钉」没匹到助手实际文案「缺 go 钉」,run3 假绿——断言模式必须先对着真实输出校一遍**;镜像内 /root/scripts 副本滞后于仓库一个提交,下轮发布链刷新
- 钉版轮(2026-10-10,用户裁定「未钉?钉版本啊」):新 `scripts/lib/pins.sh`(266 钉:go 45/crate 12/pypi 49/gem 6/nuget 17/npm 28/psgallery 8/git 克隆 60 + 标量 13 + temurin 5)+ 生成器 `scripts/resolve-pins.sh`(并行化后全量 21.6s(原串行约 6 分钟,并发 16);升级=跑它+审 diff);消费助手进 common.sh(go_install_pin/cargo_install_pin/pypi_pin/clone_pin 幂等,缺钉即响不许漂回);四个安装脚本全部消费点改钉。解析器实证坑:goproxy.cn 冷门模块 404(回退仓 tag→HEAD sha)、npm scoped/下划线文件名、git tag v 系混排(nushell v0.96.0 压过 0.109.0 事故)、nuget flatcontainer 路径、temurin 间接展开要在 local 赋值之后分两行。例外软钉清单见 known-issues
- swarm 积压批(2026-10-10,四工位并行):bun bunfig 写入挪早退前+全 runtimes 组排查;zig/nim/golang 组配置写挪早退前(golang 顺带补 dlv 三件套缺链自愈);jwt_tool/LinkFinder 坐实活 bug(wrapper 走系统 python3 而依赖在 re-venv,linkfinder 必炸)已改 re-venv python+依赖钉版(实证 ratelimit/jsbeautifier 裸 import);resolve-pins.sh 并行化。rt-fix3 验证 rc=0,断网起 jwt-tool/linkfinder/trivy 过
- 治理面:AGENTS.md(五节合同)、docs/adr/(6 篇 accepted)、docs/items/(逐件一册,件级事实唯一真相)、docs/diary/(轮次留痕)
- 离线面三层完整:工具断网能跑(冒烟 78/0)+ 缓存构建断网能编(root/ubuntu 双视角)+ 拉新依赖亚秒快失败(五生态);机制与边界见 [docs/offline.md](docs/offline.md)
- 文档解耦轮(2026-10-10):件级事实唯一真相迁 docs/items/(71 册,逐件七节:版本钉/来源安装/落点/配置缓存/离线行为/坑);install-surfaces 瘦身成组卡(机制+链接),software-inventory 改计数对账面,known-issues 只留真限制(裁定移 ADR);新增 AGENTS.md 五节合同与 docs/adr 6 篇、docs/diary 3 篇,本文件瘦身为会话本位
- 镜像源与参数口径:[docs/params.md](docs/params.md);GITHUB_MIRROR 默认 `https://proxy.ohmygh.com/`

## 近三轮(细节在 diary)

- 2026-10-10 纯离线三轮 + 快失败默认化 + smali 批 → [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md)
- 2026-10-09 评审双批 + 归档三轴 + 全做批 → [docs/diary/2026-10-09-review-rounds.md](docs/diary/2026-10-09-review-rounds.md)
- 2026-10-08 基线构建 + fresh 验证 17 坑 → [docs/diary/2026-10-08-build-baseline.md](docs/diary/2026-10-08-build-baseline.md)

## 待办

1. ~~合入定制 Chrome~~(2026-10-10 跨机派单 prt-01 完成,裁定面有裁剪):browse CLI 暂缓(仓不可达,T1 挂起等凭证);clean-chrome 155.0.8059.39 经云端道(chrome.ohmygh.com 版本段路由+sha256 锚)进镜像,系统级单副本 /opt/clean-chrome(ADR-0007);vnc-screen.sh 增 chrome 冒烟面(CDP 9222,实证 root/ubuntu/断网三视角 `Chrome/155.0.8059.39`);实证坑:155 挂 --remote-debugging-address 就绑不了 CDP 口(摘除),Chrome 136+ 无 --user-data-dir 时 CDP 静默不开。
2. ~~脚本级疑点~~(2026-10-10 两批 swarm 全清):bun/zig/nim 早退后配置写入已挪前(golang 组 profile.d 同坑顺手修);jwt_tool/LinkFinder wrapper 实证活 bug(系统 python3 无依赖必炸)已改 re-venv python + 依赖钉版;golang 早退跳过补装残留已由早退判据补三件套存在性根治(删 dlv 残留态实证重跑补装过);rust 组 rustup-init 守卫加执行探针(shim 空转不再卡死)。
3. ~~库缓存层的 repo 侧钉版(phase B)~~(2026-10-10 完成):六生态锁文件入库 `scripts/lock/`(go.mod+go.sum、Cargo.toml+Cargo.lock(31 crate 清单重建 generate-lockfile 收割)、package-lock.json、resolve-ranges 写回后 pom.xml、dotnet-prewarm.csproj、build.zig.zon);install-libcache.sh 有锁消费锁(go build 用 go.sum / cargo fetch --locked / npm ci / mvn 直消费解析后 pom / dotnet restore / zig build --fetch),无锁或 LIBCACHE_RESOLVE=1 走构建日解析并打印「未锁」;新 `scripts/sync-locks.sh` 起临时容器从线上镜像解析态再生拉回(rt-locksync,用完自删);python/pwsh 无独立锁文件(pins.sh 钉直接依赖)不在同步面。容器实证(rt-lh):六组锁消费路径全过(go build 锁 19+19 模块、npm ci 255 包/161 落点、cargo fetch --locked、restore 9 段、zig 10 包)
4. 已知遗留(不阻塞,细节见 docs/known-issues.md):webcrack 传递依赖 isolated-vm 被拦;frida windows-x86 server 多数版本未发布;coffee-ldr nightly 编译失败(上游);trivy db 为构建日快照;nuclei headless 无 Chrome 不可用。

# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-10。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。治理合同见 [AGENTS.md](AGENTS.md),文档地图见 [docs/README.md](docs/README.md)。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活,断网冒烟为发布门禁),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库(ADR-0001)。

## 当前状态

- 线上镜像:**`31ccc42d8eaf`**(17.3 GB);历史发布链见 [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md) 尾部
- 镜像内唯一副本 scripts 在 /root/scripts;复跑/发布命令见 AGENTS.md Commands
- 钉版轮(2026-10-10,用户裁定「未钉?钉版本啊」):新 `scripts/lib/pins.sh`(258 钉:go 45/crate 11/pypi 44/gem 6/nuget 17/npm 28/psgallery 8/git 克隆 61 + 标量 13 + temurin 5)+ 生成器 `scripts/resolve-pins.sh`(全量重解析约 6 分钟;升级=跑它+审 diff);消费助手进 common.sh(go_install_pin/cargo_install_pin/pypi_pin/clone_pin 幂等,缺钉即响不许漂回);四个安装脚本全部消费点改钉。解析器实证坑:goproxy.cn 冷门模块 404(回退仓 tag→HEAD sha)、npm scoped/下划线文件名、git tag v 系混排(nushell v0.96.0 压过 0.109.0 事故)、nuget flatcontainer 路径、temurin 间接展开要在 local 赋值之后分两行。例外软钉清单见 known-issues
- 治理面:AGENTS.md(五节合同)、docs/adr/(6 篇 accepted)、docs/items/(逐件一册,件级事实唯一真相)、docs/diary/(轮次留痕)
- 离线面三层完整:工具断网能跑(冒烟 78/0)+ 缓存构建断网能编(root/ubuntu 双视角)+ 拉新依赖亚秒快失败(五生态);机制与边界见 [docs/offline.md](docs/offline.md)
- 文档解耦轮(2026-10-10):件级事实唯一真相迁 docs/items/(71 册,逐件七节:版本钉/来源安装/落点/配置缓存/离线行为/坑);install-surfaces 瘦身成组卡(机制+链接),software-inventory 改计数对账面,known-issues 只留真限制(裁定移 ADR);新增 AGENTS.md 五节合同与 docs/adr 6 篇、docs/diary 3 篇,本文件瘦身为会话本位
- 镜像源与参数口径:[docs/params.md](docs/params.md);GITHUB_MIRROR 默认 `https://proxy.ohmygh.com/`

## 近三轮(细节在 diary)

- 2026-10-10 纯离线三轮 + 快失败默认化 + smali 批 → [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md)
- 2026-10-09 评审双批 + 归档三轴 + 全做批 → [docs/diary/2026-10-09-review-rounds.md](docs/diary/2026-10-09-review-rounds.md)
- 2026-10-08 基线构建 + fresh 验证 17 坑 → [docs/diary/2026-10-08-build-baseline.md](docs/diary/2026-10-08-build-baseline.md)

## 待办

1. 合入定制 Chrome:等用户通知构建完成 → install-tools.sh 加 chrome 组(对接 vnc-screen.sh :99 屏)→ 增量发布。
2. 脚本级疑点(items 迁移轮 18 工位发现,待裁定是否修):install_bun 早退判据在 bunfig 写入之前(install-runtimes.sh,增量重跑刷不上 bunfig);install_zig 的 profile.d 写入与 install_nim 整组配置在早退判据之后(同复发模式,AGENTS.md Must);jwt_tool/LinkFinder wrapper 走系统 python3 但依赖进 re-venv(功能面存疑)。
3. 库缓存层的 repo 侧钉版(phase B):go-prewarm go.mod、cargo 预热 Cargo.lock、js-lab package-lock、maven 解析后 pom 目前在镜像侧锁、未回收入库;要回收就把锁文件提到 scripts/lock/ 并让 libcache 消费。
4. 已知遗留(不阻塞,细节见 docs/known-issues.md):webcrack 传递依赖 isolated-vm 被拦;frida windows-x86 server 多数版本未发布;coffee-ldr nightly 编译失败(上游);trivy db 为构建日快照;nuclei headless 无 Chrome 不可用。

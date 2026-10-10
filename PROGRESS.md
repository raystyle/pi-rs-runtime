# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-10。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。治理合同见 [AGENTS.md](AGENTS.md),文档地图见 [docs/README.md](docs/README.md)。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活,断网冒烟为发布门禁),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库(ADR-0001)。

## 当前状态

- 线上镜像:**`31ccc42d8eaf`**(17.3 GB);历史发布链见 [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md) 尾部
- 镜像内唯一副本 scripts 在 /root/scripts;复跑/发布命令见 AGENTS.md Commands
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
2. 已知遗留(不阻塞,细节见 docs/known-issues.md):webcrack 传递依赖 isolated-vm 被拦;frida windows-x86 server 多数版本未发布;coffee-ldr nightly 编译失败(上游);trivy db 为构建日快照;nuclei headless 无 Chrome 不可用。

# 任务进度与历史轨迹:会话记忆

最后更新:2026-10-12。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。治理合同见 [AGENTS.md](AGENTS.md),文档地图见 [docs/README.md](docs/README.md)。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活,断网冒烟为发布门禁),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库(ADR-0001)。

## 当前状态
- 2026-10-13 agent 网关烤进镜像 + ACP 对外(细节归 docs/diary/2026-10-13-agent-gateway-acp-expose.md):overcast 网关按「完整照本机」接线(claude managed settings env 12 键 + codex config 三份 + 共享模型目录 + web_search 禁用;令牌经环境变量或令牌文件给,仓库公开绝不进 git);acpsup 转 systemd 常驻,incus proxy 绑 tailnet 地址 10.10.10.13:7663 对外(用户裁定;LAN 面不开,Bearer 默认拒绝,无 token 401,带 token 200,LAN 探测 000);外部回环:claude/codex session/new+prompt 双过网关模型 zp-cc-glm53[1m]/zp-cx-glm53,CLI root/ubuntu 四回环全绿;无令牌重跑防回退闸过;方向裁定:对外 ACP 接口改独立 Golang 服务(本仓独立目录,随容器部署,claude/codex/pi 三后端),研究单 acpex-01 已派 grok(w7:p5);REQ-0007 已立单开 M0(acpsvc 建库六包+cmd,go test 门禁进 install_acp,实例内全绿,7663 面板零改动);网关地址改 tailnet 10.10.10.9:8317 且变量化(脚本默认值移除,params 同步;preferred_auth_method 0.162.1 不识别,烤库 config 移除)

- 2026-10-12 用词:册节名是「版本」和「文件」。机制称版本锁定,路径称安装路径。`docs/doc-spec.md` 第 5 节已禁「版本钉」「钉版」「钉名」「落点」。
- 线上镜像:**`5e947cfcd98e`**(18.7 GB);历史发布链见 [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md) 尾部
- 2026-10-11 agent 平台轮(十批+entropia 晚批,全程细节归 [docs/diary/2026-10-11-agent-platform-rounds.md](docs/diary/2026-10-11-agent-platform-rounds.md)):回归五缺口修复+宿主信号策略发现;rea/rctl(REQ-0001)/agents/acp(REQ-0002)/清点分类归档(七域+audit 清零)/物化预热(REQ-0003)/工作流补缺(REQ-0004,交叉链+stego+web 泄漏);grok 十一笺联席;catalog 447 件、87 册、四 REQ implemented;实例开发态未打包(用户裁定)
- 2026-10-12 acp-01(grok 调研,断言 5/5 过):pi-rs 自实现 ACP Agent 侧可行,ACP prompt 轮与 AgentSession.prompt 到 agent_settled 同构;MVP=rs-agent 内新 mode(--mode acp 加 acp-entry.ts,stdio JSON-RPC,直接调 AgentSession,与私有 JSONL rpc mode 并存不桥接,chord 不承担帧);S-0002 五节补三句落地;pi-rs 实现单待派(九件清单在轮次档 acp-01-research.md 第 4 节)
- 2026-10-12 余账推进轮:impacket 闭集族全表收口(+46 机器行,catalog 447 到 493 件,shim 全在位,断网 -h 抽验 4/4,册离线行为转已验);冒烟收编 scripts/smoke-release.sh 完成过评审落地(smoke-01 四假过全修+视角双守卫+跑板重写,真双视角断网全绿 root 81/0、ubuntu 68/0,负控 root 进程跑 ubuntu 视角退 2);rctl 搜索回归与召回优化(金标 27 案 recall@10 门禁,MRR 0.502 到 0.944,caps 双语词袋+家族桥);**REQ-0005 rctl 语义搜索落地**(zg 引擎容器冷构建+qwen3-embedding-0.6b 烤库 610M sha256 锚+微文档索引 494 件 5.3M,断网双视角 engine=zvec 纯语义命中,查询 1.3s,回退词面恒绿;册 88、catalog 494);**REQ-0006 资源契约 JSON 迁移批落地**(resources.json 495 件+caps 24 条为结构真源,gen 翻转为投影+册双向对账 236 行+book 落盘守卫,容器 audit 361/0/0 全绿,族守卫 220 零漂移,金标 14/0;顺手修旧蒸馏 bytewise 截断 29 处,投影序改码点排序;AGENTS 单一真相改写:结构在 JSON、叙事在册、tsv 投影勿手改);**产品级文档规范落地**(docspec-01,grok 研究执笔断言过:docs/doc-spec.md 立分类矩阵/八签册模板/禁词表 21 行/字段长度契约 desc≤80 pin≤80 offline≤90/迁移序九步;守卫成形 scripts/check-doc-style.sh 基线棘轮即刻生效,基线 field_overlength 158/field_banned 48/md_banned_lines 274/md_old_tags 94 只许降;88 册改写按迁移序排批)
- 方向档:完整系统容器进 web 平台(左 chat 可切 agent,右持久浏览器 VNC,平台在另项目);自建 agent API 网关=独立服务(overcast,tailnet 地址 10.10.10.9:8317;镜像侧经 AGENT_GATEWAY_URL 变量接线,2026-10-13 落,不落死值);对外 ACP 接口独立 Golang 服务(本仓独立目录,claude/codex/pi 三后端,研究单 acpex-01);实例 RPC=ACP v1+stdio(S-0002);rctl=给 agent 用的 CLI;自家 agent 定名 pi-rs(agents 面留位)

6. ACP 对外 Go 服务(acpsvc):研究已回收并归档 [S-0003](docs/research/S-0003-acpsvc-go.md)(回执 49 过/1 撤/6 缺,抽核 3/3);REQ-0007 草案在 S-0003 内可照抄(scripts/acpsvc/ 独立 Go 工程、M0-M3 迁移序、slog+lumberjack 日志、多密钥限流、三后端 claude/codex/pi);REQ-0007 已立单(draft)且 M0 已落:go test 六包绿进 install_acp 门禁、selftest 次序坑修正(/shutdown 前置),面板零改动;下一步 M1(依赖锁定进 resolve-pins + stdio/平台 HTTP 移植 + 7664 selftest);publish 按用户指示等全部调好再议;当前 TS acpsup + systemd + tailnet proxy 引出是过渡面,7663/token/端点在 M2 切流后不变
## 近三轮:细节在 diary

- 2026-10-10 纯离线三轮 + 快失败默认化 + smali 批 ,到  [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md)
- 2026-10-09 评审双批 + 归档三轴 + 全做批 ,到  [docs/diary/2026-10-09-review-rounds.md](docs/diary/2026-10-09-review-rounds.md)
- 2026-10-08 基线构建 + fresh 验证 17 坑 ,到  [docs/diary/2026-10-08-build-baseline.md](docs/diary/2026-10-08-build-baseline.md)

## 待办

0. ~~REQ-0004 工作流补缺~~(2026-10-11 完成,grok prt-10):交叉编译四套 g++-13(arm64/armhf/mips/mipsel;aarch64 静态真 ELF 实证)+ i386 multilib(gcc-multilib 与 cross 包打包互斥,走 libc6-dev-i386 头道,gcc -m32 出 i386 ELF 实证);stego 四件(zsteg gem/stegseek deb 锁定 sha256/outguess/foremost);web 三件(phpggc wrapper php8.3/git-dumper uv tool/commix);SSTImap 独立 venv(tplmap 停维护不装);apkid uv tool 独立;九件断网全过;P2 留置 fenjing/stegsnow/pngcheck/riscv64 交叉链

0. ~~prt-07 阶段 3 拆册~~(2026-10-11 完成):五短册落地(SecLists/capa-rules/yara-rules 语料册 + pspy/volatility3 一事实一册,原处改链)+ zig 冲突解(缓存册改名 zig-cache.md,工具链独占 zig)+ angr 10.0.3 独立 venv(禁 extra,断网 import 过);待裁定余项:HackTricks(1GiB)/GTFOBins(代理全 403);阶段 2 余项:impacket 全表生成+无主 5 件裁定

0. ~~域分类定稿~~(prt-09 已交并吸收):七域定稿确认(数据分析独立成域正确,不加第八域;kind 与域两面并存);三处改判落地(frida/jadx/apktool/capa/pwndbg 与 floss/ilspycmd/smali/baksmali 到 逆向环境,vol/volshell/netexec/pspy 到 工具环境,poc-search 到 工具环境);一级七域够用,ATT&CK 战术留作 caps 多值标签不进 env;docs/items/README 增七域归档视图;待裁定:angr(单独 venv)/HackTricks(1GiB)/GTFOBins(代理 401)

1. ~~prt-07 阶段 2 裁定项~~(2026-10-12 收口,实为旧口径误标:八件在 catalog 全有行):microsoft=pwsh 发行树安装路径行补写、nuget.exe 行早有(libcache/dotnet 册)、httpclient/rwinrm/rwinrmcp 升显式行进 evil-winrm 册(gem 副件)、atlas 早有 nim 行、nokogiri(PROGRESS 原拼写 nokokiri 系误)升显式行进 red 册、ruff 行早有(tools-cli 册);catalog 494 件八件全带 path;坑:起底时没先对 HEAD 行就断「无主」,差点造 ruff/nuget.exe 跨册双归属,自查撤重
2. ~~catalog 空 path 行定性~~(2026-10-12 pathq-01 裁定=混合并已实施):gen 蒸馏读册表入口/安装路径列(文件形直取/目录形拼入口/apt 兜底/多名不猜),空 path 202 到 156;/usr/bin 不进路径库根名单(where 只答资源树,S-0001 L2 行补写);剩 156 属混格册,归 REQ-0006 迁移面补入口列;exploitdb 定性=GitLab 官方本尊(resolve 增 GIT_SOURCE_URL 覆写表,GitHub 副本 force-push/停更均不可钉);TCCLI 钉复原升 3.1.181.1(pypi.org 直连回挑战页,改 aliyun simple 道),未写锁定版本清零;HackTricks 文本面=10-11 已实现(本日重复造轮回滚),浅克隆非 HEAD 钉 bug 修

1. ~~合入定制 Chrome~~(2026-10-10 prt-01 完成;**同日晚又因上游修 bug 裁定下架**:镜像卸 /opt/clean-chrome 与三链,chrome 组移出 TOOLS_ALL 默认(显式可跑),机制与 ADR-0007 留仓备用;browse CLI 维持不装):browse CLI 暂缓(仓不可达,T1 挂起等凭证);clean-chrome 155.0.8059.39 经云端道(chrome.ohmygh.com 版本段路由+sha256 锚)进镜像,系统级单副本 /opt/clean-chrome(ADR-0007);vnc-screen.sh 增 chrome 冒烟面(CDP 9222,实证 root/ubuntu/断网三视角 `Chrome/155.0.8059.39`);实证坑:155 挂 --remote-debugging-address 就绑不了 CDP 口(摘除),Chrome 136+ 无 --user-data-dir 时 CDP 静默不开。
2. ~~脚本级疑点~~(2026-10-10 两批 swarm 全清):bun/zig/nim 早退后配置写入已挪前(golang 组 profile.d 同坑顺手修);jwt_tool/LinkFinder wrapper 实证活 bug(系统 python3 无依赖必炸)已改 re-venv python + 依赖锁定版本;golang 早退跳过补装残留已由早退判据补三件套存在性根治(删 dlv 残留态实证重跑补装过);rust 组 rustup-init 守卫加执行探针(shim 空转不再卡死)。
3. ~~库缓存层的 repo 侧锁定版本(phase B)~~(2026-10-10 完成):六生态锁文件入库 `scripts/lock/`(go.mod+go.sum、Cargo.toml+Cargo.lock(31 crate 清单重建 generate-lockfile 收割)、package-lock.json、resolve-ranges 写回后 pom.xml、dotnet-prewarm.csproj、build.zig.zon);install-libcache.sh 有锁消费锁(go build 用 go.sum / cargo fetch --locked / npm ci / mvn 直消费解析后 pom / dotnet restore / zig build --fetch),无锁或 LIBCACHE_RESOLVE=1 走构建日解析并打印「未锁」;新 `scripts/sync-locks.sh` 起临时容器从线上镜像解析态再生拉回(rt-locksync,用完自删);python/pwsh 无独立锁文件(pins.sh 钉直接依赖)不在同步面。容器实证(rt-lh):六组锁消费路径全过(go build 锁 19+19 模块、npm ci 255 包/161 安装路径、cargo fetch --locked、restore 9 段、zig 10 包)
4. 已知遗留(不阻塞,细节见 docs/known-issues.md):webcrack 传递依赖 isolated-vm 被拦;frida windows-x86 server 多数版本未发布;coffee-ldr nightly 编译失败(上游);trivy db 为构建日快照;nuclei headless 无 Chrome 不可用;**宿主层信号投递策略**(容器内 kill 族全 EPERM,宿主侧问题,进程管理类动作受限)。
5. ~~冒烟脚本入库化~~(2026-10-12 完成,smoke-01 评审过):`scripts/smoke-release.sh` 落地为发布门禁面,grok 评审四假过全修(TOOLS_ALL 词边界/profile 逐路径/vnc 分支败态/skip 不计分)+ 视角双守卫 + 跑板五步法;断网真双视角 root 81/0、ubuntu 68/0,负控退 2;AGENTS.md Commands 收跑法行


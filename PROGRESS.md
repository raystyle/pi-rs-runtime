# 任务进度与历史轨迹:会话记忆

最后更新:2026-10-12。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。治理合同见 [AGENTS.md](AGENTS.md),文档地图见 [docs/README.md](docs/README.md)。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活,断网冒烟为发布门禁),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库(ADR-0001)。

## 当前状态

- 线上镜像:**`5e947cfcd98e`**(18.7 GB);历史发布链见 [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md) 尾部
- 2026-10-11 agent 平台轮(十批+entropia 晚批,全程细节归 [docs/diary/2026-10-11-agent-platform-rounds.md](docs/diary/2026-10-11-agent-platform-rounds.md)):回归五缺口修复+宿主信号策略发现;rea/rctl(REQ-0001)/agents/acp(REQ-0002)/清点分类归档(七域+audit 清零)/物化预热(REQ-0003)/工作流补缺(REQ-0004,交叉链+stego+web 泄漏);grok 十一笺联席;catalog 447 件、87 册、四 REQ implemented;实例开发态未打包(用户裁定)
- 2026-10-12 acp-01(grok 调研,断言 5/5 过):pi-rs 自实现 ACP Agent 侧可行,ACP prompt 轮与 AgentSession.prompt 到 agent_settled 同构;MVP=rs-agent 内新 mode(--mode acp 加 acp-entry.ts,stdio JSON-RPC,直接调 AgentSession,与私有 JSONL rpc mode 并存不桥接,chord 不承担帧);S-0002 五节补三句落地;pi-rs 实现单待派(九件清单在轮次档 acp-01-research.md 第 4 节)
- 方向档:完整系统容器进 web 平台(左 chat 可切 agent,右持久浏览器 VNC,平台在另项目);自建 agent API 网关;实例 RPC=ACP v1+stdio(S-0002);rctl=给 agent 用的 CLI;自家 agent 定名 pi-rs(agents 面留位)

## 近三轮:细节在 diary

- 2026-10-10 纯离线三轮 + 快失败默认化 + smali 批 ,到  [docs/diary/2026-10-10-offline-rounds.md](docs/diary/2026-10-10-offline-rounds.md)
- 2026-10-09 评审双批 + 归档三轴 + 全做批 ,到  [docs/diary/2026-10-09-review-rounds.md](docs/diary/2026-10-09-review-rounds.md)
- 2026-10-08 基线构建 + fresh 验证 17 坑 ,到  [docs/diary/2026-10-08-build-baseline.md](docs/diary/2026-10-08-build-baseline.md)

## 待办

0. ~~REQ-0004 工作流补缺~~(2026-10-11 完成,grok prt-10):交叉编译四套 g++-13(arm64/armhf/mips/mipsel;aarch64 静态真 ELF 实证)+ i386 multilib(gcc-multilib 与 cross 包打包互斥,走 libc6-dev-i386 头道,gcc -m32 出 i386 ELF 实证);stego 四件(zsteg gem/stegseek deb 钉 sha256/outguess/foremost);web 三件(phpggc wrapper php8.3/git-dumper uv tool/commix);SSTImap 独立 venv(tplmap 停维护不装);apkid uv tool 独立;九件断网全过;P2 留置 fenjing/stegsnow/pngcheck/riscv64 交叉链

0. ~~prt-07 阶段 3 拆册~~(2026-10-11 完成):五短册落地(SecLists/capa-rules/yara-rules 语料册 + pspy/volatility3 一事实一册,原处改链)+ zig 冲突解(缓存册改名 zig-cache.md,工具链独占 zig)+ angr 10.0.3 独立 venv(禁 extra,断网 import 过);待裁定余项:HackTricks(1GiB)/GTFOBins(代理全 403);阶段 2 余项:impacket 全表生成+无主 5 件裁定

0. ~~域分类定稿~~(prt-09 已交并吸收):七域定稿确认(数据分析独立成域正确,不加第八域;kind 与域两面并存);三处改判落地(frida/jadx/apktool/capa/pwndbg 与 floss/ilspycmd/smali/baksmali 到 逆向环境,vol/volshell/netexec/pspy 到 工具环境,poc-search 到 工具环境);一级七域够用,ATT&CK 战术留作 caps 多值标签不进 env;docs/items/README 增七域归档视图;待裁定:angr(单独 venv)/HackTricks(1GiB)/GTFOBins(代理 401)

1. prt-07 阶段 2:闭集族全表生成(impacket 余 ~50 脚本、frida/rz/nim 已过半)+ 漂移守卫;阶段 2 裁定项:microsoft/nuget.exe/httpclient/rwinrm/rwinrmcp(无主)、atlas/nokokiri/ruff(uv-tool shim 未点名);别名行机制已就位(alias 列)
2. prt-07 阶段 3:拆独立册(SecLists/capa-rules/yara-rules/pspy/volatility3,数据册三条纪律)+ zig 册 id 冲突解(工具链 zig vs 缓存 zig 两册同名,拆缓存行 id=zig-cache);audit 残 12 项目录认领随拆册收口

1. ~~合入定制 Chrome~~(2026-10-10 prt-01 完成;**同日晚又因上游修 bug 裁定下架**:镜像卸 /opt/clean-chrome 与三链,chrome 组移出 TOOLS_ALL 默认(显式可跑),机制与 ADR-0007 留仓备用;browse CLI 维持不装):browse CLI 暂缓(仓不可达,T1 挂起等凭证);clean-chrome 155.0.8059.39 经云端道(chrome.ohmygh.com 版本段路由+sha256 锚)进镜像,系统级单副本 /opt/clean-chrome(ADR-0007);vnc-screen.sh 增 chrome 冒烟面(CDP 9222,实证 root/ubuntu/断网三视角 `Chrome/155.0.8059.39`);实证坑:155 挂 --remote-debugging-address 就绑不了 CDP 口(摘除),Chrome 136+ 无 --user-data-dir 时 CDP 静默不开。
2. ~~脚本级疑点~~(2026-10-10 两批 swarm 全清):bun/zig/nim 早退后配置写入已挪前(golang 组 profile.d 同坑顺手修);jwt_tool/LinkFinder wrapper 实证活 bug(系统 python3 无依赖必炸)已改 re-venv python + 依赖钉版;golang 早退跳过补装残留已由早退判据补三件套存在性根治(删 dlv 残留态实证重跑补装过);rust 组 rustup-init 守卫加执行探针(shim 空转不再卡死)。
3. ~~库缓存层的 repo 侧钉版(phase B)~~(2026-10-10 完成):六生态锁文件入库 `scripts/lock/`(go.mod+go.sum、Cargo.toml+Cargo.lock(31 crate 清单重建 generate-lockfile 收割)、package-lock.json、resolve-ranges 写回后 pom.xml、dotnet-prewarm.csproj、build.zig.zon);install-libcache.sh 有锁消费锁(go build 用 go.sum / cargo fetch --locked / npm ci / mvn 直消费解析后 pom / dotnet restore / zig build --fetch),无锁或 LIBCACHE_RESOLVE=1 走构建日解析并打印「未锁」;新 `scripts/sync-locks.sh` 起临时容器从线上镜像解析态再生拉回(rt-locksync,用完自删);python/pwsh 无独立锁文件(pins.sh 钉直接依赖)不在同步面。容器实证(rt-lh):六组锁消费路径全过(go build 锁 19+19 模块、npm ci 255 包/161 落点、cargo fetch --locked、restore 9 段、zig 10 包)
4. 已知遗留(不阻塞,细节见 docs/known-issues.md):webcrack 传递依赖 isolated-vm 被拦;frida windows-x86 server 多数版本未发布;coffee-ldr nightly 编译失败(上游);trivy db 为构建日快照;nuclei headless 无 Chrome 不可用;**宿主层信号投递策略**(容器内 kill 族全 EPERM,宿主侧问题,进程管理类动作受限)。
5. 冒烟脚本入库化:本轮回归冒烟是即席脚本(宿主 /tmp/prt-smoke-regression.sh,双视角+五生态快失败+构建面+工具扫+参考库+chrome 下架面),建议收编进 scripts/ 做发布门禁可复跑面(先过评审)。


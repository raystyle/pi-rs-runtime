# AGENTS.md

渗透测试运行时镜像维护仓(Ubuntu 24.04 noble + Incus)。仓库只维护 yaml、脚本与文档;镜像产物不入库。定位细节见 README.md 与 docs/offline.md。

## Commands

```bash
bash -n scripts/*.sh scripts/lib/*.sh          # 脚本语法检查(改后必跑)
# 名字 = pi-rs-runtime-YYYYMMDD-HHMM,主机本地时间。实例用 launch 时刻,镜像版本用 publish 时刻,两个时间不同。
# 禁止 rt-* 、禁止 -dev。当前工作实例: pi-rs-runtime-20261010-2210。有它就不要再 launch。
incus file push scripts pi-rs-runtime-20261010-2210/root/ -r
incus exec pi-rs-runtime-20261010-2210 -- bash /root/scripts/install-tools.sh <组>
incus exec pi-rs-runtime-20261010-2210 -- bash -c 'ip link set eth0 down'   # 断网冒烟
# 没有存活实例时才 launch,会解包约 3.5 分钟:
 # incus launch pi-rs-runtime "pi-rs-runtime-$(date +%Y%m%d-%H%M)"
# 这批稳定后先问用户。点头才打包;新镜像别名用打包时刻,浮动别名 pi-rs-runtime 再指向它:
 # incus publish <实例> --alias "pi-rs-runtime-$(date +%Y%m%d-%H%M)"
```

## Must

- 脚本幂等 + 钉版 + 可升级;幂等判据存在早退的组,配置写入一律放早退之前
- **钉版纪律**:安装脚本只消费 `scripts/lib/pins.sh`(go/crate/pypi/gem/nuget/npm/psgallery/git 八映射 + 标量);新增消费点必须先把清单加进 `scripts/resolve-pins.sh` 并跑它补钉;缺钉直接失败,禁止漂回 @latest/漂 HEAD;升级 = 跑 `scripts/resolve-pins.sh`(全量约 21s,并行 16)+ 审 diff;库缓存传递闭包锁在 `scripts/lock/`(六生态),升级传递闭包再加跑 `scripts/sync-locks.sh`(容器内再生+校验拉回);锁与钉失步时 npm ci/cargo --locked 会硬失败(设计意图)
- 一切能力声明要容器实证(断网冒烟),不许「应该能跑」;验证要覆盖 root 与 ubuntu 双视角
- 推送脚本进容器后必须 grep 验证内容落地;跑批中的脚本禁止换盘重推(bash 按字节偏移续读)
- **一批一实例**:已有工作实例时禁止再 `incus launch`(每次都是整盘解包)。改动都进该实例;稳定后先问用户,点头才 `incus publish`(整盘 gzip,约 18–22 分钟)。不自行决定发或不发,也不为单笔改动再解包再打包
- **版本名**:`pi-rs-runtime-YYYYMMDD-HHMM`(主机本地时间)。实例名取 launch 时刻,镜像版本别名取 publish 时刻,两者不是同一时间。浮动别名 `pi-rs-runtime` 只指向最新已发布镜像。禁止 `rt-*` 和 `-dev`
- 文档单一真相:件级事实(版本/来源/落点/离线行为)只在 `docs/items/<组>/<件>.md`;新增或改动件时同步该件文档,并在 items 索引对账计数
- 不可逆裁定立 ADR(docs/adr/),实现回填;每轮工作落 PROGRESS.md 当前状态,历史轮次归 docs/diary/

## Must not

- 不提交镜像产物、不提交 /tmp 路径下的评审报告全文(链接口径即可)
- 不在 install-surfaces/ 与 software-inventory.md 重写逐件版本/来源(那是 items/ 的面,双写必漂移)
- 不在 heredoc 里写 shell 注释(会混进产物);不用 `cmd | head` 的退出码做断言
- 不关非自建的 incus 容器/镜像;不动 main 以外的分支策略

## Read first

1. `PROGRESS.md`(当前状态、待办、发布链指纹)
2. `docs/README.md`(文档地图)
3. `docs/items/README.md`(逐件索引与计数对账)

## 环境

- 构建机:Linux + Incus(sudo),镜像 publish 约 18-22 分钟,launch 解包约 3.5 分钟
- `GITHUB_MIRROR` 默认 `https://proxy.ohmygh.com/`(只代理 GitHub 系,置空回直连);镜像源口径见 docs/params.md
- 宿主 DNS 复发整挂时:`sudo resolvectl dns wlo1 223.5.5.5 223.6.6.6`
- 评审邻居:grok 工位经 herdr 派发(协议见 herdr-flywheel 纪律)

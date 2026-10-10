# AGENTS.md

渗透测试运行时镜像维护仓(Ubuntu 24.04 noble + Incus)。仓库只维护 yaml、脚本与文档;镜像产物不入库。定位细节见 README.md 与 docs/offline.md。

## Commands

```bash
bash -n scripts/*.sh scripts/lib/*.sh          # 脚本语法检查(改后必跑)
# 增量发布链(默认路线,脚本幂等可重跑):
incus launch pi-rs-runtime rt-edit && incus file push scripts rt-edit/root/ -r
incus exec rt-edit -- bash /root/scripts/install-tools.sh <组>   # 只跑改动组
incus stop rt-edit && incus image alias delete pi-rs-runtime && incus publish rt-edit --alias pi-rs-runtime
incus image delete <旧指纹> && incus delete rt-edit
# 断网验收(离线承诺的实证门禁):
incus exec rt-edit -- bash -c 'ip link set eth0 down'  # 然后跑受影响面的冒烟
```

## Must

- 脚本幂等 + 钉版 + 可升级;幂等判据存在早退的组,配置写入一律放早退之前
- **钉版纪律**:安装脚本只消费 `scripts/lib/pins.sh`(go/crate/pypi/gem/nuget/git 五映射 + 标量);新增消费点必须先把清单加进 `scripts/resolve-pins.sh` 并跑它补钉;缺钉直接失败,禁止漂回 @latest/漂 HEAD;升级 = 跑 `scripts/resolve-pins.sh` + 审 diff + 增量发布
- 一切能力声明要容器实证(断网冒烟),不许「应该能跑」;验证要覆盖 root 与 ubuntu 双视角
- 推送脚本进容器后必须 grep 验证内容落地;跑批中的脚本禁止换盘重推(bash 按字节偏移续读)
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

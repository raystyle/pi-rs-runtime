# recon 组册:侦察指纹参考(4 仓)

> MAC/服务指纹库与 DNS 协议栈、CVE PoC 索引参考,只克隆归档 ｜ 状态:参考克隆 ｜ 组:`install-tools.sh recon`

- **版本钉**:4 仓全部 `git clone --depth 1` 未钉提交(升级靠重跑组)
- **来源与安装**:GitHub 经 `GITHUB_MIRROR` 循环克隆(`scripts/install-tools.sh install_recon`),幂等判据 `.git` 目录在否,每仓失败重试一次、仍败 echo 「下轮补」;同段还生成 poc-search wrapper 与 parquet 离线索引,见 [poc-search 册](poc-search.md)
- **落点**:`/opt/recon-ref/<仓>`,4 仓对账表:

| 仓 | 用途 | 落点 |
|---|---|---|
| [runZeroInc/mac-tracker](https://github.com/runZeroInc/mac-tracker) | MAC 地址厂商指纹库 | /opt/recon-ref/mac-tracker |
| [rapid7/recog](https://github.com/rapid7/recog) | 服务/产品指纹规则库 | /opt/recon-ref/recog |
| [hickory-dns/hickory-dns](https://github.com/hickory-dns/hickory-dns) | DNS 协议栈源码参考 | /opt/recon-ref/hickory-dns |
| [nomi-sec/PoC-in-GitHub](https://github.com/nomi-sec/PoC-in-GitHub) | CVE PoC 索引仓(README 含恶意样本警示;只克隆索引,不递归) | /opt/recon-ref/PoC-in-GitHub |

- **配置与缓存**:无(只克隆不写配置;`poc-index.parquet` 是构建期固化数据,机制见 [poc-search 册](poc-search.md))
- **离线行为**:✅ 断网在位核验——断网冒烟覆盖「参考库在位」面([离线机制 §验证](../../offline.md),2026-10-10 轮 78/0);指纹库纯读盘不触网。验证:`ip link set eth0 down` 后 `ls /opt/recon-ref` 四仓齐
- **坑与留痕**:PoC-in-GitHub 索引仓 README 明示混有恶意样本,本组只克隆索引供查询,下载执行是使用者自己的裁量(留痕 [known-issues](../../known-issues.md));`/opt/recon-ref` 是三轴归档的侦察轴,裁定见 [ADR-0002](../../adr/ADR-0002-reference-clone-three-axis.md)

# trufflehog

> git 历史与云密钥扫描器(与 gitleaks 互补,带 verify 校验) ｜ 状态:已装 ｜ 组:`install-tools.sh secgo`

- **版本钉**:release tag 经 `git ls-remote --tags`(GITHUB_MIRROR 前置)+ 只取 `refs/tags/vX.Y.Z` 纯版本 + `sort -V | tail -1` 取最新;无校验和([known-issues](../../known-issues.md) 登记);`have` 早退,升级须先删 `/usr/local/bin/trufflehog` 再重跑 secgo 组
- **来源与安装**:[trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog) releases 预编译 tarball(`trufflehog_<ver>_linux_<arch>.tar.gz`,arch 只认 amd64/arm64);安装面 `scripts/install-tools.sh` `install_secgo` 尾部(不走 go install,原因见坑①)
- **落点**:`/usr/local/bin/trufflehog`(`install -m755` 直装,非软链);/tmp 临时档用完即删
- **配置与缓存**:无
- **离线行为**:✅ 本地 `filesystem`/`git` 扫描断网可跑——纯本地读盘;离线轮冒烟实证 3.99 扫空目录退 1(见坑④)。验证:`ip link set eth0 down` 后 `mkdir -p /tmp/th-empty && trufflehog filesystem /tmp/th-empty` 完成扫描(零命中退 1 属正常,看输出别看退出码)。✅ 边界:verify(回连源头验密钥有效性)与云 API 枚举断网失败属设计([offline.md](../../offline.md) §边界实证口径)
- **坑与留痕**:①上游 go.mod 带 replace 指令,`go install @版本` 被 go 拒装(实证 v3.99.2)→ 改 release 预编译,裁定留痕 [ADR-0006](../../adr/ADR-0006-user-rulings-log.md);②tag 排序必须用 `sort -V`:旧式 `sort -t. -k2` 不比较主版本,v4.0.0 会排输 v3.100.0(grok 评审 G1 实证);③未知架构先置空再判:set -u 下 case 未命中读到未赋值变量会提前退出(grok 评审 G1);④零命中退 1:3.99 `filesystem` 零命中也退 1(实证空目录 rc=1),自动化断言看输出内容别看退出码([known-issues](../../known-issues.md))

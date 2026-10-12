# trufflehog

> git 历史与云密钥扫描器(与 gitleaks 互补,带 verify 校验) ｜ 状态:已装 ｜ 组:`install-tools.sh go-security`

## 版本

- `TRUFFLEHOG_VERSION` = v3.99.2(解析日 2026-10-10)。
- 未写锁定版本时,经 `GITHUB_MIRROR` 执行 `git ls-remote --tags`。
- 只取 `refs/tags/vX.Y.Z` 这种纯版本标签。
- 用 `sort -V | tail -1` 取最新标签。
- 无校验和。见 [known-issues.md](../../known-issues.md)。
- 幂等判据是 `have trufflehog`,命中则早退。
- 升级:执行 `scripts/resolve-pins.sh`,删除 `/usr/local/bin/trufflehog`,再执行 go-security 组。

## 来源与安装

- 上游:[trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)。
- 下载 release 预编译包 `trufflehog_<ver>_linux_<arch>.tar.gz`。
- 架构只认 amd64 与 arm64。
- 脚本:`install-tools.sh` 的 `install_go-security` 尾部。
- 不走 `go install`。原因见「限制」第 1 条。

## 文件

- `/usr/local/bin/trufflehog` 由 `install -m755` 直接安装,不是软链。
- `/tmp` 里的临时文件用完即删。

## 配置

- 无。

## 离线行为

- 支持本地 `filesystem` 与 `git` 扫描。扫描只读磁盘。
- 3.99 扫描空目录时退 1。见「限制」第 4 条。
- 关闭 eth0 后,`mkdir -p /tmp/th-empty && trufflehog filesystem /tmp/th-empty` 能完成扫描。
- 零命中时退 1 是正常结果。看输出,不看退出码。
- verify 会回连源头检查密钥是否有效。断网时失败是设计边界。
- 云 API 枚举在断网时失败,同样是设计边界。见 [offline.md](../../offline.md)。

## 限制

- 上游 `go.mod` 带 `replace` 指令。`go install @版本` 被 go 拒绝,v3.99.2 即如此。因此改用 release 预编译包。
- 标签排序必须用 `sort -V`。
- 旧式 `sort -t. -k2` 不比较主版本,`v4.0.0` 会排在 `v3.100.0` 后面。
- 未知架构先置空,再判断是否下载。
- 在 `set -u` 下,`case` 未命中时读取未赋值变量会提前退出。
- 3.99 的 `filesystem` 在零命中时也退 1。空目录的退出码是 1。
- 自动化断言看输出内容,不看退出码。见 [known-issues.md](../../known-issues.md)。

## 参见

- [go-security.md](go-security.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

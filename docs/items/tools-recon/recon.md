# recon 组册:侦察指纹参考,4 仓

> MAC/服务指纹库与 DNS 协议栈、CVE PoC 索引参考,只克隆归档 ｜ 状态:参考克隆 ｜ 组:`install-tools.sh recon`

## 版本

- 4 仓都由 pins.sh 的 `GIT_PIN` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。
- 解析日 2026-10-10。
- 升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_recon`。
- 经 `GITHUB_MIRROR` 循环克隆。
- 幂等判据是 `.git` 目录是否存在。
- 每个仓失败后重试一次。
- 仍然失败时 echo,本次不安装。再次执行该组时安装。
- 同一段还生成 poc-search 的 wrapper 与 parquet 离线索引。见 [poc-search.md](poc-search.md)。

## 文件

- 根目录是 `/opt/recon-ref/<仓>`。
- 四仓的用途与路径在文末成员清单。

## 配置

- 无。
- 只克隆,不写配置。
- `poc-index.parquet` 是构建期固化的数据。机制见 [poc-search.md](poc-search.md)。

## 离线行为

- 支持确认参考库在位。见 [offline.md](../../offline.md)。
- 指纹库只读磁盘,不访问网络。
- 关闭 eth0 后,`ls /opt/recon-ref` 能看到四仓。

## 限制

- PoC-in-GitHub 的 README 写明仓内混有恶意样本。
- 本组只克隆索引,供查询。
- 下载并执行由使用者自行决定。见 [known-issues.md](../../known-issues.md)。
- `/opt/recon-ref` 是侦察参考的归档根。

## 参见

- [poc-search.md](poc-search.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## 成员清单

@@RECON_TABLE@@

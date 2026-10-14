# recon 组册:PoC 索引面

> CVE PoC 索引(poc-search 依赖);mac-tracker/recog/hickory-dns 指纹参考按 2026-10-14 瘦身批 不烤镜像(后续走 MCP) ｜ 状态:已装(仅 PoC-in-GitHub 索引) ｜ 组:`install-tools.sh recon`

## 版本

- 4 仓都由 pins.sh 的 `GIT_PIN` 锁定提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;解析日 2026-10-10;升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_recon`;经 `GITHUB_MIRROR` 循环克隆;幂等判据是 `.git` 目录是否存在;每个仓失败后重试一次;仍然失败时 echo,本次不安装。再次执行该组时安装。
- 同一段还生成 poc-search 的 wrapper 与 parquet 离线索引。见 [poc-search.md](poc-search.md)。

## 文件

- 根目录是 `/opt/recon-ref/<仓>`;四仓的用途与路径在文末成员清单。

## 配置

- 无;只克隆,不写配置;`poc-index.parquet` 是构建期固化的数据。机制见 [poc-search.md](poc-search.md)。

## 离线行为

- 支持确认参考库在位。见 [offline.md](../../offline.md);指纹库只读磁盘,不访问网络;关闭 eth0 后,`ls /opt/recon-ref` 能看到四仓。

## 限制

- PoC-in-GitHub 的 README 写明仓内混有恶意样本;本组只克隆索引,供查询;下载并执行由使用者自行决定。见 [known-issues.md](../../known-issues.md);`/opt/recon-ref` 是侦察参考的归档根。

## 参见

- [poc-search.md](poc-search.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## 成员清单

| 仓 | 用途 | 路径 |
|---|---|---|
| [runZeroInc/mac-tracker](https://github.com/runZeroInc/mac-tracker) | MAC 地址厂商指纹库 | /opt/recon-ref/mac-tracker |
| [rapid7/recog](https://github.com/rapid7/recog) | 服务/产品指纹规则库 | /opt/recon-ref/recog |
| [hickory-dns/hickory-dns](https://github.com/hickory-dns/hickory-dns) | DNS 协议栈源码参考 | /opt/recon-ref/hickory-dns |
| [nomi-sec/PoC-in-GitHub](https://github.com/nomi-sec/PoC-in-GitHub) | CVE PoC 索引仓(README 含恶意样本警示;只克隆索引,不递归) | /opt/recon-ref/PoC-in-GitHub |

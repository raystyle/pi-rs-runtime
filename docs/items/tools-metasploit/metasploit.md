# metasploit-framework:msf

> 渗透测试框架整套(msfconsole 等) ｜ 状态:未装(组保留;按 2026-10-14 瘦身批 移出镜像与默认全量,显式跑组可复得) ｜ 组:`install-tools.sh metasploit`

## 版本

- 安装器是 omnibus nightly,版本随该源;容器内 Framework 为 6.5.3(解析日 2026-10-09)。
- 安装器与 deb 都无校验和。见 [known-issues.md](../../known-issues.md)。

## 来源与安装

- 上游:[rapid7/metasploit-framework](https://github.com/rapid7/metasploit-framework)。
- 官方安装器说明:[nightly installers](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html)。
- 脚本拉取 `msfupdate.erb`。地址在 `raw.githubusercontent.com`,经 `GITHUB_MIRROR`。
- 安装器加入 `apt.metasploit.com` 源,再 apt 安装 deb;noble 源没有这个包;`apt.metasploit.com` 需要直连,没有国内镜像;脚本:`install-tools.sh` 的 `install_metasploit`。

## 文件

- 框架在 `/opt/metasploit-framework`;`msfconsole` 链到 `/usr/local/bin`。

## 配置

- `~/.msf4` 保存模块缓存与配置;该目录在首次运行时重建;`clean-image.sh` 删除构建期残留的 `/root/.msf4`;成品镜像里,每个用户首次执行 `msfconsole` 时自行创建 `~/.msf4`。

## 离线行为

- 未验证;框架与模块都在本地,没有强制联网的步骤;首次运行重建模块缓存时不访问网络;关闭 eth0 后,判定命令是 `msfconsole -qx 'exit'`,退 0。

## 限制

- 安装失败时执行 `|| echo`,不中断整组;失败的主要原因是 `apt.metasploit.com` 直连抖动;失败时本次不安装。再次执行该组时安装;幂等判据是 `have msfconsole`,命中则早退;早退时打印 `msfconsole -v` 的首行;升级走 apt。安装器留下的源保持在源列表里;离线期 `/var/lib/apt/lists` 已清除,这是预期;升级需要回到有网环境。边界见 [offline.md](../../offline.md)。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

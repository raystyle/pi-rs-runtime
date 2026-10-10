# metasploit-framework(msf)

> 渗透测试框架整套(msfconsole 等)｜ 状态:已装 ｜ 组:`install-tools.sh msf`

- **版本钉**:omnibus 随源(nightly 安装器);容器实测 Framework 6.5.3(2026-10-09 全做批);安装器与 deb 均无校验和(用户裁定留痕接受:[ADR-0006](../../adr/ADR-0006-user-rulings-log.md)、[known-issues](../../known-issues.md))
- **来源与安装**:[rapid7/metasploit-framework](https://github.com/rapid7/metasploit-framework) [官方安装器](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html) `msfupdate.erb`(raw.githubusercontent.com 经 `GITHUB_MIRROR` 拉)→ 加 apt.metasploit.com 仓后 apt 装 deb;noble 源无包,apt.metasploit.com 需直连无国内镜像(2026-10-09 路线裁定进镜像)
- **落点**:`/opt/metasploit-framework`;`msfconsole` 链 `/usr/local/bin`
- **配置与缓存**:`~/.msf4`(模块缓存/配置)首跑重建——clean-image.sh 删 `/root/.msf4`(构建期首跑残留),成品镜像内各用户首跑 `msfconsole` 自建
- **离线行为**:☐ [推断:]框架与模块全在本地,无强制联网;首跑重建模块缓存不触网,未跑断网实证。验证:`ip link set eth0 down` 后 `msfconsole -qx 'exit'` 退 0
- **坑与留痕**:安装失败语义是 `|| echo` 不中断整组(apt.metasploit.com 直连抖动是主因,失败留「下轮补」);幂等判据 `have msfconsole` 早退并打印 `msfconsole -v` 首行;升级走 apt(仓随安装器留在源列表;离线期 `/var/lib/apt/lists` 已清属预期,升级需回有网环境,边界见 [offline.md](../../offline.md))

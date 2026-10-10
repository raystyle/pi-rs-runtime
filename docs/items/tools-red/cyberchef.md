# CyberChef

> 离线加解密/编码瑞士军刀(纯静态站点)｜ 状态:已装 ｜ 组:`install-tools.sh red`

- **版本钉**:release tag 钉版——`git ls-remote --tags` 取最新 `vX.Y.Z`(api.github.com 限流 403 改用此,nushell 同款);zip 无校验和
- **来源与安装**:[gchq/CyberChef](https://github.com/gchq/CyberChef) releases 资产 `CyberChef_<tag>.zip`(**资产名保留 v 前缀**,fresh 实证 404 根因)经 `GITHUB_MIRROR` 直下,`unzip` 落盘;[red 组册](red.md)
- **落点**:`/opt/cyberchef`(静态文件);无 `/usr/local/bin` 入口
- **配置与缓存**:无
- **离线行为**:☐ [推断:]纯静态站点,设计即离线工具(脚本称「离线瑞士军刀」),本地起服即用,未跑断网实证。验证:`ip link set eth0 down` 后 `cd /opt/cyberchef && python3 -m http.server 8000` 起服,`curl -sf http://127.0.0.1:8000/` 退 0
- **坑与留痕**:幂等判据 `[ ! -d /opt/cyberchef ]`;api.github.com 限流是 fresh 构建常见失败点(2026-10-08 基线批),已改 `git ls-remote`

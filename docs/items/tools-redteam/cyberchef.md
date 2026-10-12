# CyberChef

> 离线加解密/编码瑞士军刀(纯静态站点) ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `CYBERCHEF_VERSION` = v11.5.0(解析日 2026-10-10)。
- 未写锁定版本时,用 `git ls-remote --tags` 取最新 `vX.Y.Z`。
- 不用 `api.github.com`。该接口限流时返回 403。
- nushell 使用同一回退。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[gchq/CyberChef](https://github.com/gchq/CyberChef)。
- 下载 release 资产 `CyberChef_<tag>.zip`。
- 资产名保留 `v` 前缀。
- 去掉 `v` 前缀时,该资产返回 404。
- 下载经 `GITHUB_MIRROR`。
- `unzip` 解到 `/opt/cyberchef`。
- 幂等判据是 `[ ! -d /opt/cyberchef ]`。
- 组册:[redteam.md](redteam.md)。

## 文件

- `/opt/cyberchef` 存放静态文件。
- 没有 `/usr/local/bin` 入口。

## 配置

- 无。

## 离线行为

- 未验证。
- 这是纯静态站点,本地起服务即可使用。
- 关闭 eth0 后,在 `/opt/cyberchef` 执行 `python3 -m http.server 8000`。
- 判定命令是 `curl -sf http://127.0.0.1:8000/`,退 0。

## 限制

- 目录已存在时,本组不再下载。
- zip 无校验和。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)
- [nu.md](../tools-nu/nu.md)

# capa

> 恶意软件能力识别,静态特征映射到能力与 ATT&CK ｜ 状态:已装 ｜ 组:`install-tools.sh analysis` 装本体与规则,`install-tools.sh pentest` 接线

## 版本

- `CAPA_VERSION=9.4.0`。脚本带该默认值。环境变量可覆盖。
- 上游没有 v9.5.0。最新标签是 v9.4.0。
- 规则库键:`GIT_PIN[mandiant/capa-rules]`。
- 当前值:805f9eaccfb6a4e1ddffc809d71d1e2b5ccc15e5(解析日 2026-10-10)。
- clone_pin:HEAD 等于锁定的提交则跳过。
- zip 无校验和。
- 升级:运行 `scripts/resolve-pins.sh`,再执行 analysis 组。

## 来源与安装

- 上游:[mandiant/capa](https://github.com/mandiant/capa)。
- 规则库:[mandiant/capa-rules](https://github.com/mandiant/capa-rules)。
- 本体与规则由 `install-tools.sh` 的 analysis 组安装。
- wrapper 由 pentest 组写入。
- 经 `GITHUB_MIRROR` 下载 `capa-v9.4.0-linux.zip`,解到 `/opt/capa`。
- 规则库以 `--depth 1` 克隆到 `/opt/capa-rules`。单独克隆,便于更新。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/capa | zip 解开后的程序 |
| /usr/local/bin/capa | analysis 初装时 `find /opt/capa -name capa` 的软链。pentest 组改为 wrapper |
| /usr/local/bin/capa.real | pentest 组把被包装的程序挪到此路径 |

- wrapper 内容:`exec /usr/local/bin/capa.real -r /opt/capa-rules "$@"`。

## 配置

- 规则库路径:`/opt/capa-rules`。内容是构建日快照。
- 刷新规则:在有网环境重跑 analysis 组。
- 不指定 `-r` 时,capa 把规则下载到 `~/.local/share/capa`。
- 该下载在离线时失败,错误信息不说明原因。
- wrapper 固定传入 `-r` 之后,不再使用 `~/.local/share/capa`。

## 离线行为

- 未验证。
- 规则与二进制都在本地路径。wrapper 传入 `-r` 后不访问网络。
- wrapper 层的机制见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`capa /bin/true` 跑完,且不因缺少规则而尝试下载,为判定命令。

## 限制

- 对软链执行 `printf` 重定向会改写 `/opt/capa` 里的程序。
- 该写法还会递归 exec。
- 写 wrapper 之前,先 `mv` 被包装的程序为 `capa.real`,再删除软链。
- 行为修正写在 wrapper 文件,不写 alias。
- alias 在非交互 shell 不生效。`incus exec` 属于非交互 shell。

## 参见

- [analysis.md](analysis.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: capa-rules kind=data path=/opt/capa-rules note=能力规则(缺它 capa 自下载)

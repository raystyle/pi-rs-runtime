# volatility3

> 内存取证框架,CLI 为 vol 与 volshell ｜ 状态:已装 ｜ 组:`install-tools.sh reverse`

## 版本

- pins.sh 键:`PYPI_PIN[volatility3]`;升级:运行 `scripts/resolve-pins.sh`,再执行 reverse 组。

## 来源与安装

- 脚本:`install-tools.sh` 的 reverse 组;`uv pip` 安装进 re-venv;vol 与 volshell 链到 `/usr/local/bin`;轮子在 wheelhouse,供重装。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/re-venv | 包与依赖 |
| /usr/local/bin/vol | CLI |
| /usr/local/bin/volshell | CLI |

## 配置

- 无工具配置文件;符号表按分析的镜像按需使用。

## 离线行为

- 支持。vol 与 volshell 读取本地输入;缺少符号表的内存镜像,离线可分析的范围变小。这是语料边界,不是网络依赖。

## 限制

- 内存取证归工具环境,不归逆向环境。

## 参见

- [offline.md](../../offline.md)
- [python.md](../libcache/python.md)

## rctl 收录行

- rctl: vol kind=tool path=/usr/local/bin/vol env=工具环境 note=volatility3 CLI
- rctl: volshell kind=tool path=/usr/local/bin/volshell env=工具环境

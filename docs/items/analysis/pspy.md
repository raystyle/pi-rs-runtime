# pspy

> 无 root 权限监听 Linux 进程与 cron ｜ 状态:已装 ｜ 组:`install-tools.sh discovery`

## 版本

- pins.sh 键:`GO_PIN[github.com/DominicBreuker/pspy]`;升级:运行 `scripts/resolve-pins.sh`,再执行 discovery 组。

## 来源与安装

- 脚本:`install-tools.sh` 的 discovery 组循环;安装命令:`go install`,按该锁定版本。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/go/bin/pspy | 构建产物 |
| /usr/local/bin/pspy | 链到 `/opt/go/bin/pspy` |

## 配置

- 无。单二进制。

## 离线行为

- 支持。程序枚举 `/proc`,并使用 inotify;不访问网络。

## 限制

- 用途是提权前的信息收集。

## 参见

- [offline.md](../../offline.md)

## rctl 收录行

- rctl: pspy kind=tool path=/usr/local/bin/pspy env=工具环境 note=无 root 进程刺探

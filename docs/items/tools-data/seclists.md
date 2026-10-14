# SecLists

> 渗透测试词表与数据集合集,含用户名、密码、URL、敏感模式、载荷 ｜ 状态:未装(2026-10-14 瘦身批 不烤镜像;调用方自带词表或后续走 MCP 字典服务) ｜ 组:装面在 pentest 组接线,本册独立登记

## 版本

- pins.sh `GIT_PIN[danielmiessler/SecLists]` 锁定提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;升级:执行 `scripts/resolve-pins.sh`,再执行 pentest 组。

## 来源与安装

- GitHub `clone_pin` 到 `/opt/SecLists`;rockyou 从 Passwords 解出;落到 `/usr/share/wordlists/rockyou.txt`;hashcat、john、ffuf、feroxbuster 使用这份词表。

## 文件

- `/opt/SecLists`;`/usr/share/wordlists` 是软链。

## 配置

- 无配置文件;纯数据,直接读取;目录名即分类;分类包括 Passwords、Discovery、Web-Shells。

## 离线行为

- 支持。本地直读;缺少本目录时,多个工具空跑,或自行下载词表;新鲜度等于构建日快照。

## 限制

- 顶层目录名即语义;`rctl where` 可以搜这些目录;pentest 册的接线段链接到本册;接线内容不在本册重复。

## 参见

- [pentest.md](../tools-pentest/pentest.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: SecLists kind=data path=/opt/SecLists note=词表合集(rockyou 派生在 /usr/share/wordlists)

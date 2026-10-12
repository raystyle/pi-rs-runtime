# overthrone

> Active Directory 利用框架:枚举(LDAP/SMB/Kerberos)、攻击图、横向移动(PtH/PtT)、持久化(金/银/钻石票)、中继、EDR 绕过;Rust 单二进制,无 Python/.NET/Neo4j/mimikatz 依赖 ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `GIT_PIN[karmanya03/overthrone]`=v0.4.9(解析日 2026-10-12)。

## 来源与安装

- 上游:[karmanya03/overthrone](https://github.com/karmanya03/overthrone)。
- release 预编译 tarball 或 clone_pin 源码构建(cargo build --release)。
- 入口:`overthrone` 与 `ovt`。

## 文件

- `/usr/local/bin/overthrone`(实体)。
- `/usr/local/bin/ovt` 同链。

## 配置

- XDG TOML profiles;见上游文档。

## 离线行为

- 未验证:二进制本地可跑;对目标的动作(LDAP/SMB/Kerberos 连接)需网络。

## 限制

- 活跃开发期(0.4.x);`ovt auto-pwn` 已移除,改用 `ovt wizard`。

## 参见

- [redteam 册](redteam.md)

## rctl 收录行

- rctl: overthrone kind=tool path=/usr/local/bin/overthrone alias=ovt note=AD 利用框架(枚举/攻击图/横向/持久化/中继)

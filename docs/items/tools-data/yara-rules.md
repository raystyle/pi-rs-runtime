# yara-rules

> YARA 规则社区集(Yara-Rules/rules)。构建日快照 ｜ 状态:已装 ｜ 组:装面在 analysis 组,本册独立登记

## 版本

- pins.sh `GIT_PIN[Yara-Rules/rules]` 锁定提交。
- `clone_pin` 在 HEAD 等于锁定提交时跳过。

## 来源与安装

- GitHub `clone_pin` 到 `/opt/yara-rules`。

## 文件

- `/opt/yara-rules`。

## 配置

- yara CLI 直接读取本目录。该 CLI 属于 analysis 组。
- 扫描器按文件分类,从对应子目录取规则。

## 离线行为

- 支持。本地直读。
- 规则是语料,不是查询引擎。

## 限制

- 部分规则依赖外部模块。
- 离线使用时按需选用规则。

## 参见

- [analysis.md](../analysis/analysis.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: yara-rules kind=data path=/opt/yara-rules note=YARA 规则集(语料)

# capa-rules

> capa 恶意软件能力识别规则库,带 ATT&CK 与 MBC 映射。构建日快照 ｜ 状态:已装 ｜ 组:装面在 analysis 组,本册独立登记

## 版本

- pins.sh `GIT_PIN[mandiant/capa-rules]` 锁定提交;规则库与 capa 二进制各自锁定;规则库独立演进。

## 来源与安装

- GitHub `clone_pin` 到 `/opt/capa-rules`;capa wrapper 注入 `-r`。见 [capa.md](../analysis/capa.md)。

## 文件

- `/opt/capa-rules`。

## 配置

- capa wrapper 始终带上规则路径。

## 离线行为

- 支持。本地直读;缺少规则库时,capa 把规则下载到家目录;这个失败不容易从输出里看出来。

## 限制

- 规则名带 namespace 前缀;`capa -t` 按前缀选择规则;前缀例子是 `communication/socket/tcp`;namespace 前缀可以按战术过滤。

## 参见

- [capa.md](../analysis/capa.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: capa-rules kind=data path=/opt/capa-rules note=capa 规则(namespace 前缀可按战术过滤)

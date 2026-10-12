# capa-rules

> capa 恶意软件能力识别规则库(ATT&CK/MBC 映射)｜ 状态:已装(构建日快照)｜ 组:装面在 p0 组,本册独立登记

- **版本钉**:pins.sh `GIT_PIN[mandiant/capa-rules]` 钉 sha;与 capa 二进制不同钉(规则库独立演进)
- **来源与安装**:GitHub clone_pin 到 `/opt/capa-rules`;capa wrapper 注入 `-r`(见 capa 册)
- **落点**:`/opt/capa-rules`
- **配置与缓存**:capa wrapper 恒带规则路径
- **离线行为**:过,本地直读;缺它 capa 自下载规则到家目录(晦涩错,数据册验收句命中)
- **限制**:规则命名带 namespace 前缀(capa -t 按 `communication/socket/tcp` 式前缀选,)

- rctl: capa-rules kind=data path=/opt/capa-rules note=capa 规则(namespace 前缀可按战术过滤)

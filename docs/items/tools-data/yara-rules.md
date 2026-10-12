# yara-rules

> YARA 规则社区集(Yara-Rules/rules)｜ 状态:已装(构建日快照)｜ 组:装面在 p0 组,本册独立登记

- **版本钉**:pins.sh `GIT_PIN[Yara-Rules/rules]` 钉 sha(clone_pin)
- **来源与安装**:GitHub clone_pin 到 `/opt/yara-rules`
- **落点**:`/opt/yara-rules`
- **配置与缓存**:yara CLI(p0 组)直读;扫描器面按文件分类子目录取
- **离线行为**:过,本地直读;规则是语料不是查询引擎
- **限制**:部分规则有外部依赖模块,离线面按需挑用

- rctl: yara-rules kind=data path=/opt/yara-rules note=YARA 规则集(语料)

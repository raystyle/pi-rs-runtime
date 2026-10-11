# SecLists

> 渗透测试词表与数据集合集(用户名/密码/URL/敏感模式/载荷等)｜ 状态:已装(构建日快照)｜ 组:装面在 pentest 组接线,本册独立登记

- **版本钉**:pins.sh `GIT_PIN[danielmiessler/SecLists]` 钉 sha(clone_pin 幂等);升级跑 resolve-pins.sh 重跑 pentest 组
- **来源与安装**:GitHub clone_pin 到 `/opt/SecLists`;rockyou 从 Passwords 解出落 `/usr/share/wordlists/rockyou.txt`;多工具消费(hashcat/john/ffuf/feroxbuster)
- **落点**:`/opt/SecLists`;`/usr/share/wordlists` 软链
- **配置与缓存**:纯数据直读;目录语义即分类(Passwords/Discovery/Web-Shells 等)
- **离线行为**:过,本地直读;缺它多只工具空跑或自下载(数据册验收句);新鲜度=构建日快照
- **坑与留痕**:顶层目录名即语义(rctl where 可搜);pentest 册接线段链到此,不双写

- rctl: SecLists kind=data path=/opt/SecLists note=词表合集(rockyou 派生在 /usr/share/wordlists)

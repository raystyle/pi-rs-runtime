# nuclei

> 模板化漏洞扫描引擎(YAML 模板库缓存固化) ｜ 状态:已装 ｜ 组:`install-tools.sh discovery`(本体)+ `install-tools.sh pentest`(离线接线)

## 版本

- 本体 `GO_PIN[github.com/projectdiscovery/nuclei/v3/cmd/nuclei]` = v3.11.1(解析日 2026-10-10)。
- 模板库 `/opt/nuclei-templates` 由 `clone_pin` 锁定 `GIT_PIN[projectdiscovery/nuclei-templates]` 的提交。
- HEAD 等于锁定提交时,克隆跳过;要换新模板:执行 `scripts/resolve-pins.sh`,在有网环境重跑,再 publish;新鲜度边界见 [offline.md](../../offline.md)。

## 来源与安装

- 本体上游:[projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei)。
- 经 goproxy.cn 编译,随 discovery 组安装到 `/opt/go/bin`。
- 模板上游:[projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates)。
- 模板经 `GITHUB_MIRROR` 克隆。
- 离线接线在 `scripts/install-tools.sh` 的 `install_pentest` 尾部。

## 文件

- `/usr/local/bin/nuclei.real` 是被包装的程序。pentest 组把它从 `/opt/go/bin` 挪入。
- `/usr/local/bin/nuclei` 是 wrapper,内容为 `exec /usr/local/bin/nuclei.real -duc "$@"`。
- 模板目录是 `/opt/nuclei-templates`。
- root 与 ubuntu 的家目录各有一条 `~/nuclei-templates` 软链,指向 `/opt/nuclei-templates`。
- nuclei 默认的模板路径是家目录。

## 配置

- 模板缓存就是 `/opt/nuclei-templates`,从磁盘直接读取;`-duc` 恒定禁止版本检查与模板更新检查;除此之外没有配置写入。

## 离线行为

- 支持。断网时不会停在更新检查。
- 模板从 `/opt` 直接读取。wrapper 机制见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`nuclei -tl` 列出本地模板,并且没有更新报错;未验证:断网后对本机服务做真实扫描。模板全部在盘上。
- 判定命令:断网后执行 `python3 -m http.server 8000 &`,再执行 `nuclei -u http://127.0.0.1:8000 -tags tech -silent`。

## 限制

- discovery 组尾部的 `nuclei -update-templates` 把模板写到各家目录;该命令失败时不中断安装;断网时这次更新失败,并且没有明确的退出状态;pentest 组改为克隆到 `/opt`,并在家目录放软链;家目录已有真实的 `nuclei-templates` 目录时,先挪成 `.bak`,再放软链;挪走时不删除其中的内容;`clean-image.sh` 清除 `.bak` 残留;wrapper 的幂等判据是 `nuclei.real` 不存在;写 wrapper 之前先删除旧软链。
- 对软链做 `printf` 直写会穿透,改写 `/opt/go/bin` 里的被包装程序。capa 有同一情况。
- headless 模板需要 Chrome。镜像里目前没有。见 [known-issues.md](../../known-issues.md)。
- 定制 Chrome 待合入。

## 参见

- [discovery.md](discovery.md)
- [pentest.md](../tools-pentest/pentest.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: nuclei-templates kind=data path=/opt/nuclei-templates note=模板库(缺它 nuclei 空跑/自下载;GIT_PIN 单独锁定)

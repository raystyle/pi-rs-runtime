# nuclei

> 模板化漏洞扫描引擎(YAML 模板库) ｜ 状态:已装 + 模板缓存固化 ｜ 组:`install-tools.sh pd`(本体)+ `install-tools.sh pentest`(离线接线)

- **版本钉**:本体 pins.sh 钉版(`GO_PIN[github.com/projectdiscovery/nuclei/v3/cmd/nuclei]`,当前钉值 v3.11.1,解析日 2026-10-10);模板库 `/opt/nuclei-templates` 由 clone_pin 钉 `GIT_PIN[projectdiscovery/nuclei-templates]` sha(幂等:HEAD==钉即跳过)——要新鲜模板跑 scripts/resolve-pins.sh 换钉、回有网重跑再 publish([offline.md](../../offline.md) §边界)
- **来源与安装**:[projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei) 经 goproxy.cn 编译,随 pd 组落 /opt/go/bin;模板 [projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates) 经 GITHUB_MIRROR 克隆;离线接线在 `scripts/install-tools.sh` `install_pentest` 尾部段
- **落点**:真身 `/usr/local/bin/nuclei.real`(pentest 组从 /opt/go/bin 挪入);wrapper `/usr/local/bin/nuclei` = `exec /usr/local/bin/nuclei.real -duc "$@"`;模板 `/opt/nuclei-templates`,root 与 ubuntu 家目录各一条 `~/nuclei-templates` 软链指过去(nuclei 默认模板路径即家目录)
- **配置与缓存**:模板缓存即 `/opt/nuclei-templates`(盘上直读);`-duc` 恒禁版本检查与模板更新检查;此外无配置写入
- **离线行为**:✅ 断网不卡更新检查、模板从 /opt 盘直读(wrapper 机制见 [offline.md](../../offline.md) §1/§2,渗透工具面断网冒烟口径)。验证:`ip link set eth0 down` 后 `nuclei -tl` 列出本地模板且无更新报错。☐ [推断:] 断网对本机服务真实扫描可用(模板全在盘);验证:断网后 `python3 -m http.server 8000 &` 再 `nuclei -u http://127.0.0.1:8000 -tags tech -silent`
- **坑与留痕**:pd 组尾部的在线 `nuclei -update-templates` 落各家目录且失败容忍,离线期静默坏——pentest 组改为克隆钉 /opt + 家目录软链;家目录已有真实 `nuclei-templates` 目录时挪为 `.bak` 再软链(不删内容,clean-image.sh 卫生轮清 `.bak` 残留);wrapper 幂等判据是 `nuclei.real` 不存在,写 wrapper 前先删旧软链——printf 直写软链会穿透改写 /opt/go/bin 里的真身(capa 同案 fresh 实证递归 exec);headless 模板需 Chrome,镜像暂无([known-issues](../../known-issues.md),定制 Chrome 待合入)

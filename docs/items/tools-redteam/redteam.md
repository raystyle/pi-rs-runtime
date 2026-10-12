# redteam 组:渗透测试工具增补

> AD 横向/Web/密码/移动/云批量工具面(uv tool + git 克隆 + gem + 锁定版本的 Release 四批) ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- 解析日 2026-10-10;uv tool 批逐件取 `PYPI_PIN[<包>]`;ghauri 不走 PyPI,锁定 `GIT_PIN[r0oth3x49/ghauri]` 的提交;gem 批取 `GEM_PIN[<gem>]`,共 6 个键。其中 evil-winrm 为 4.1;git 克隆批取 `GIT_PIN[<owner/repo>]` 的提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;`CYBERCHEF_VERSION` = v11.5.0;`KUBECTL_VERSION` = v1.37.1;`TRIVY_VERSION` = v0.75.0;awscli v2 随软件源。`AWSCLI_VERSION` 留空。
- 官方 zip 没有干净的版本索引。见 [known-issues.md](../../known-issues.md)。
- `have` 命中则早退。早退不会把已安装的件升到新锁定版本;升级:执行 `scripts/resolve-pins.sh`,再执行本组。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_redteam`;uv tool 先使用构建期默认索引。
- 该索引来自 `UV_CONFIG_FILE=/etc/uv/uv-online.toml`,对应 `PIP_INDEX`。
- 默认索引失败时,显式改用 tuna;bloodhound-ce 不走这套回退:tuna 没有该包,安装显式使用 pypi.org;ghauri 不在任何 PyPI,从 git 安装;git 克隆经 `GITHUB_MIRROR`;克隆失败时重试 2 次。
- gem 源换成 [gems.ruby-china.com](https://gems.ruby-china.com/),并执行 `--remove rubygems.org`。
- 安装面总表见 [tools.md](../../install-surfaces/tools.md);逐件入口、版本与来源在文末成员清单。

## 文件

- uv tool 隔离安装。`UV_TOOL_DIR=/opt/uv-tools`;`UV_TOOL_BIN_DIR=/usr/local/bin`,入口直接链接。
- 四个 venv 里依赖分支的 `*.py` 按白名单外链:certipy-ad、bloodyad、bofhound、bloodhound-ce。
- bloodhound-ce 排在白名单最后,同名脚本以它为准;没有 console entrypoint 的包写 wrapper,不做硬链。
- bloodhound-python 的 wrapper 调用 re-venv 的 `python -m bloodhound`。
- 该 wrapper 每次无条件重写;depjunk 清单删除指向 uv-tools venv 的非入口依赖 CLI;`httpx` 链回 discovery 组的 Go 产物;semgrep 只链入口名 `semgrep` 与 `pysemgrep`;git 克隆目录是 `/opt/<仓名>`。
- 四个仓内脚本的 wrapper 都执行 `exec /opt/re-venv/bin/python`:enum4linux-ng、krbrelayx、jwt_tool、LinkFinder。
- 这四件的依赖按锁定版本装进 re-venv;jwt_tool 在顶层直接 import ratelimit;LinkFinder 在顶层直接 import jsbeautifier;系统 python3 没有这些模块,用它执行会在 import 失败并退出;CeWL 安装到 `/opt/CeWL`,wrapper 名为 `cewl`;evil-winrm 的 gem 二进制在 `/usr/local/bin`;CyberChef 安装到 `/opt/cyberchef`。

## 配置

- 无组级运行期配置;各件自己的配置见对应册。

## 离线行为

- 支持六件 wrapper 的入口:enum4linux-ng、krbrelayx、bloodhound-python、cewl、jwt-tool、linkfinder。
- wrapper 层机制见 [offline.md](../../offline.md);关闭 eth0 后,逐件启动 help 面。例如 `enum4linux-ng -h` 退 0;未验证:uv tool 与 gem 的纯本地件。它们没有自更新;这些件的实际操作需要目标网络可达;CyberChef 见 [cyberchef.md](cyberchef.md)。

## 限制

- 不把 venv 的 `bin` 整目录软链到 `/usr/local/bin`。
- 整目录软链会把 `bin/python3` 链出去,劫持系统 python,并形成 ELOOP。semgrep 会因此无法运行。
- 依赖 CLI 曾盖掉 discovery 组的 Go `httpx`。这些 CLI 包括 httpx、idna、normalizer,散在 certipy-ad、bofhound、bloodhound-ce 三个 venv。
- `have` 早退不会自行修复被盖掉的链接。外链只走白名单。
- bloodhound-python 的 wrapper 无条件重写,避免被 bofhound 的依赖链盖掉。
- ghauri 在官方 PyPI、tuna、阿里云都返回 404,只从 git 仓安装;GitHub 限流时,克隆要重试;jwt_tool 与 LinkFinder 的 wrapper 执行 re-venv 的 python。
- 依赖 ratelimit、pycryptodomex、termcolor、requests、jsbeautifier 按锁定版本装进 re-venv。
- 克隆仓名是 `ticarpi/jwt_tool`、`GerbenJavado/LinkFinder`、`cddmp/enum4linux-ng`。

## 参见

- [bloodhound-ce.md](bloodhound-ce.md)
- [enum4linux-ng.md](enum4linux-ng.md)
- [evil-winrm.md](evil-winrm.md)
- [cyberchef.md](cyberchef.md)
- [trivy.md](trivy.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)
- [tools.md](../../install-surfaces/tools.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: jwt-tool kind=tool path=/usr/local/bin/jwt-tool note=wrapper(re-venv)
- rctl: linkfinder kind=tool path=/usr/local/bin/linkfinder note=wrapper(re-venv)
- rctl: pysemgrep kind=tool path=/usr/local/bin/pysemgrep
- rctl: jwt_tool kind=ref path=/opt/jwt_tool note=JWT 工具仓(wrapper 见 jwt-tool)
- rctl: LinkFinder kind=ref path=/opt/LinkFinder note=LinkFinder 仓(wrapper 见 linkfinder)
- rctl: krbrelayx kind=ref path=/opt/krbrelayx note=krbrelayx 仓(wrapper 同名)
- rctl: enum4linux-ng kind=ref path=/opt/enum4linux-ng note=enum4linux-ng 仓(wrapper 同名)
- rctl: CeWL kind=ref path=/opt/CeWL note=CeWL 仓(wrapper 见 cewl)
- rctl: RsaCtfTool kind=ref path=/opt/RsaCtfTool note=RsaCtfTool 仓
- rctl: nokogiri kind=tool path=/usr/local/bin/nokogiri note=ruby gem 副件(HTML 解析,CeWL 依赖)
- rctl: racc kind=tool path=/usr/local/bin/racc note=ruby gem 副件(解析器生成)
- rctl: rwinrm kind=tool path=/usr/local/bin/rwinrm note=winrm gem 副件(evil-winrm 依赖链)
- rctl: rwinrmcp kind=tool path=/usr/local/bin/rwinrmcp note=winrm-fs gem 副件
- rctl: httpclient kind=tool path=/usr/local/bin/httpclient note=ruby gem 副件
- rctl: nokogiri kind=tool path=/usr/local/bin/nokogiri note=RubyGems 副件 shim(CeWL 依赖显式装,1.19.4 带原生件)

## 成员清单

- 下表 24 件,与 `install_redteam` 实际安装和克隆的数量对账。
- 已有单独册的件,链接在表内。

| 件 | 批次 | 入口(`/usr/local/bin`) | 版本 | 来源与备注 |
|---|---|---|---|---|
| ghauri | uv tool(git 源) | ghauri | GIT_PIN 锁定 sha | [r0oth3x49/ghauri](https://github.com/r0oth3x49/ghauri),不在任何 PyPI |
| kerbrute | uv tool 批 | kerbrute | PYPI_PIN 0.0.2 | PyPI |
| wafw00f | uv tool 批 | wafw00f | PYPI_PIN 2.4.2 | PyPI |
| arjun | uv tool 批 | arjun | PYPI_PIN 2.2.7 | PyPI |
| bloodhound-python | uv tool 批(无 entrypoint) | bloodhound-python(wrapper,re-venv `python -m bloodhound`) | PYPI_PIN 0.2.0 | PyPI;与 CE 并存(维护者明示可共存) |
| Coercer | uv tool 批 | coercer/Coercer(命名差异链接检查) | PYPI_PIN 2.4.3 | PyPI |
| mitm6 | uv tool 批 | mitm6 | PYPI_PIN 0.3.0 | PyPI |
| objection | uv tool 批 | objection | PYPI_PIN 1.12.5 | PyPI;启动查一次 PyPI 版本,断网 DNS 快失败不阻塞([offline.md](../../offline.md) 边界) |
| apkleaks | uv tool 批 | apkleaks | PYPI_PIN 2.6.3 | PyPI |
| certipy-ad | AD 现役批 | certipy | PYPI_PIN 5.1.0 | [ly4k/Certipy](https://github.com/ly4k/Certipy),PyPI 经 tuna;ADCS 审计 |
| bloodyAD | AD 现役批 | bloodyAD | PYPI_PIN 2.5.5 | [CravateRouge/bloodyAD](https://github.com/CravateRouge/bloodyAD),PyPI 经 tuna |
| bofhound | AD 现役批 | bofhound | PYPI_PIN 0.4.25 | [coffeegist/bofhound](https://github.com/coffeegist/bofhound),PyPI 经 tuna |
| semgrep | AD 现役批 | semgrep/pysemgrep(只链入口名) | PYPI_PIN 1.180.0 | [semgrep/semgrep](https://github.com/semgrep/semgrep),PyPI 经 tuna;SAST 代码审计 |
| bloodhound-ce | AD 现役批 | bloodhound-ce-python | PYPI_PIN 1.9.1 | pypi.org 显式(tuna 缺失);见 [bloodhound-ce 册](bloodhound-ce.md) |
| jwt_tool | git 克隆批 | jwt-tool(wrapper,re-venv python;依赖 ratelimit/pycryptodomex/termcolor/requests 锁定版本) | GIT_PIN 锁定 sha | [ticarpi/jwt_tool](https://github.com/ticarpi/jwt_tool) |
| LinkFinder | git 克隆批 | linkfinder(wrapper,re-venv python;依赖 jsbeautifier 锁定版本) | GIT_PIN 锁定 sha | [GerbenJavado/LinkFinder](https://github.com/GerbenJavado/LinkFinder);requirements 进 re-venv |
| krbrelayx | git 克隆批 | krbrelayx(wrapper,re-venv python) | GIT_PIN 锁定 sha | [dirkjanm/krbrelayx](https://github.com/dirkjanm/krbrelayx);依赖 impacket/ldap3/dnspython/pyasn1 进 re-venv |
| enum4linux-ng | git 克隆批 | enum4linux-ng(wrapper,re-venv python) | GIT_PIN 锁定 sha | [cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng);见 [enum4linux-ng 册](enum4linux-ng.md) |
| CeWL | gem/ruby 批 | cewl(wrapper,`ruby /opt/CeWL/cewl.rb`) | GIT_PIN 锁定 sha | [digiNinja/CeWL](https://github.com/digiNinja/CeWL);不在 rubygems(实测搜索无此 gem),git 仓 + 依赖 gem(nokogiri/mime/mime-types/mini_exiftool/rubyzip,GEM_PIN 锁定版本) |
| evil-winrm | gem/ruby 批 | evil-winrm | GEM_PIN 4.1 | [Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm),ruby-china;见 [evil-winrm 册](evil-winrm.md) |
| CyberChef | 锁定版本的 Release | 无 CLI(`/opt/cyberchef` 静态站点) | CYBERCHEF_VERSION v11.5.0 | [gchq/CyberChef](https://github.com/gchq/CyberChef);见 [CyberChef 册](cyberchef.md) |
| kubectl | 云与内网批 | kubectl | KUBECTL_VERSION v1.37.1 | dl.k8s.io 直连(国内无二进制镜像,实测阿里云/ustc/华为均无 release 布局) |
| trivy | 云与内网批 | trivy(wrapper 压 `/usr/bin` 被包装的程序) | TRIVY_VERSION v0.75.0 | [aquasecurity/trivy](https://github.com/aquasecurity/trivy);见 [trivy 册](trivy.md) |
| awscli v2 | 云与内网批 | aws | 软件源锁定(AWSCLI_VERSION 空) | awscli.amazonaws.com 官方 zip 安装器(无国内镜像,直连不通可跳过) |

- 组头 `apt-get install --no-install-recommends` 安装 `samba-common-bin`、`smbclient`、`ldap-utils`。这是 enum4linux-ng 的运行依赖。
- 同一次还安装 `ruby-full` 与 `ruby-dev`,供 gem 批编译原生扩展。
- 这些是 noble 随源的 apt 包,不计入上表 24 件。
- rctl: overthrone kind=tool path=/usr/local/bin/overthrone alias=ovt note=AD 利用框架(枚举/攻击图/横向/持久化/中继)

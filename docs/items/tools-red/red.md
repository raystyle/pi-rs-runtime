# red 组(渗透测试工具增补)

> AD 横向/Web/密码/移动/云批量工具面(uv tool + git 克隆 + gem + Release 钉版四批)｜ 状态:已装 ｜ 组:`install-tools.sh red`

- **版本钉**:pins.sh 钉版(解析日 2026-10-10,升级跑 scripts/resolve-pins.sh):uv tool 批逐件 `PYPI_PIN[<包>]`(ghauri 例外走 git 源,钉 `GIT_PIN[r0oth3x49/ghauri]` sha);gem 批 `GEM_PIN[<gem>]`(evil-winrm 4.1 等 6 键);git 克隆批 `GIT_PIN[<owner/repo>]` 钉 sha(clone_pin,幂等:HEAD==钉即跳过);CyberChef 标量 `CYBERCHEF_VERSION`=v11.5.0、kubectl 标量 `KUBECTL_VERSION`=v1.37.1、trivy 标量 `TRIVY_VERSION`=v0.75.0;awscli v2 软钉(`AWSCLI_VERSION` 留空,官方 zip 无干净版本索引,留痕 [known-issues](../../known-issues.md));`have` 早退意味重跑不升级,升级=跑解析器后重跑本组
- **来源与安装**:`scripts/install-tools.sh` `install_red()`。uv tool 先试构建期默认索引(`UV_CONFIG_FILE=/etc/uv/uv-online.toml`,$PIP_INDEX 面),失败显式 tuna 兜底;bloodhound-ce 例外(tuna 缺失实证,显式走 pypi.org);ghauri 不在任何 PyPI 走 git 源。git 克隆经 `GITHUB_MIRROR` 且重试 2 次。gem 源换 [gems.ruby-china.com](https://gems.ruby-china.com/)(`--remove rubygems.org`)。安装面总表见 [install-surfaces/tools.md red 节](../../install-surfaces/tools.md)
- **落点与配置缓存**(批量机制):uv tool 隔离装,`UV_TOOL_DIR=/opt/uv-tools`、`UV_TOOL_BIN_DIR=/usr/local/bin`(入口直链);venv 内依赖叉的 `*.py` 按白名单外链(仅 certipy-ad/bloodyad/bofhound/bloodhound-ce 四 venv,bloodhound-ce 殿后同名优先),裁定见 [ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md);无 console entrypoint 的包写 wrapper 不硬链(bloodhound-python → re-venv `python -m bloodhound`,无条件重写);depjunk 清单清剿指向 uv-tools venv 的非入口依赖 CLI(httpx 还回 pd 组 Go 产物);semgrep 只链 `semgrep`/`pysemgrep` 入口名。git 克隆钉 `/opt/<仓名>`,仓内脚本 wrapper 一律 `exec /opt/re-venv/bin/python` 直调(四件:enum4linux-ng/krbrelayx/jwt_tool/LinkFinder;依赖钉版进 re-venv——jwt_tool 实证顶层裸 import ratelimit、LinkFinder 裸 import jsbeautifier,系统 python3 必炸,2026-10-10 钉版轮修)。CeWL 钉 `/opt/CeWL` + wrapper `cewl`;evil-winrm gem 二进位落 `/usr/local/bin`;CyberChef 钉 `/opt/cyberchef`。组级运行期配置:无(各件自管,见成员册)
- **离线行为**:wrapper 层六件(enum4linux-ng、krbrelayx、bloodhound-python、cewl、jwt-tool、linkfinder)✅ 断网冒烟渗透工具面过(78/0,2026-10-10 离线轮;机制见 [offline.md](../../offline.md) §2)。验证:`ip link set eth0 down` 后逐件起 help 面(如 `enum4linux-ng -h`)退 0。uv tool/gem 纯本地件 ☐ [推断:]无自更新机制断网可起,实战动作需目标网络可达;CyberChef 见[件册](cyberchef.md)
- **坑与留痕**:venv 全目录软链曾把 `bin/python3` 链到 `/usr/local/bin` 劫持系统 python 并成环 ELOOP(semgrep 受害),依赖 CLI(httpx/idna/normalizer 等,实证散在 certipy-ad/bofhound/bloodhound-ce 三 venv)曾盖掉 pd 组 Go httpx 且 `have` 早退不自愈 → 白名单重构([ADR-0003](../../adr/ADR-0003-uv-tool-isolation-whitelist-linking.md),grok 评审 F1);bloodhound-python wrapper 曾被 bofhound 依赖链盖掉故无条件重写;ghauri 官方/tuna/阿里云 PyPI 均 404(实证)只发 git 仓,GitHub 限流窗口需重试;三个克隆仓名曾写错(ticarpi/jwt_tool、GerbenJavado/LinkFinder、cddmp/enum4linux-ng,2026-10-08 fresh 验证修);jwt_tool/LinkFinder 曾 wrapper 走系统 python3 而依赖在 re-venv(linkfinder 实证必然起不来),钉版轮已修(wrapper 改 re-venv python,依赖 ratelimit/pycryptodomex/termcolor/requests/jsbeautifier 钉版进 re-venv)

成员表(24 件,与 `install_red` 实际安装/克隆数对账;另册件点链接):

| 件 | 批次 | 入口(`/usr/local/bin`) | 版本钉 | 来源与备注 |
|---|---|---|---|---|
| ghauri | uv tool(git 源) | ghauri | GIT_PIN 钉 sha | [r0oth3x49/ghauri](https://github.com/r0oth3x49/ghauri),不在任何 PyPI |
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
| bloodhound-ce | AD 现役批 | bloodhound-ce-python | PYPI_PIN 1.9.1 | pypi.org 显式(tuna 缺失实证);见 [bloodhound-ce 册](bloodhound-ce.md) |
| jwt_tool | git 克隆批 | jwt-tool(wrapper,re-venv python;依赖 ratelimit/pycryptodomex/termcolor/requests 钉版) | GIT_PIN 钉 sha | [ticarpi/jwt_tool](https://github.com/ticarpi/jwt_tool) |
| LinkFinder | git 克隆批 | linkfinder(wrapper,re-venv python;依赖 jsbeautifier 钉版) | GIT_PIN 钉 sha | [GerbenJavado/LinkFinder](https://github.com/GerbenJavado/LinkFinder);requirements 进 re-venv |
| krbrelayx | git 克隆批 | krbrelayx(wrapper,re-venv python) | GIT_PIN 钉 sha | [dirkjanm/krbrelayx](https://github.com/dirkjanm/krbrelayx);依赖 impacket/ldap3/dnspython/pyasn1 进 re-venv |
| enum4linux-ng | git 克隆批 | enum4linux-ng(wrapper,re-venv python) | GIT_PIN 钉 sha | [cddmp/enum4linux-ng](https://github.com/cddmp/enum4linux-ng);见 [enum4linux-ng 册](enum4linux-ng.md) |
| CeWL | gem/ruby 批 | cewl(wrapper,`ruby /opt/CeWL/cewl.rb`) | GIT_PIN 钉 sha | [digiNinja/CeWL](https://github.com/digiNinja/CeWL);不在 rubygems(实测搜索无此 gem),git 仓 + 依赖 gem(nokogiri/mime/mime-types/mini_exiftool/rubyzip,GEM_PIN 钉版) |
| evil-winrm | gem/ruby 批 | evil-winrm | GEM_PIN 4.1 | [Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm),ruby-china;见 [evil-winrm 册](evil-winrm.md) |
| CyberChef | Release 钉版 | 无 CLI(`/opt/cyberchef` 静态站点) | CYBERCHEF_VERSION v11.5.0 | [gchq/CyberChef](https://github.com/gchq/CyberChef);见 [CyberChef 册](cyberchef.md) |
| kubectl | 云与内网批 | kubectl | KUBECTL_VERSION v1.37.1 | dl.k8s.io 直连(国内无二进制镜像,实测阿里云/ustc/华为均无 release 布局) |
| trivy | 云与内网批 | trivy(wrapper 压 `/usr/bin` 真身) | TRIVY_VERSION v0.75.0 | [aquasecurity/trivy](https://github.com/aquasecurity/trivy);见 [trivy 册](trivy.md) |
| awscli v2 | 云与内网批 | aws | 软钉(AWSCLI_VERSION 空) | awscli.amazonaws.com 官方 zip 安装器(无国内镜像,直连不通可跳过) |

依赖备注:组头 `apt-get install --no-install-recommends samba-common-bin smbclient ldap-utils`(enum4linux-ng 运行依赖)与 `ruby-full ruby-dev`(gem 批原生件编译)是 noble 随源 apt 件,不计入上表 24 件。

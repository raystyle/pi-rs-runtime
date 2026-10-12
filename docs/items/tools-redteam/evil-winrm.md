# evil-winrm

> 交互式 WinRM shell(上传/下载/补全)｜ 状态:已装 ｜ 组:`install-tools.sh reversed`

- **版本钉**:pins.sh 钉版(`GEM_PIN[evil-winrm]`,当前钉值 4.1,解析日 2026-10-10),`gem install evil-winrm -v <钉>`(ruby-china 源);升级跑 scripts/resolve-pins.sh
- **来源与安装**:[Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm);`gem install evil-winrm --no-document`,gem 源已换 [gems.ruby-china.com](https://gems.ruby-china.com/)(`--remove rubygems.org`);ruby-full + ruby-dev 随 CeWL 批 apt noble 随源(winrm 依赖链带原生件,缺 ruby-dev 编译失败);[redteam 组册](redteam.md)
- **落点**:`/usr/local/bin/evil-winrm`(gem 二进位默认落点)
- **配置与缓存**:无件级配置;gem 下载缓存(`/var/lib/gems/*/cache`)由 clean-image.sh 清,`/root/.local/share/gem` 是 `--user-install` 安装根非缓存
- **离线行为**:未验 [推断:]纯 Ruby 本地运行,无自更新机制,断网可起 help 面;连目标 WinRM 需网络。验证:`ip link set eth0 down` 后 `evil-winrm --help` 退 0
- **限制**:幂等判据 `have evil-winrm` 早退,装后 `evil-winrm --version` 打印;定位补 netexec 的位(netexec 是跑命令不是交互壳,脚本注)

## rctl 面,机器行:catalog 投影声明,audit 豁免依据

- rctl: evil-winrm kind=tool path=/usr/local/bin/evil-winrm note=gem 主入口(gems.ruby-china)
- rctl: rwinrm kind=tool path=/usr/local/bin/rwinrm note=RubyGems 副件 shim(winrm gem 2.4.1)
- rctl: rwinrmcp kind=tool path=/usr/local/bin/rwinrmcp note=RubyGems 副件 shim(winrm-fs gem,远程文件拷贝)
- rctl: httpclient kind=tool path=/usr/local/bin/httpclient note=RubyGems 副件 shim(httpclient gem 2.9.0,evil-winrm 依赖)

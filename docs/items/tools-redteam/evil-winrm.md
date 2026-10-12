# evil-winrm

> 交互式 WinRM shell(上传/下载/补全) ｜ 状态:已装 ｜ 组:`install-tools.sh redteam`

## 版本

- `GEM_PIN[evil-winrm]` = 4.1(解析日 2026-10-10)。
- 安装命令是 `gem install evil-winrm -v <版本>`。
- gem 源是 [gems.ruby-china.com](https://gems.ruby-china.com/)。
- 升级:执行 `scripts/resolve-pins.sh`,再执行 redteam 组。

## 来源与安装

- 上游:[Hackplayers/evil-winrm](https://github.com/Hackplayers/evil-winrm)。
- 命令是 `gem install evil-winrm --no-document`。
- gem 源已执行 `--remove rubygems.org`。
- `ruby-full` 与 `ruby-dev` 随 CeWL 批从 noble 源安装。
- winrm 依赖链带原生扩展。
- 缺少 `ruby-dev` 时,原生扩展编译失败。
- 组册:[redteam.md](redteam.md)。

## 文件

- `/usr/local/bin/evil-winrm` 是 gem 二进制的默认安装路径。

## 配置

- 无件级配置。
- gem 下载缓存在 `/var/lib/gems/*/cache`。
- `clean-image.sh` 清除该缓存。
- `/root/.local/share/gem` 是 `--user-install` 的安装根,不是缓存。

## 离线行为

- 未验证。
- 这是纯 Ruby 程序,没有自更新。
- 关闭 eth0 后,`evil-winrm --help` 退 0,入口可用。
- 连接目标 WinRM 需要网络。

## 限制

- 幂等判据是 `have evil-winrm`,命中则早退。
- 安装完成后执行 `evil-winrm --version`。
- netexec 用来在目标上执行命令。
- evil-winrm 是交互壳,提供上传、下载与补全。

## 参见

- [redteam.md](redteam.md)
- [offline.md](../../offline.md)

## rctl 收录行

这些行是 catalog 投影声明,也是 audit 豁免依据。

- rctl: evil-winrm kind=tool path=/usr/local/bin/evil-winrm note=gem 主入口(gems.ruby-china)
- rctl: rwinrm kind=tool path=/usr/local/bin/rwinrm note=RubyGems 副件 shim(winrm gem 2.4.1)
- rctl: rwinrmcp kind=tool path=/usr/local/bin/rwinrmcp note=RubyGems 副件 shim(winrm-fs gem,远程文件拷贝)
- rctl: httpclient kind=tool path=/usr/local/bin/httpclient note=RubyGems 副件 shim(httpclient gem 2.9.0,evil-winrm 依赖)

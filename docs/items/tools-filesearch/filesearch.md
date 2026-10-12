# fd + ripgrep

> 文件查找(fd)与内容搜索(rg)双件,filesearch 组同批装 ｜ 状态:已装 ｜ 组:`install-tools.sh filesearch`

## 版本

- 版本随 Ubuntu noble 源,不单独锁定。
- apt 包是 `fd-find` 与 `ripgrep`。

## 来源与安装

- 上游:[sharkdp/fd](https://github.com/sharkdp/fd)。
- 上游:[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)。
- 两者都是 Ubuntu 打包。
- base 镜像的 apt 源是阿里云。源规定见 [params.md](../../params.md)。
- 脚本:`install-tools.sh` 的 `install_filesearch`。
- 安装命令是 `apt-get install -y --no-install-recommends fd-find ripgrep`。
- 装完后链出通用名。
- 组尾执行 `fd --version && rg --version`。

## 文件

- `/usr/bin/fdfind` 是 fd 的包内二进制。
- `/usr/bin/rg` 是 ripgrep。
- `/usr/local/bin/fd` 软链到 `fdfind`。
- Debian/Ubuntu 的包名 `fd` 已被 fdclone 占用,所以本包二进制叫 `fdfind`。
- 脚本把通用名 `fd` 链回来。

## 配置

- 无。
- 脚本不写配置,也不固化缓存。

## 离线行为

- 未验证。
- 两者都只读本地文件系统,没有网络面。
- 断网冒烟覆盖工具面。逐件名单未留档,本件没有单独记录。
- 关闭 eth0 后,判定命令是 `fd . /etc -d 1 >/dev/null && rg -q . /etc/hostname`,退 0。

## 限制

- 无。

## 参见

- [params.md](../../params.md)
- [offline.md](../../offline.md)

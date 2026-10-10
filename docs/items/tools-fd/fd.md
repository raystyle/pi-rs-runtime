# fd + ripgrep

> 文件查找(fd)与内容搜索(rg)双件,fd 组同批装 ｜ 状态:已装 ｜ 组:`install-tools.sh fd`

- **版本钉**:noble 随源(apt 包 `fd-find`、`ripgrep`,版本随 Ubuntu 源冻结,不另钉)
- **来源与安装**:[sharkdp/fd](https://github.com/sharkdp/fd)、[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)(Ubuntu 打包;base 镜像 apt 钉阿里云,源口径见 [docs/params.md](../../params.md));脚本面 `install_fd`:`apt-get install -y --no-install-recommends fd-find ripgrep` 后链名,尾跑 `fd --version && rg --version`
- **落点**:真身 `/usr/bin/fdfind`、`/usr/bin/rg`;`/usr/local/bin/fd` 软链到 fdfind(Debian/Ubuntu 把 `fd` 名让给 fdclone,包二进制才叫 fdfind,脚本链回通用名)
- **配置与缓存**:无(脚本不写配置、不固化缓存)
- **离线行为**:☐ [推断:]纯本地文件系统工具,无网络面;断网冒烟 78/0 覆盖工具面但逐件名单未留档,本件未单独实证。验证:`ip link set eth0 down` 后 `fd . /etc -d 1 >/dev/null && rg -q . /etc/hostname` 退 0
- **坑与留痕**:无

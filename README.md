# pi-rs-runtime

本仓是智能体渗透测试运行时系统（pi-rs-runtime）的环境维护仓，仓库地址为 [raystyle/pi-rs-runtime](https://github.com/raystyle/pi-rs-runtime)。输入是 Ubuntu 24.04（noble）与 `image-defs/ubuntu.yaml` 镜像定义；输出是 Incus 基础镜像 `ubuntu-24.04-base` 与发布别名 `pi-rs-runtime` 的运行时镜像；副作用包括：构建时删除同名旧镜像、在 `image-defs/` 下生成 `incus.tar.xz` 与 `rootfs.squashfs`、启动并删除临时验证容器、在容器内改写 apt 源与各类工具链配置。

## 前置条件

- 宿主需为已初始化的 Incus（`sudo incus admin init --auto` 即可）,`build-base-image.sh` 以 sudo 调用 `distrobuilder` 与 `incus`。
- `distrobuilder` 需从源码编译：Ubuntu 官方源无此包，官方只发布 Snap。需要 Go(Ubuntu 24.04 自带 `golang-go` 满足）与 `debootstrap rsync gpg squashfs-tools git make build-essential libwin-hivex-perl wimtools genisoimage`:

  ```bash
  git clone https://github.com/lxc/distrobuilder
  cd distrobuilder && make
  sudo install -m 755 "$HOME/go/bin/distrobuilder" /usr/local/bin/distrobuilder
  ```

- 容器内安装脚本（`scripts/install-*.sh`）以 root 在 Ubuntu 24.04 容器内运行，bash,`set -euo pipefail`，幂等可重跑。
- 网络：默认走清华 tuna 源与各生态国内镜像；Ghidra、vcpkg、rizin、zig 等从 GitHub 或官方直下，国内直连可能失败，可设 `GITHUB_MIRROR` 前置代理。
- 镜像源原则（`lib/common.sh` 注释）：有 tuna 走 tuna;tuna 没有的走该生态自己的国内镜像（golang 模块走 goproxy.cn,npm 走 npmmirror,sury 走南大镜像等）。

## 文档索引

操作步骤见下文「步骤」节；清单与参考分册在 `docs/`:

| 文档 | 内容 |
|------|------|
| [AGENTS.md](AGENTS.md) | 治理合同：命令、必须/禁止、先读清单、环境（agent 与人都先看它） |
| [docs/README.md](docs/README.md) | 文档地图 |
| [docs/items/](docs/items/README.md) | 逐件一册：每个安装/配置件的版本钉、落点、离线行为、坑（件级事实唯一真相，71 册） |
| [docs/install-surfaces/](docs/install-surfaces/) | 安装面组卡：四个分类脚本的组机制导览（逐件明细链 items） |
| [docs/software-inventory.md](docs/software-inventory.md) | 计数对账与形态分布（册数/件数，不记逐件事实） |
| [docs/adr/](docs/adr/README.md) | 不可逆裁定（ADR,6 篇 accepted) |
| [docs/diary/](docs/diary/) | 每轮构建/评审过程留痕（按日一篇） |
| [docs/offline.md](docs/offline.md) | 离线运行：固化缓存/wrapper/非登录 shell 兼容三层机制、五生态快失败、断网冒烟验证法 |
| [docs/params.md](docs/params.md) | 参数表：构建脚本变量、镜像源覆盖、版本钉、路径与工具集 |
| [docs/known-issues.md](docs/known-issues.md) | 已知限制与未决项（真限制；裁定类在 ADR) |
| [PROGRESS.md](PROGRESS.md) | 任务进度与历史轨迹（跨会话工作记忆，接续工作前先读） |

## 步骤

### 1. 准备宿主机构建环境

一次性执行：

1. 安装并初始化 Incus:`sudo apt install -y incus`，然后 `sudo incus admin init --auto`。
2. 按前置条件从源码编译并安装 `distrobuilder`。
3. （可选）把宿主 apt 源换成 tuna（deb822 格式，把 `URIs:` 改为 `https://mirrors.tuna.tsinghua.edu.cn/ubuntu/`），加快装包。

### 2. 构建基础镜像

```bash
./scripts/build-base-image.sh
```

等价于：

```bash
cd image-defs
sudo distrobuilder build-incus ubuntu.yaml \
  -o image.release=noble -o image.architecture=amd64 -o image.variant=cloud
sudo incus image import incus.tar.xz rootfs.squashfs --alias ubuntu-24.04-base
```

脚本随后启动临时容器 `verify-base`，等 cloud-init 完成后检查 apt 源、cloud-init 版本与 `apt-get update`，退出时自动删除该容器。

镜像事实（`image-defs/ubuntu.yaml`）：debootstrap 源与 `sources.list` 均指向 tuna（amd64 用 `/ubuntu`，arm 系用 `/ubuntu-ports`）；cloud 变体装 cloud-init；netplan DHCP；`ubuntu` 用户 `sudo NOPASSWD`；源是 deb822 格式，键为 `URIs:`；post-packages 动作改写 cloud-init 模板并写 `apt_preserve_sources_list: true`，使 tuna 源在 cloud-init 首启重写后仍生效。

症状：`debootstrap: You must specify a suite and a target`。原因：yaml 不写死套件，缺 `-o image.release=`。处理：显式传 `RELEASE`，或用脚本。

产物 `incus.tar.xz` 与 `rootfs.squashfs` 落在 `image-defs/` 下，不入 git。

### 3. 在容器内全量安装

```bash
incus launch ubuntu-24.04-base rt-build
incus file push scripts rt-build/root/ -r
incus exec rt-build -- bash /root/scripts/install-all.sh
```

`install-all.sh` 先装隐式依赖（`ca-certificates curl wget gpg unzip zip xz-utils file`），再按 编译器 → 运行时 → 库缓存 → 工具 顺序跑四个分类脚本，不转发过滤器；末尾自动跑 `clean-image.sh` 做镜像卫生（删可再生缓存与一次性残留，不碰 `/opt` 固化的离线缓存与 fnm node 多版本；可独立执行）。要装单项用分类脚本，例如 `./install-compilers.sh rust` 或 `./install-runtimes.sh python node`。


安装面事实（按代码逐条核对的「组|项目|版本|官方来源|安装命令」全表）见 [docs/install-surfaces/](docs/install-surfaces/)。

### 4. 发布 pi-rs-runtime 镜像

```bash
incus stop rt-build
incus publish rt-build --alias pi-rs-runtime
incus delete rt-build
```

发布别名固定为 `pi-rs-runtime`。发布后开实例：`incus launch pi-rs-runtime <名>`。

验收建议（重跑 `install-all.sh` 后）：核对版本输出、镜像配置落点、`/opt/analytics` 与 `/opt/re-venv` 的 venv 隔离、以及 `/usr/local/bin` 链接对 `ubuntu` 用户可执行。

### 5. 开发实例挂载仓库

`dev-instance.sh` 把仓库目录以 `shift=true` 挂进开发容器，改完在 Pi 里 `/reload` 生效，不走 `incus publish`:

```bash
./scripts/dev-instance.sh pi-dev /path/to/repo
```

等价于：

```bash
incus launch pi-box-dev pi-dev
incus config device add pi-dev src disk \
  source=/path/to/repo path=/home/ubuntu/workspace shift=true
incus exec pi-dev -- sudo -u ubuntu -i bash -lc 'cd /home/ubuntu/workspace && pi'
```

事实：实例不存在才创建；`src` 设备不存在才添加；镜像别名取 `PI_IMAGE`（默认 `pi-box-dev`，该镜像的构建不在本仓，见“已知限制与未决项”）；`shift=true` 需要容器开启 idmap；挂载的是宿主管的仓库，未提交改动不进任何镜像。

### 6. （可选）VNC 屏幕与浏览器面

容器内（ubuntu 用户）:

```bash
# 轻量面(挂单个 GUI 程序):Xvfb :99 + x11vnc 5900
vnc-screen setup && VNC_PASS='<口令>' vnc-screen start
# 桌面面(XFCE + TigerVNC + noVNC):浏览器经宿主回环 6080 进
VNC_PASS='<口令>' vnc-screen desktop   # 桌面栈已烘焙进镜像
# clean-chrome 冒烟面(起 :99 屏 + CDP 9222,实证到 Browser 版本号)
vnc-screen chrome
```

宿主侧一次性引端口（均只回环）:

```bash
sudo incus config device add <实例> vnc proxy \
  listen=tcp:127.0.0.1:5900 connect=tcp:127.0.0.1:5900
sudo incus config device add <实例> novnc proxy \
  listen=tcp:127.0.0.1:6080 connect=tcp:127.0.0.1:6080
# 浏览器开 http://127.0.0.1:6080/vnc.html
```

事实：轻量面 Xvfb 起 `:99`（1280x800x24）、x11vnc 只绑 `127.0.0.1:5900`；桌面面 TigerVNC :1(5901)+noVNC/websockify 只绑 `127.0.0.1:6080`;`start`/`desktop` 内置 `status` 校验；clean-chrome 155 在镜像内（`clean-chrome`/`chrome`/`chromium` 三链，恒 `--no-sandbox`),CDP 冒烟实证到 `Chrome/155.0.8059.39`；无 `VNC_PASS` 时生成随机口令并打印一次。件级细节见 [docs/items/tools-vnc/vnc.md](docs/items/tools-vnc/vnc.md) 与 [docs/items/tools-chrome/clean-chrome.md](docs/items/tools-chrome/clean-chrome.md)。

## 已知限制与未决项

见 [docs/known-issues.md](docs/known-issues.md)。

本仓只维护 yaml、脚本与文档；镜像产物不入库；distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`，失败后可手动清理。

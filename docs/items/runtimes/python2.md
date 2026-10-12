# Python 2 运行时

> 源码编译的 CPython 2.7:跑老样本、2.x 语法的逆向/exploit 脚本 ｜ 状态:已装 ｜ 组:`install-runtimes.sh python2`

## 版本

- `PY2_VERSION=2.7.18`(`lib/common.sh`)。这是 2.7 线的最终版。
- 源码包经 `PY2_MIRROR` 直拉。默认 `https://mirrors.huaweicloud.com/python`。
- 未做校验和。

## 来源与安装

- 来源:[python.org 2.7.18](https://www.python.org/downloads/release/python-2718/) 源码包。
- noble 官方源已无 python2。
- 脚本:`scripts/install-runtimes.sh` 的 `install_python2`,源码编译。
- 先用 apt 安装构建依赖:libssl-dev、zlib1g-dev、libbz2-dev、libreadline-dev、libsqlite3-dev、libncursesw5-dev、xz-utils、libffi-dev。
- 然后执行 `./configure --prefix=/usr/local --enable-shared && make -j$(nproc) && make altinstall && ldconfig`。
- 最后软链 `python2`。

## 文件

- `/usr/local/bin/python2.7` 是被包装的程序。`altinstall` 不抢占无版本名的 `python`。
- `/usr/local/bin/python2` 软链指向它。
- 共享库 `libpython2.7.so.1.0` 落在 `/usr/local/lib`,经 ldconfig 注册。这来自 `--enable-shared`。
- 库目录是 `/usr/local/lib/python2.7`。

## 配置

- 脚本不写任何配置文件;`/etc/pip.conf` 是 python3 与 pip3 的面。python2 未装 pip。

## 离线行为

- 未验证:断网跑脚本。解释器在本地,跑脚本不访问网络。断网冒烟未单独覆盖。
- 构建期已测得 `import ssl` 可用。记录见 [known-issues.md](../../known-issues.md)。
- 判定:关闭 eth0 后执行 `python2 -c 'import ssl, zlib, bz2, sqlite3'`,期望退出码 0。

## 限制

- 这是 EOL 运行时,与 PHP 7.4 同类,没有官方支持;样本动态执行只在无网络、无生产数据挂载的隔离环境进行。
- 当前部署链未强制该隔离面。见 [known-issues.md](../../known-issues.md)。
- EOL 运行时保留在镜像上。这一组是 python2、PHP 7.4、PHP 8.1、JDK 11、Node 18、Node 20。见 [known-issues.md](../../known-issues.md)。

## 参见

- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: python2.7 kind=runtime path=/usr/local/bin/python2.7 note=python2 入口
- rctl: python2.7-config kind=runtime path=/usr/local/bin/python2.7-config

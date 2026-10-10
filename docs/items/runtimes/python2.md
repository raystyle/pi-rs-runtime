# Python 2 运行时

> 源码编译的 CPython 2.7:跑老样本、2.x 语法的逆向/exploit 脚本 ｜ 状态:已装 ｜ 组:`install-runtimes.sh python2`

- **版本钉**:`PY2_VERSION=2.7.18`(lib/common.sh;2.7 线最终版);源码包经 `PY2_MIRROR`(默认 `https://mirrors.huaweicloud.com/python`)直拉,未做校验和
- **来源与安装**:[python.org 2.7.18](https://www.python.org/downloads/release/python-2718/) 源码包;noble 官方源已无 python2,`scripts/install-runtimes.sh` `install_python2()` 源码编译:先 apt 装构建依赖(libssl-dev、zlib1g-dev、libbz2-dev、libreadline-dev、libsqlite3-dev、libncursesw5-dev、xz-utils、libffi-dev),再 `./configure --prefix=/usr/local --enable-shared && make -j$(nproc) && make altinstall && ldconfig`,最后软链 `python2`
- **落点**:`/usr/local/bin/python2.7` 真身(`altinstall`,不抢 `python` 无版本名);`/usr/local/bin/python2` 软链;共享库 `libpython2.7.so.1.0` 落 `/usr/local/lib` 经 ldconfig 注册(`--enable-shared`);库目录 `/usr/local/lib/python2.7`
- **配置与缓存**:无(脚本不写任何配置文件;`/etc/pip.conf` 是 python3/pip3 的面,python2 未装 pip)
- **离线行为**:☐ [推断:纯本地解释器,断网跑脚本不触网;断网冒烟未专项覆盖];构建期已实测 `import ssl` 可用(known-issues 留痕)。验证:`ip link set eth0 down` 后 `python2 -c 'import ssl, zlib, bz2, sqlite3'` 退 0
- **坑与留痕**:EOL 运行时,与 PHP 7.4 同类:无官方支持,样本动态执行只在无网络、无生产数据挂载的隔离环境跑,当前部署链未强制该隔离面(见 [known-issues](../../known-issues.md));用户裁定 EOL 运行时全保留(python2、PHP 7.4/8.1、JDK 11、Node 18/20,known-issues 留痕)

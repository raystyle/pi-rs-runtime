# PHP(多版本 sury + VLD)

> webshell 逆向运行时:7.4 复现老样本、8.x 对照现代样本,VLD dump opcode ｜ 状态:已装 ｜ 组:`install-runtimes.sh php`

- **版本钉**:`PHP_VERSIONS="7.4 8.1 8.3"`(`scripts/lib/common.sh`,env 可覆盖);小版本随 sury 源——apt 源冻结即钉(软钉,留痕 [known-issues](../../known-issues.md));VLD 走 `pecl install vld-beta` 未钉(pins.sh 未收钉位;脚本提示对齐公开数据集以 PHP 8.0 + VLD 0.18.0 最稳)
- **来源与安装**:[php.net](https://www.php.net) 官方不发 deb,用 Ondřej Surý 第三方打包:GPG key 从官方 `packages.sury.org/php/apt.gpg` 取一次落 `/usr/share/keyrings/sury-php.gpg`,仓库指 `$SURY_MIRROR`(默认南大 `mirror.nju.edu.cn/sury`,tuna 无 sury);逐版本 `apt-get install php${v}-cli php${v}-dev`(失败只 echo 跳过),`php-pear` 走 noble apt 源;VLD 逐版本 `yes '' | pecl -q -d php_suffix=${v} install vld-beta` 编译,`phpenmod -v ${v} vld` 启用(`scripts/install-runtimes.sh` `install_php`)
- **落点**:`/usr/bin/php7.4`、`/usr/bin/php8.1`、`/usr/bin/php8.3`(apt 真身,全路径切换;无 `/usr/local/bin` 入口);VLD 为各版本扩展 so,ini 落 `/etc/php/<v>/mods-available/vld.ini`
- **配置与缓存**:`/etc/apt/sources.list.d/sury-php.list` + sury keyring(见上);VLD 启用由 phpenmod 管(已加载判据 `php${v} -m | grep -qi '^vld$'`);无缓存固化
- **离线行为**:☐ [推断:]CLI 解释器纯本地,`php<v> -d vld.active=1 <样本>` dump opcode 不触网;pecl 新装/升级扩展离线不可用(属预期,同 apt 边界,见 [offline.md](../../offline.md));断网冒烟未单独覆盖本件。验证:`ip link set eth0 down` 后 `php8.3 -v` 与 `php7.4 -m | grep -i vld`
- **坑与留痕**:7.4/8.1 已 EOL,只放隔离机跑样本——EOL 运行时全保留是用户裁定([ADR-0006](../../adr/ADR-0006-user-rulings-log.md));动态执行前必须 `-d opcache.jit=off`(否则 VLD 与单步行为偏),且部署链未强制隔离面([known-issues](../../known-issues.md));不要用 2021-03 被植入后门的 8.1.0-dev 快照当分析运行时;VLD 在 PHP 8.0 工具链最稳、8.1+ 常需自行编译,而 PHP_VERSIONS 不含 8.0——pecl 编译失败时按脚本提示手动 phpize 编 VLD 0.18.0;静态先过 php-malware-finder(YARA)是脚本提示,镜像未装该件

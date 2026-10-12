# PHP:多版本 sury + VLD

> webshell 逆向运行时:7.4 复现老样本、8.x 对照现代样本,VLD dump opcode ｜ 状态:已装 ｜ 组:`install-runtimes.sh php`

## 版本

- `PHP_VERSIONS="7.4 8.1 8.3"`(`scripts/lib/common.sh`,环境变量可覆盖)。
- 小版本随 sury 源。apt 源冻结即钉,属软钉。见 [known-issues.md](../../known-issues.md)。
- VLD 走 `pecl install vld-beta`,未钉版。pins.sh 未收该钉位。
- 脚本提示:对齐公开数据集时,PHP 8.0 加 VLD 0.18.0 最稳。

## 来源与安装

- [php.net](https://www.php.net) 官方不发 deb。用 Ondřej Surý 的第三方打包。
- GPG key 从官方 `packages.sury.org/php/apt.gpg` 取一次,落到 `/usr/share/keyrings/sury-php.gpg`。
- 仓库指向 `$SURY_MIRROR`。默认是南大 `mirror.nju.edu.cn/sury`。tuna 没有 sury。
- 逐版本执行 `apt-get install php${v}-cli php${v}-dev`。失败只打印信息并跳过。
- `php-pear` 走 noble apt 源。
- VLD 逐版本编译:`yes '' | pecl -q -d php_suffix=${v} install vld-beta`。
- 启用命令:`phpenmod -v ${v} vld`。
- 脚本:`scripts/install-runtimes.sh` 的 `install_php`。

## 文件

- `/usr/bin/php7.4`、`/usr/bin/php8.1`、`/usr/bin/php8.3` 是 apt 被包装的程序。切换靠全路径。
- 没有 `/usr/local/bin` 入口。
- VLD 是各版本的扩展 so。ini 落在 `/etc/php/<v>/mods-available/vld.ini`。

## 配置

- `/etc/apt/sources.list.d/sury-php.list` 与 sury keyring 见「来源与安装」。
- VLD 的启用由 phpenmod 管。已加载的判据是 `php${v} -m | grep -qi '^vld$'`。
- 无缓存固化。

## 离线行为

- 未验证:CLI 解释器与 VLD dump。解释器在本地。`php<v> -d vld.active=1 <样本>` dump opcode 不访问网络。断网冒烟未单独覆盖本件。
- 判定:关闭 eth0 后执行 `php8.3 -v`,以及 `php7.4 -m | grep -i vld`。
- 不支持:pecl 新装或升级扩展。这与 apt 的离线边界相同。见 [offline.md](../../offline.md)。

## 限制

- 7.4 与 8.1 已 EOL。样本只在隔离环境运行。
- 这类 EOL 运行时保留在镜像上。
- 动态执行前必须加 `-d opcache.jit=off`。否则 VLD 与单步行为会偏。
- 部署链未强制隔离面。见 [known-issues.md](../../known-issues.md)。
- 不要用 2021-03 被植入后门的 8.1.0-dev 快照当分析运行时。
- VLD 在 PHP 8.0 工具链最稳。8.1 及以上常常需要自行编译。
- `PHP_VERSIONS` 不含 8.0。pecl 编译失败时,按脚本提示手动 phpize,编 VLD 0.18.0。
- 静态先过 php-malware-finder(YARA) 是脚本提示。镜像未装该件。

## 参见

- [known-issues.md](../../known-issues.md)
- [offline.md](../../offline.md)
- [python2 册](python2.md)

# pspy

> 无 root 权限监听 Linux 进程与 cron 的刺探器｜ 状态:已装 ｜ 组:`install-tools.sh pd`(GO_PIN)

- **版本钉**:pins.sh `GO_PIN[github.com/DominicBreuker/pspy]`(实装产物 /opt/go/bin/pspy,链 /usr/local/bin)
- **来源与安装**:go install 钉版(pd 组循环);事实原写在 libcache/go 与 compilers/golang 两册,2026-10-11 一事实一册拆出,原处改链
- **落点**:`/opt/go/bin/pspy` 链 `/usr/local/bin/pspy`
- **配置与缓存**:单二进制零配置
- **离线行为**:过,纯本地(枚举 /proc 与 inotify)
- **坑与留痕**:privesc 信息收集面

- rctl: pspy kind=tool path=/usr/local/bin/pspy env=工具环境 note=无 root 进程刺探

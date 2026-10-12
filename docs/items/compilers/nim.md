# Nim 编译器

> OffensiveNim 等 maldev 模板的编译器(choosenim 官方安装器) ｜ 状态:已装 ｜ 组:`install-compilers.sh nim`

## 版本

- `NIM_VERSION=v2.2.12`(解析日 2026-10-10)。choosenim 按该锁定版本安装工具链。
- 升级:运行 `scripts/resolve-pins.sh`,再重跑本组。
- choosenim 本体经 init.sh 直下,未锁定版本。pins.sh 未收该锁定项。未写锁定版本回退 stable 频道。

## 来源与安装

- 来源:[nim-lang.org](https://nim-lang.org) 的 [choosenim](https://github.com/nim-lang/choosenim)。
- 安装命令:`curl -fsSL https://nim-lang.org/choosenim/init.sh | sh -s -- -y`。
- `CHOOSENIM_DIR=/opt/nim`。
- noble apt 的 nim 停在 1.6.x,过旧,不取。
- 脚本:`install-compilers.sh` 的 `install_nim`。

## 文件

- `/opt/nim` 是 choosenim 根,含 `bin/choosenim` 与 `toolchains/nim-<版本>/`。
- 最新工具链按 `sort -V` 取尾。其 `bin/*` 整批软链进 `/usr/local/bin`,包括 nim、nimble 等。
- nim 经 `/proc/self/exe` 定位 stdlib,软链安全。
- choosenim 本体不链出。登录 shell 经 profile.d 的 PATH 看见它。

## 配置

- `/etc/profile.d/nim.sh` 把 `/opt/nim/bin` 追加进 PATH。这是登录 shell 面。
- 无 per-user 配置。
- 无库缓存。libcache 八生态不含 nim。

## 离线行为

- 支持:关闭 eth0 后,`nim --version` 可读出版本。记录见 [offline.md](../../offline.md) 验证节。
- 未验证:本体编译。编译本身无网络依赖。判定:关闭 eth0 后执行 `echo 'echo "hi"' > /tmp/h.nim && nim c -r /tmp/h.nim`,期望退出码 0。
- 未验证:`nimble` 拉新包。无固化缓存。nim 不在五生态快失败默认面,断网即失败。

## 限制

- 整组装在 `! have nim` 守卫内,组尾以 `true` 兜底。
- choosenim 失败时(nim-lang.org 直连抖动)只打印信息,不阻塞流水线。
- 该次执行不完成安装。再次执行该组时安装。
- nim 已装后,重跑本组不补写 `/etc/profile.d/nim.sh`,也不补链。
- 配置写入放早退前的规则见 [golang 册](golang.md)。
- 非登录 shell(`incus exec`)读不到 `/opt/nim/bin`,choosenim 不可用。
- nim 本体经 `/usr/local/bin` 链出,不受该限制。

## 参见

- [offline.md](../../offline.md)
- [golang 册](golang.md)

## rctl 收录行

- rctl: nimble kind=compiler path=/usr/local/bin/nimble
- rctl: nimgrep kind=compiler path=/usr/local/bin/nimgrep
- rctl: nimpretty kind=compiler path=/usr/local/bin/nimpretty
- rctl: nimsuggest kind=compiler path=/usr/local/bin/nimsuggest
- rctl: nim-gdb kind=compiler path=/usr/local/bin/nim-gdb
- rctl: nim_dbg kind=compiler path=/usr/local/bin/nim_dbg
- rctl: testament kind=compiler path=/usr/local/bin/testament
- rctl: atlas kind=compiler path=/usr/local/bin/atlas note=Nim 包克隆器(工具链副件)

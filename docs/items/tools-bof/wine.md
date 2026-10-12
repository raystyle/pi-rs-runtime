# wine:PE 验证路径

> 在 Linux 下跑交叉编译出的 Windows PE,例如 COFFLoader64.exe ｜ 状态:已装 ｜ 组:`install-tools.sh bof`

## 版本

- 版本随 noble 源;版本是 wine 9.0。
- 安装命令是 `apt-get install -y --no-install-recommends mingw-w64 wine64 wine`。

## 来源与安装

- 来自 Ubuntu noble 源。源记录为 tuna。规定见 [params.md](../../params.md)。
- 脚本:`scripts/install-tools.sh` 的 `install_bof`;只开 64 位,不开 i386;wine 的依赖是 `wine64|wine32`;wine64 已经满足该依赖,所以不拉 wine32。

## 文件

- `/usr/bin/wine` 来自 wine 包。
- `/usr/local/bin/wine64` 是兜底软链,指向 `$(command -v wine)`。
- 脚本逻辑是 `have wine64 || { have wine && ln -sf … }`;幂等判据是 `have wine64`;wine loader 本体在 `/usr/lib/wine/`。

## 配置

- 脚本不写配置;首次运行 PE 时,就地创建 `~/.wine` prefix;该 prefix 的创建未验证。

## 离线行为

- 未验证:wine 运行原生 Windows PE。这是本地动作,不依赖网络,尚未单独断网测量;.NET PE 在缺少 mono 时会下载组件。那是在线动作;关闭 eth0 后,`wine64 --version` 退 0。

## 限制

- noble 的 wine64 包不提供 PATH 里的命令。`dpkg -L` 没有 `bin/`;`/usr/bin/wine` 在 wine 包里;只装 wine64 时,包已经安装,但是没有命令;`wine64` 这个命令名由 wine 包链出;脚本再兜底软链 `/usr/local/bin/wine64`;安装期 `wine64 --version` 失败只告警,不阻塞本组;那时 PE 验证路径本次不安装。再次执行该组时安装。

## 参见

- [bof.md](bof.md)
- [offline.md](../../offline.md)
- [params.md](../../params.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: wine64 kind=tool path=/usr/local/bin/wine64 note=wine 主入口

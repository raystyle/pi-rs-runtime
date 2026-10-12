# vnc:桌面与 Web 面

> XFCE 桌面 + TigerVNC + noVNC/websockify,浏览器经 incus proxy 进容器图形面;轻量 Xvfb+x11vnc 面并存 ｜ 状态:已装 ｜ 组:`install-tools.sh vnc`

## 版本

- apt noble 源冻结即锁定。成员:xfce4、xfce4-terminal、dbus-x11、tigervnc-standalone-server、tigervnc-common、novnc、websockify、fonts-noto-cjk。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_vnc`;桌面栈烘焙进镜像。
- 启动脚本装在公共位 `/usr/local/bin/vnc-screen`(/root/scripts 权限 0700,ubuntu 用户不可读)。

## 文件

| 路径 | 内容 |
| --- | --- |
| vncserver | TigerVNC 服务入口 |
| websockify | WebSocket 代理 |
| /usr/share/novnc/vnc.html | 浏览器客户端页 |
| $HOME/.vnc/passfile | 口令文件;首启随机生成,打印一次,不入库 |

## 配置

- 无镜像级配置;`~/.vnc/xstartup` 首启写入 startxfce4。

## 离线行为

- 支持:全部组件为本地件,断网可起。
- 验证:容器内执行 `VNC_PASS=<口令> vnc-screen desktop`,随后 `curl -sI http://127.0.0.1:6080/vnc.html` 返回 200;`ss -ltn` 仅见 127.0.0.1 监听。

## 限制

- websockify 与 VNC 都只绑回环。宿主访问经 proxy 设备引出:`incus config device add <实例> novnc proxy listen=tcp:127.0.0.1:6080 connect=tcp:127.0.0.1:6080`。
- 官方 Chrome 不随本组安装;桌面内浏览器件由 chrome 组显式安装。
- nuclei headless 模式因无 Chrome 不可用(见 [known-issues.md](../../known-issues.md))。
- 轻量面(Xvfb :99 + x11vnc 5900)与桌面面(:1 + 6080)并存,不互斥;`vnc-screen status` 两面同查。
- noble 的 tigervnc 拆分打包:口令工具 `vncpasswd` 在 `tigervnc-tools` 内,只装 server 与 common 时缺失,桌面启动会因交互要密码而卡死。
- TigerVNC 读 `~/.vnc/passwd`(`vncpasswd -f` 写入),x11vnc 读 `~/.vnc/passfile`(`-storepasswd` 写入);两个文件名各认各的,`need_pass` 两份都写。

## 参见

- [known-issues.md](../../known-issues.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: vnc-screen kind=tool path=/usr/local/bin/vnc-screen note=屏幕/VNC 起停面

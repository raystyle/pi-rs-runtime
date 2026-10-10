# vnc(桌面与 Web 面)

> XFCE 桌面 + TigerVNC + noVNC/websockify,浏览器经 incus proxy 进容器图形面;轻量 Xvfb+x11vnc 面并存 ｜ 状态:已装 ｜ 组:`install-tools.sh vnc`

- **版本钉**:apt noble 源冻结即钉(xfce4/xfce4-terminal/dbus-x11/tigervnc-standalone-server/tigervnc-common/novnc/websockify/fonts-noto-cjk,阿里云)
- **来源与安装**:`scripts/install-tools.sh install_vnc`;桌面栈烘焙进镜像;启动面脚本装公共位 `/usr/local/bin/vnc-screen`(/root/scripts 是 0700,ubuntu 够不着)
- **落点**:TigerVNC `vncserver`、websockify、`/usr/share/novnc/vnc.html`;口令文件 `$HOME/.vnc/passfile`(首启随机生成打印一次,不落库)
- **配置与缓存**:无镜像级配置;`~/.vnc/xstartup` 首启写 startxfce4
- **离线行为**:✅ 纯本地件,断网可起;验证:容器内 `VNC_PASS=<口令> vnc-screen desktop` 后 `curl -sI http://127.0.0.1:6080/vnc.html` 200 + `ss -ltn` 只见 127.0.0.1
- **坑与留痕**:websockify 与 VNC 都只绑回环(宿主经 proxy 设备引:`incus config device add <实例> novnc proxy listen=tcp:127.0.0.1:6080 connect=tcp:127.0.0.1:6080`);官方 Chrome 不装([ADR-0006](../../adr/ADR-0006-user-rulings-log.md)),桌面里浏览器件等定制 Chrome 合入;nuclei headless 同理不可用([known-issues](../../known-issues.md));轻量面(Xvfb :99+x11vnc 5900)与桌面面(:1+6080)并存不互斥,`vnc-screen status` 两面同查。**实证坑**:noble 的 tigervnc 拆分装,口令工具 `vncpasswd` 在 `tigervnc-tools`(只装 server+common 会缺,桌面起不来时它交互要密码卡死);TigerVNC 读 `~/.vnc/passwd`(vncpasswd -f 写),x11vnc 读 `~/.vnc/passfile`(-storepasswd),两个文件名各认各的,`need_pass` 两份都写

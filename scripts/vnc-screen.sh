#!/usr/bin/env bash
# pi 实例的虚拟屏幕 + VNC + 桌面/noVNC Web 面
# 两种形态:
#   轻量(默认):Xvfb :99 + x11vnc 127.0.0.1:5900(无桌面,适合挂单个 GUI 程序)
#   桌面:xfce4 桌面 TigerVNC :1(5901)+ noVNC/websockify 127.0.0.1:6080,浏览器进
# 用法(容器内,ubuntu 用户):
#   ./vnc-screen.sh setup           # 装轻量面(xvfb x11vnc x11-utils xterm)
#   ./vnc-screen.sh setup-desktop   # 装桌面面(xfce4 tigervnc novnc websockify;镜像已烘焙则秒过)
#   VNC_PASS=xxx ./vnc-screen.sh start          # 起轻量面
#   VNC_PASS=xxx ./vnc-screen.sh desktop        # 起桌面+noVNC
#   ./vnc-screen.sh status          # 校验屏幕与监听只绑回环
#   ./vnc-screen.sh stop            # 停轻量面;desktop-stop 停桌面面
# 宿主侧一次性(把端口引到宿主回环,不开公网):
#   轻量:sudo incus config device add <实例> vnc proxy listen=tcp:127.0.0.1:5900 connect=tcp:127.0.0.1:5900
#   桌面:sudo incus config device add <实例> novnc proxy listen=tcp:127.0.0.1:6080 connect=tcp:127.0.0.1:6080
#   浏览器开 http://127.0.0.1:6080/vnc.html
set -euo pipefail

RES="${VNC_RES:-1280x800x24}"
DISP="${VNC_DISPLAY:-:99}"
PORT="${VNC_PORT:-5900}"
# 桌面面参数
DESK_DISP="${VNC_DESK_DISPLAY:-:1}"
DESK_PORT="${VNC_DESK_PORT:-5901}"     # TigerVNC :1 对应 5901
WEB_PORT="${NOVNC_PORT:-6080}"
DESK_RES="${VNC_DESK_RES:-1280x720}"
VNC_PASS="${VNC_PASS:-}"
PASSFILE="$HOME/.vnc/passfile"

setup() {
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends xvfb x11vnc x11-utils xterm
}

setup-desktop() {
    # 新镜像已烘焙(install-tools.sh vnc 组),这里是老镜像增量补装面
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        xfce4 xfce4-terminal dbus-x11 \
        tigervnc-standalone-server tigervnc-common \
        novnc websockify fonts-noto-cjk
}

need_pass() {
    if [ -z "$VNC_PASS" ] && [ ! -f "$PASSFILE" ] && [ ! -f "$HOME/.vnc/passwd" ]; then
        VNC_PASS="$(head -c 12 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)"
        echo "未提供 VNC_PASS,已生成随机口令: $VNC_PASS"
    fi
    if [ -n "$VNC_PASS" ]; then
        mkdir -p "$HOME/.vnc"
        # 两套口令文件:x11vnc 读 passfile(-storepasswd),TigerVNC 读 passwd(vncpasswd -f)
        command -v x11vnc >/dev/null && x11vnc -storepasswd "$VNC_PASS" "$PASSFILE" >/dev/null 2>&1 || true
        command -v vncpasswd >/dev/null && vncpasswd -f <<<"$VNC_PASS" > "$HOME/.vnc/passwd"
        chmod 600 "$PASSFILE" "$HOME/.vnc/passwd" 2>/dev/null || true
    fi
}

start() {
    need_pass
    if xdpyinfo -display "$DISP" >/dev/null 2>&1; then
        echo "$DISP 已在跑"
    else
        Xvfb "$DISP" -screen 0 "$RES" -ac +extension RANDR >/tmp/xvfb.log 2>&1 &
        for _ in $(seq 1 20); do xdpyinfo -display "$DISP" >/dev/null 2>&1 && break; sleep 0.3; done
    fi
    xterm -display "$DISP" >/dev/null 2>&1 &   # 画面确认用
    if ! ss -ltn | grep -q "127.0.0.1:$PORT"; then
        x11vnc -display "$DISP" -localhost -rfbport "$PORT" -forever -shared \
            -passwdfile "$PASSFILE" >/tmp/x11vnc.log 2>&1 &
        sleep 1
    fi
    status
}

desktop() {
    need_pass
    # TigerVNC 读 ~/.vnc/xstartup;xfce4 会话
    cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
    chmod +x "$HOME/.vnc/xstartup"
    if ! xdpyinfo -display "$DESK_DISP" >/dev/null 2>&1; then
        vncserver "$DESK_DISP" -geometry "$DESK_RES" -depth 24 -localhost yes >/tmp/vncserver.log 2>&1
        sleep 1
    else
        echo "$DESK_DISP 已在跑"
    fi
    # noVNC/websockify:Web 面绑回环,宿主经 proxy 设备进
    if ! ss -ltn | grep -q "127.0.0.1:$WEB_PORT"; then
        websockify --web=/usr/share/novnc/ "127.0.0.1:$WEB_PORT" "127.0.0.1:$DESK_PORT" >/tmp/websockify.log 2>&1 &
        sleep 1
    fi
    status
}

stop() {
    pkill -f "x11vnc -display $DISP" 2>/dev/null || true
    pkill -f "Xvfb $DISP" 2>/dev/null || true
    pkill -f "xterm -display $DISP" 2>/dev/null || true
    echo stopped
}

desktop-stop() {
    vncserver -kill "$DESK_DISP" >/dev/null 2>&1 || true
    pkill -f "websockify.*$WEB_PORT" 2>/dev/null || true
    echo stopped
}

status() {
    local ok=1
    if xdpyinfo -display "$DISP" 2>/dev/null | grep -q dimensions; then
        echo "轻量屏: $(xdpyinfo -display "$DISP" | grep dimensions | awk '{print $2}') @ $DISP"
    else
        echo "轻量屏: $DISP 未起"
    fi
    ss -ltn | grep -q "127.0.0.1:$PORT" && echo "轻量 VNC: 127.0.0.1:$PORT(仅回环)"
    if xdpyinfo -display "$DESK_DISP" >/dev/null 2>&1; then
        echo "桌面屏: $DESK_DISP 在跑"
        ss -ltn | grep -q "127.0.0.1:$WEB_PORT" && echo "noVNC:  127.0.0.1:$WEB_PORT(仅回环,宿主 proxy 引 6080)" || { echo "noVNC: $WEB_PORT 未监听"; ok=0; }
    fi
    ss -ltn | grep -E ":$PORT |:$WEB_PORT " | grep -v "127.0.0.1" && { echo "!! 有端口绑在非回环地址"; ok=0; } || true
    [ "$ok" = 1 ] && echo OK || { echo "查 /tmp/xvfb.log /tmp/x11vnc.log /tmp/vncserver.log /tmp/websockify.log"; exit 1; }
}

case "${1:-}" in
    setup)         setup ;;
    setup-desktop) setup-desktop ;;
    start)         start ;;
    desktop)       desktop ;;
    stop)          stop ;;
    desktop-stop)  desktop-stop ;;
    status)        status ;;
    *) grep '^#' "$0" | head -16; exit 1 ;;
esac

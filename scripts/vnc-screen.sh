#!/usr/bin/env bash
# pi 实例的虚拟屏幕 + VNC(无 Chrome / noVNC)
# Xvfb 负责 :99,x11vnc 把屏幕变成 127.0.0.1:5900;宿主经 incus proxy 访问
# 用法(容器内,ubuntu 用户):
#   ./vnc-screen.sh setup          # 装 xvfb x11vnc x11-utils xterm
#   VNC_PASS=xxx ./vnc-screen.sh start   # 起 Xvfb + x11vnc(xterm 仅作画面确认)
#   ./vnc-screen.sh status         # 校验 1280x800 与 5900 只绑 127.0.0.1
#   ./vnc-screen.sh stop
# 宿主侧一次性(把 5900 引到宿主回环,不开公网):
#   sudo incus config device add <实例> vnc proxy \
#     listen=tcp:127.0.0.1:5900 connect=tcp:127.0.0.1:5900
set -euo pipefail

RES="${VNC_RES:-1280x800x24}"
DISP="${VNC_DISPLAY:-:99}"
PORT="${VNC_PORT:-5900}"
VNC_PASS="${VNC_PASS:-}"
PASSFILE="$HOME/.vnc/passfile"

setup() {
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends xvfb x11vnc x11-utils xterm
}

need_pass() {
    if [ -z "$VNC_PASS" ] && [ ! -f "$PASSFILE" ]; then
        VNC_PASS="$(head -c 12 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)"
        echo "未提供 VNC_PASS,已生成随机口令: $VNC_PASS"
    fi
    if [ -n "$VNC_PASS" ]; then
        mkdir -p "$HOME/.vnc"
        x11vnc -storepasswd "$VNC_PASS" "$PASSFILE" >/dev/null
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

stop() {
    pkill -f "x11vnc -display $DISP" 2>/dev/null || true
    pkill -f "Xvfb $DISP" 2>/dev/null || true
    pkill -f "xterm -display $DISP" 2>/dev/null || true
    echo stopped
}

status() {
    local ok=1
    if xdpyinfo -display "$DISP" 2>/dev/null | grep -q dimensions; then
        echo "屏幕:   $(xdpyinfo -display "$DISP" | grep dimensions | awk '{print $2}') @ $DISP"
    else
        echo "屏幕:   $DISP 未起"; ok=0
    fi
    if ss -ltn | grep -q "127.0.0.1:$PORT"; then
        echo "VNC:    127.0.0.1:$PORT (仅回环)"
    elif ss -ltn | grep -q ":$PORT"; then
        echo "VNC:    !! $PORT 绑在非回环地址"; ok=0
    else
        echo "VNC:    $PORT 未监听"; ok=0
    fi
    [ "$ok" = 1 ] && echo OK || { echo "查 /tmp/xvfb.log /tmp/x11vnc.log"; exit 1; }
}

case "${1:-}" in
    setup)  setup ;;
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    *) grep '^#' "$0" | head -12; exit 1 ;;
esac

#!/usr/bin/env bash
# pi 开发实例:把仓库挂进容器开发,改完 Pi 里 /reload,不走 incus publish
# 用法: ./dev-instance.sh [实例名] [仓库路径]   默认 pi-dev / 当前目录
set -euo pipefail

NAME="${1:-pi-dev}"
REPO="$(cd "${2:-$PWD}" && pwd)"
IMAGE="${PI_IMAGE:-pi-box-dev}"

if ! incus info "$NAME" >/dev/null 2>&1; then
    incus launch "$IMAGE" "$NAME"
fi
if ! incus config device show "$NAME" | grep -q '^src:'; then
    incus config device add "$NAME" src disk \
        source="$REPO" path=/home/ubuntu/workspace shift=true
fi
incus start "$NAME" 2>/dev/null || true

cat <<EOF
开发实例就绪:
  进入:  incus exec $NAME -- sudo -u ubuntu -i bash -lc 'cd /home/ubuntu/workspace && pi'
  重载:  Pi 里 /reload(改 .pi/extensions、.pi/skills、.pi/prompts 后立即生效)
  停止:  incus stop $NAME   删除: incus delete $NAME
注意: shift=true 需要容器开启 idmap(见 README);挂载的是宿主管的仓库,
      未提交改动不会进任何镜像;发布走 build.sh,不挂开发目录。
EOF

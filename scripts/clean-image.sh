#!/usr/bin/env bash
# 镜像卫生清理:删可再生缓存与一次性残留,压镜像体积。
# 不碰 /opt 下有意固化的离线缓存(go pkg/mod、cargo registry、wheelhouse、js-lab、
# nuget-packages、trivy-db、SecLists、frida-server、vcpkg installed)与 fnm 的 node 多版本。
# 幂等,可重复执行;install-all.sh 末尾自动调用,也可独立跑:
#   ./clean-image.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

log "apt 缓存(脚本各组自带 apt-get update,lists 可再拉)"
apt-get clean
rm -rf /var/lib/apt/lists/*

log "构建期可再生缓存(实测约 15 GB:go-build/uv/npm/pip/ccache/zig/vcpkg 下载/NuGet http-cache/gem)"
rm -rf /root/.cache/go-build /root/.cache/uv /root/.cache/pip \
       /root/.cache/ccache /root/.cache/zig /root/.cache/vcpkg
rm -rf /root/.npm/_cacache
rm -rf /root/.local/share/NuGet/http-cache
rm -rf /var/lib/gems/*/cache/* /root/.local/share/gem
# ubuntu 用户同形(量小,顺手)
rm -rf /home/ubuntu/.cache/go-build /home/ubuntu/.cache/uv /home/ubuntu/.cache/pip \
       /home/ubuntu/.cache/ccache /home/ubuntu/.npm/_cacache 2>/dev/null || true

log "一次性残留(nuclei 模板迁移备份/msf 首跑目录/nimble 缓存/crash)"
rm -rf /root/nuclei-templates.bak /home/ubuntu/nuclei-templates.bak
rm -rf /root/.msf4 /root/.nimble /var/crash/* 2>/dev/null || true

log "日志与临时文件(journal 真空到 16M,*.log 截断, histories 清除)"
journalctl --vacuum-size=16M >/dev/null 2>&1 || true
find /var/log -type f -name '*.log' -exec truncate -s 0 {} + 2>/dev/null || true
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
rm -f /root/.bash_history /home/ubuntu/.bash_history

log "清理完成"
df -h / | tail -1

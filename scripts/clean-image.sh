#!/usr/bin/env bash
# 镜像卫生清理:删可再生缓存与一次性残留,压镜像体积。
# 不碰 /opt 下有意固化的离线缓存(cargo registry 的 cache/git、wheelhouse、js-lab、
# nuget-packages、trivy-db、SecLists、frida-server、vcpkg installed、zig-cache/zig-pkg)
# 与 fnm 的 node 多版本;go pkg/mod 与 cargo registry/src 按用户裁定 2026-10-14 转删
# (口径:保留运行时与编程环境,删构建缓存——装好的二进制不受影响,离线「新装」go 工具
# 需在线一次,cargo 离线编译靠 registry/cache 的 .crate 原件不受影响)。
# 幂等,可重复执行;install-all.sh 末尾自动调用,也可独立跑:
#   ./clean-image.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

log "apt 缓存(构建期各组自带 apt-get update 可再拉;成品镜像离线,apt install 新件不可用属预期快失败)"
apt-get clean
rm -rf /var/lib/apt/lists/*

log "go 模块缓存(用户裁定 2026-10-14 转删;装好的 go 工具二进制在 /opt/go/bin 与 /usr/local/bin 不受影响)"
rm -rf /opt/go/pkg/mod /opt/go/pkg/sumdb

log "cargo 解包源(registry/cache 的 .crate 原件在,离线编译可再解;pi 闭包不受影响)"
rm -rf /opt/cargo/registry/src

log "构建中间树(zg 源仓 target/vcpkg buildtrees;产物已装)"
rm -rf /opt/zvec-grep-src/rust/target
rm -rf /opt/vcpkg/buildtrees

log "构建期可再生缓存(go-build/rust-script/ort/uv/npm/pip/ccache/vcpkg 下载/NuGet http-cache/gem)"
rm -rf /root/.cache/go-build /root/.cache/uv /root/.cache/pip \
       /root/.cache/ccache /root/.cache/vcpkg \
       /root/.cache/rust-script /root/.cache/ort.pyke.io
# zig 默认缓存位可能是指向 /opt/zig-cache 的固化软链(install-libcache zig 组建):软链留下,只清真目录
[ -L /root/.cache/zig ] || rm -rf /root/.cache/zig
rm -rf /root/.npm/_cacache
rm -rf /root/.local/share/NuGet/http-cache
# gem 的 cache/* 是 .gem 下载缓存;/root/.local/share/gem 是 --user-install 安装根(非缓存,grok 评审),不删
rm -rf /var/lib/gems/*/cache/*
# ubuntu 用户同形(量小,顺手)
rm -rf /home/ubuntu/.cache/go-build /home/ubuntu/.cache/uv /home/ubuntu/.cache/pip \
       /home/ubuntu/.cache/ccache /home/ubuntu/.npm/_cacache 2>/dev/null || true

log "裁定不烤面(2026-10-14:trivy-db/SecLists/C2 参考仓/BOF 参考树/ref 仓非功能子面;exploitdb 与 PoC 索引是 poc-search 依赖保留)"
rm -rf /opt/trivy-db /opt/SecLists /opt/c2dev-ref /opt/tradecraft-ref /opt/payload-ref \
       /opt/data-ref/LOLBAS /opt/data-ref/webappanalyzer /opt/data-ref/gtfobins /opt/data-ref/hacktricks \
       /opt/recon-ref/hickory-dns /opt/recon-ref/mac-tracker /opt/recon-ref/recog
# trivy wrapper/profile 若是旧道产物(指向已删 db),还原真身直通
[ -L /usr/local/bin/trivy ] || rm -f /usr/local/bin/trivy /etc/profile.d/trivy.sh

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

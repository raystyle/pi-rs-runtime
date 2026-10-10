#!/usr/bin/env bash
# 锁文件再生同步(phase B):从线上镜像起临时容器,LIBCACHE_RESOLVE=1 跑
# install-libcache.sh 各组解析态(忽略仓库锁,构建日重新解析),把再生的锁文件
# incus file pull 拉回 scripts/lock/<生态>/,用完删容器。
# 用法:
#   bash scripts/sync-locks.sh             # 六组全量(go rust node java dotnet zig)
#   bash scripts/sync-locks.sh go node     # 只同步指定组
# python/pwsh 无独立锁文件(pins.sh 钉直接依赖),不在同步面。
# 镜像用 LOCK_IMAGE 覆盖(默认 pi-rs-runtime 线上版);incus 需 sudo 或在 incus 组。
# 拉锁先落暂存再校验后入库:解析态失败的残缺文件不会覆盖仓库现存锁。
# 跑完审 git diff scripts/lock/,再按 AGENTS.md 增量发布链重跑受影响组。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LOCKS="$HERE/lock"
SYNCTMP="$LOCKS/.sync-tmp"
IMAGE="${LOCK_IMAGE:-pi-rs-runtime}"
BOX="rt-locksync"
SYNCABLE=(go rust node java dotnet zig)

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=("${SYNCABLE[@]}")
for t in "${targets[@]}"; do
    case " ${SYNCABLE[*]} " in
        *" $t "*) ;;
        *) echo "未知组: $t(可选: ${SYNCABLE[*]})"; exit 1 ;;
    esac
done

command -v incus >/dev/null 2>&1 || { echo "!! 需要 incus"; exit 1; }
# 幂等:残留同名容器(只可能是本脚本以前起的)先删
incus info "$BOX" >/dev/null 2>&1 && incus delete "$BOX" --force
rm -rf "$SYNCTMP"
trap 'incus delete "$BOX" --force 2>/dev/null || true; rm -rf "$SYNCTMP"' EXIT

echo "==> 起临时容器 $BOX(镜像 $IMAGE,launch 解包约 3.5 分钟)"
incus launch "$IMAGE" "$BOX"
# agent 起来不代表 DNS 就绪(实证:launch 后立刻解析 goproxy.cn 走 [::1]:53 拒)
ready=""
for _ in $(seq 1 45); do
    incus exec "$BOX" -- getent hosts goproxy.cn >/dev/null 2>&1 && { ready=1; break; }
    sleep 2
done
[ -n "$ready" ] || { echo "!! 容器 DNS 90s 未就绪(宿主 DNS 复发整挂?按 AGENTS.md: sudo resolvectl dns wlo1 223.5.5.5 223.6.6.6)"; exit 1; }

echo "==> 推送仓库 scripts 进容器并 grep 核验落地"
incus file push "$HERE" "$BOX/root/" -r
incus exec "$BOX" -- grep -q "LIBCACHE_RESOLVE" /root/scripts/install-libcache.sh \
    || { echo "!! scripts 推送未落地(缺 LIBCACHE_RESOLVE 标记)"; exit 1; }

echo "==> 解析态重跑: LIBCACHE_RESOLVE=1 install-libcache.sh ${targets[*]}"
incus exec "$BOX" -- env LIBCACHE_RESOLVE=1 bash /root/scripts/install-libcache.sh "${targets[@]}"

pull() { # pull <组> <容器内绝对路径> <内容校验 grep 模式>
    install -d "$SYNCTMP/$1" "$LOCKS/$1"
    local f="$SYNCTMP/$1/$(basename "$2")"
    if incus file pull "$BOX$2" "$SYNCTMP/$1/" && [ -s "$f" ] && grep -q "$3" "$f"; then
        mv "$f" "$LOCKS/$1/"
        echo "锁已回收: scripts/lock/$1/$(basename "$2")"
    else
        echo "!! 拉取或校验失败: $BOX$2(解析态未产出有效锁;仓库现存锁未动)"
        exit 1
    fi
}
for t in "${targets[@]}"; do
    case "$t" in
        go)     pull go /opt/go-prewarm/go.mod '^require'
                pull go /opt/go-prewarm/go.sum ' h1:' ;;
        rust)   pull rust /opt/rust-prewarm-libs/Cargo.toml '^\[dependencies\]'
                pull rust /opt/rust-prewarm-libs/Cargo.lock '^\[\[package\]\]' ;;
        node)   pull node /opt/js-lab/package-lock.json '"lockfileVersion"' ;;
        java)   pull java /opt/maven-prewarm/pom.xml '<project' ;;
        dotnet) # incus file pull -r 总是落 目的/<源目录名>/ 一层,用 find 兜底目录名变化
                if incus file pull -r "$BOX/opt/dotnet-prewarm" "$SYNCTMP/dotnet"; then
                    staged=$(find "$SYNCTMP/dotnet" -maxdepth 2 -name '*.csproj' -print -quit)
                    if [ -n "$staged" ] && grep -q "<Project" "$staged"; then
                        install -d "$LOCKS/dotnet"
                        mv "$staged" "$LOCKS/dotnet/"
                        echo "锁已回收: scripts/lock/dotnet/$(basename "$staged")"
                    else
                        echo "!! csproj 拉取或校验失败(仓库现存锁未动)"; exit 1
                    fi
                else
                    echo "!! 拉取失败: $BOX/opt/dotnet-prewarm(仓库现存锁未动)"; exit 1
                fi ;;
        zig)    pull zig /opt/zig-prewarm/build.zig.zon '\.dependencies' ;;
    esac
done

echo "==> 完成(容器 $BOX 与暂存随 trap 清理)。锁 diff:"
git -C "$HERE/.." status --short -- scripts/lock 2>/dev/null || true

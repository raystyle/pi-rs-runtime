# ADR-0005 共享可写缓存:piopt 组 + 默认 ACL

状态:accepted(2026-10-10,grok F1 实证)｜ 关联:items/libcache/zig、items/runtimes/sdkman、scripts/lib/common.sh shared_writable_cache

## Context

家目录软链把 zig/gradle/cargo-zigbuild 缓存指到 /opt 后,root 的 755 目录让 ubuntu 编译直接 AccessDenied(zig 要写 z/ 编译产物,gradle 要写 daemon/锁)。但不能 1777:缓存按 hash 寻址,任意用户可写就能换掉 root 下次构建要用的缓存。实证 setgid 单独压不住 umask 022(zig 自建子目录 drwxr-sr-x,组无写位)。

## Decision

`shared_writable_cache()`(scripts/lib/common.sh):共同组 `piopt`(root+ubuntu)+ chgrp -R + g+rwX + 目录 setgid + **默认 ACL**(`setfacl -R -m g:piopt:rwX` + `-d` 默认 ACL,压 umask 的是 -d 这条)。setfacl 缺失(acl 包未装)直接 return 1 失败响,不静默降级。只读消费面(node lib/node、psmodules、nuget fallback)保持 755 不共享写。

## Consequences

- root/ubuntu 双视角编译实证通过;跨用户删缓存项无 sticky 阻碍(终审实证 sticky 0 命中)
- acl 包进 install-all.sh 前置批,是硬依赖
- 新增「可写共享缓存」一律走这个函数,不自创权限配方

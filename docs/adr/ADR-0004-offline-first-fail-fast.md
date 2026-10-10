# ADR-0004 纯离线默认:固化缓存 + wrapper 注入 + 五生态快失败

状态:accepted(2026-10-10,纯离线轮三轮实证)｜ 关联:docs/offline.md(机制全表)

## Context

镜像定位第一条是「建成后无外网可干活」,但断网实证(rt-offline,eth0 down)发现:非登录 shell(incus exec,agent 主通道)不读 /etc/profile.d 也不读 /etc/environment,离线必需的 env(NUGET_PACKAGES/GRADLE_USER_HOME/ZIG_GLOBAL_CACHE_DIR/NODE_PATH/PSModulePath)全失效;zig 固化是空壳;trivy alias 不生效;新依赖解析默认长超时挂起,半静默最伤现场。

## Decision

- 离线必需的环境一律用 shell 无关机制:per-user 配置(go env 文件 root+ubuntu、NuGet.Config fallbackPackageFolders)、默认路径软链(cargo/rustup/gradle/zig/cargo-zigbuild)、系统模块路径(pwsh)、Module.globalPaths(node lib/node)
- 运行期行为修正落 /usr/local/bin wrapper 文件(trivy/nuclei/capa/responder…),**不用 alias**(非交互不生效)
- 五生态默认快失败:go env GOPROXY=off、cargo [net] offline=true、npmrc offline=true+fetch-retries=0、uv.toml offline=true、pip.conf no-index+find-links=/opt/wheelhouse;构建脚本经 lib/common.sh 导出的 env 组拿回在线面(env 恒优先于配置文件;uv 用 UV_CONFIG_FILE 整面替换,实证 UV_OFFLINE=0 无效)
- 断网冒烟是发布门禁:PASS 全绿(仅断网确认项除外)才许 publish

## Consequences

- 运行期拉新件亚秒报错,错误信息直白
- 在线场景要拉新件需显式 env(文档给口径);maven/gradle 无干净覆盖对,不默认离线
- npm `--prefix` 会连 prefix 级 npmrc 一起丢(npm 天性,留痕);bun/corepack 不吃 npmrc,不钉默认

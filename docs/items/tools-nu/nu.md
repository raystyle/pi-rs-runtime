# nu(nushell)

> 结构化 Shell(数据按表流动的 shell 与脚本语言) ｜ 状态:已装 ｜ 组:`install-tools.sh nu`

- **版本钉**:release latest tag 经 `git ls-remote --tags` 取(过滤 `refs/tags/<semver>$`、三段数字排序取尾);不用 api.github.com——未认证限流 60 次/时,fresh 验证实证 403,git 协议不受限流影响;tarball 无校验和
- **来源与安装**:[nushell/nushell](https://github.com/nushell/nushell) release 预编译 tarball `nu-<tag>-<arch>-unknown-linux-gnu.tar.gz`(tag 无 v 前缀;arch 映射 amd64→x86_64、arm64→aarch64)经 `GITHUB_MIRROR` 直下,解包后 `install -m755` 落 `/usr/local/bin/nu`(`scripts/install-tools.sh install_nu`;[nushell.sh](https://www.nushell.sh))
- **落点**:`/usr/local/bin/nu` 单文件真身,无 wrapper
- **配置与缓存**:无(脚本不写配置、不固化缓存)
- **离线行为**:☐ [推断:]预编译单文件,运行不触网;断网冒烟未单列 nu。验证:`ip link set eth0 down` 后 `nu --version` 退 0
- **坑与留痕**:GitHub 直连间歇性归零(与 tuna 抖动同期),取 tag 重试 3 次(间隔 sleep 5);pipefail 下 ls-remote 失败整条管道非零、命令替换赋值即触发 set -e 退出,故 `|| true` 兜底;tag 取不到只 echo「下轮补」不退出(`have nu` 幂等早退,下轮重跑补装);api.github.com 403 与 pipefail 赋值坑的实证留痕 [docs/diary/2026-10-08](../../diary/2026-10-08-build-baseline.md)

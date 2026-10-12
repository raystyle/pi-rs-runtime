# nu:nushell

> 结构化 Shell:数据按表流动的 shell 与脚本语言 ｜ 状态:已装 ｜ 组:`install-tools.sh nu`

## 版本

- release latest tag 经 `git ls-remote --tags` 取:过滤 `refs/tags/<semver>$`,三段数字排序取尾。
- 不用 api.github.com:未认证限流 60 次/时,fresh 验证 403;git 协议不受限流影响。
- tarball 无校验和。

## 来源与安装

- 上游:[nushell/nushell](https://github.com/nushell/nushell)([nushell.sh](https://www.nushell.sh))。
- release 预编译 tarball `nu-<tag>-<arch>-unknown-linux-gnu.tar.gz`:tag 无 v 前缀;arch 映射 amd64→x86_64、arm64→aarch64。
- 经 GITHUB_MIRROR 直下,解包后 `install -m755` 落 `/usr/local/bin/nu`。
- 脚本:`scripts/install-tools.sh` 的 `install_nu`。

## 文件

- `/usr/local/bin/nu` 单文件程序,无 wrapper。

## 配置

- 无(脚本不写配置、不固化缓存)。

## 离线行为

- 未验证:预编译单文件,运行不触网。
- 验证:关闭 eth0 后 `nu --version` 退出码 0。

## 限制

- GitHub 直连间歇性归零(与 tuna 抖动同期):取 tag 重试 3 次(间隔 sleep 5)。
- pipefail 下 ls-remote 失败使整条管道非零,命令替换赋值即触发 set -e 退出;故 `|| true` 兜底。
- tag 取不到时仅记录,本次不安装,再次执行该组时补装(`have nu` 幂等早退)。

## 参见

- [docs/offline.md](../../offline.md)

## rctl 收录行

- rctl: aws kind=tool path=/usr/local/bin/aws note=AWS CLI v2(awscli 官方 zip 装,未锁定,属 known-issues 软件源锁定)
- rctl: aws_completer kind=tool path=/usr/local/bin/aws_completer note=aws CLI 补全副件

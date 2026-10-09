# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-09。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库。

## 当前状态

- 镜像 `pi-rs-runtime` 第一版已落库(fingerprint `7564be3f6e57`,17.6 GB):publish 客户端超时被杀但 daemon 侧已打包完成,别名直接挂到该 fingerprint。
- 从镜像开实例验收发现三处静默缺口,已全部修复并推 main(`2b4ddc5`、`16e7609`):① nu 装不上——`install_nu` 的 `git ls-remote` 缺 owner(`${gh}/nushell` 应为 `nushell/nushell`,CyberChef 同款缺 `gchq/`);② capa wrapper 递归 exec——`printf > 软链` 穿透改写 `/opt/capa` 真身,改 nuclei 同款挪文件写法;③ pwsh 模块固化空——PackageManagement(Save-Module)在 noble+pwsh 7.4 段错误,换 inbox PSResourceGet(Save-PSResource)。
- 修复已在 `rt-img-verify`(从镜像开的实例)增量落地:nu 0.116.1、capa 9.4.0(wrapper 正常)、/opt/psmodules 8 模块,ubuntu 用户复验绿。**重发布完成:`pi-rs-runtime` → fingerprint `9c63a0288d34`**;两个无别名旧镜像(7564be3f6e57、de805a88111c)已删;rt-verify 与 rt(开发工作机,勿删)保留。
- 工作流原则(用户定):脚本幂等部署 + pin + 可升级;以后走「从发布镜像开实例 → 增量跑分类脚本 → 重 publish」的增量路线,不必每次 fresh 全量。
- `GITHUB_MIRROR` 默认改为 `https://proxy.ohmygh.com/`(置空回直连),已推 main。
- 文档重组:README 689 行拆为 132 行薄入口(定位/前置条件/文档索引/步骤)+ `docs/` 四分册:`params.md`(参数表)、`install-surfaces.md`(安装面清单)、`software-inventory.md`(软件清单归档)、`known-issues.md`(已知限制)。
- 脚本全量 fresh 验证通过,验收绿(版本输出、wrapper、/opt 缓存落点、ubuntu 用户可执行)。
- main 最新提交 `16e7609`,工作区干净。

## 已完成的里程碑(按时间)

1. 基础镜像流水线:`image-defs/ubuntu.yaml`(distrobuilder,cloud 变体)+ `build-base-image.sh`,别名 `ubuntu-24.04-base`。
2. 分类脚本四件套:`install-compilers.sh`(c/golang/rust/zig/vcpkg)、`install-runtimes.sh`(node/fnm/bun/uv/python/python2/duckdb/php/mono/dotnet/pwsh/sdkman)、`install-libcache.sh`(八生态库缓存固化)、`install-tools.sh`(17 组,含 pentest/red);`install-all.sh` 按 编译器 → 运行时 → 库缓存 → 工具 顺序跑,前置批含 git 并停掉自动升级计时器。
3. 评审吸收:grok 两份(八生态库清单 + 全平台编译矩阵,落盘 `/tmp/pi-rs-libs-review.md`)、claude 一份(环境体检,落盘 `/tmp/pi-rs-env-review.md`)→ P0/P1 实施。
4. 共享缓存全部归 /opt 并 profile.d 导出:GOPATH/GOMODCACHE(/opt/go)、RUSTUP_HOME/CARGO_HOME(/opt/rustup、/opt/cargo)、ZIG_GLOBAL_CACHE_DIR、CARGO_ZIGBUILD_CACHE_DIR、NUGET_PACKAGES(/opt/nuget-packages)、Maven localRepository(/opt/m2)、GRADLE_USER_HOME(/opt/gradle-home)、PSModulePath(/opt/psmodules);家目录 `.rustup`/`.cargo` 兼容链到 /opt(非登录 shell 实测必需)。
5. pentest 组:31 包底线批、hashcat+pocl、Responder、frida 全链(客户端与八平台 server 版本对齐,/opt/frida-server/<ver>)、nuclei 模板钉 /opt + wrapper `-duc`、capa wrapper 接规则、/usr/share/wordlists + rockyou、pwndbg 系统 gdbinit + 冒烟、时区上海 + zh_CN locale、offline() 快失败函数。
6. red 组:kerbrute/wafw00f/arjun/Coercer/mitm6/objection/apkleaks/ghauri(git 源)/bloodhound-python(re-venv + `python -m bloodhound` wrapper)、jwt_tool、LinkFinder(GerbenJavado 原仓)、enum4linux-ng(cddmp)、krbrelayx(dirkjanm)、CeWL(/opt/CeWL + wrapper)、CyberChef v9.55.0(/opt/cyberchef)、kubectl(dl.k8s.io 直连)、trivy + /opt/trivy-db 烘焙、awscli v2。
7. 库缓存固化:Go(grep 清单 go mod tidy 钉版)、Rust(cargo add 钉版 + 10 交叉 target)、Python(re-venv 扩展 18 包 + /opt/wheelhouse 52 轮子)、Node(/opt/js-lab 161 包)、Java(pom [0,) 区间 resolve-ranges + dependency:go-offline 双 profile,study 隔离 fastjson 1.2.47/1.2.68/1.2.83、log4j 2.14.1、shiro 1.2.4)、PowerShell(Save-Module 8 个)、.NET(15 包 + 8 RID runtime pack + ilspycmd)、Zig(zig fetch allyourcodebase 五库)。
8. 文档:README 按文档标准重写(how-to,无错误表——用户裁定删除);三张安装面表(组|项目|版本|官方来源|安装命令,组列中文术语 + 键对照);「软件清单归档」12 分类 249 行逐项库/包。

## fresh 验证修复台账(17 坑,全部已修)

pipefail:`ls` 多 glob 缺操作数返回 2 致赋值退出(rust-lld、ghidra j21、nushell tag);`cmd | head` 类。set -e 语义:&& 链只有最后被执行的命令失败才退出(nuclei 模板循环 rmdir 案)。其他:cloud 镜像缺 git(unattended-upgrades 抢 dpkg 锁,前置批停计时器)、ast-grep 的 sg 与 shadow 撞名、cargo/rustup 旧布局假设($HOME/.cargo/env)、fnm 无 RUSTUP_HOME、p0 apt 批无容错(tuna 抖动)、api.github.com 限流 403(nushell/CyberChef 改 git ls-remote;duckdb 链兜底)、GitHub 直连间歇归零(nushell 重试)、ghauri 不在任何 PyPI(只发 git 仓)、bloodhound-python 无 entrypoint、CyberChef 资产名保留 v 前缀、kubectl 国内无镜像、三个克隆仓名错误(ticarpi/jwt_tool、GerbenJavado/LinkFinder、cddmp/enum4linux-ng)。

## 镜像源现状(实测后切换)

apt(yaml 8 处)阿里云;PyPI 阿里云;rustup/crates rsproxy.cn;maven 发行包阿里云;goproxy.cn 不动;npmmirror(即淘宝)不动;南大 golang/sury;华为 nuget/python2;tuna 仅 Adoptium(阿里云无)。GITHUB_MIRROR 默认空,有需要用 `https://proxy.ohmygh.com/`(用户提供的 gh-proxy,实测可用)。

## 待办

1. ~~确认 `pi-rs-runtime` 别名落库~~ 已完成;重发布(含 nu/capa/psmodules 修复)完成后核对新 fingerprint,删旧镜像 `7564be3f6e57` 回收 17.6 GB。
2. 合入定制 Chrome:等用户通知定制构建完成 → install-tools.sh 加 chrome 组(定制二进制 + CDP 配置 + 对接 vnc-screen.sh 的 :99 屏幕)→ 按增量路线从 `pi-rs-runtime` 开实例装 chrome 组后重 publish。
3. 已知遗留(不阻塞):webcrack 传递依赖 isolated-vm 原生模块 npm install script 被拦;frida windows-x86 server 多数版本未发布(容错);coffee-ldr nightly 编译失败(上游问题,留档);trivy db 为构建日快照。

## 复跑流水线命令

fresh 全量(基础镜像或脚本大改后):

```bash
./scripts/build-base-image.sh   # 基础镜像(yaml 改了才需要)
incus launch ubuntu-24.04-base rt-build
incus file push scripts rt-build/root/ -r
incus exec rt-build -- bash /root/scripts/install-all.sh
# 验收后:incus stop rt-build && incus publish rt-build --alias pi-rs-runtime && incus delete rt-build
```

增量改发布容器(默认路线,脚本幂等可重跑):

```bash
incus launch pi-rs-runtime rt-edit
incus file push scripts rt-edit/root/ -r
incus exec rt-edit -- bash /root/scripts/install-tools.sh <组>   # 只跑改动的分类
# 验收后:incus stop rt-edit && incus publish rt-edit --alias pi-rs-runtime(先删旧别名)
```

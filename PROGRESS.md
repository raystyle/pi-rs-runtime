# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-09。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库。

## 当前状态

- 镜像 `pi-rs-runtime` 正在发布:`incus publish rt-verify --alias pi-rs-runtime`(后台任务,rt-verify 已 stop)。发布完成后核对 `incus image list`。
- 脚本全量 fresh 验证通过,验收绿(版本输出、wrapper、/opt 缓存落点、ubuntu 用户可执行)。
- main 最新提交 `f9c3821`,工作区干净。

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

1. 确认 `pi-rs-runtime` 别名落库(publish 后台任务完成后 `incus image list` 核对)。
2. 合入定制 Chrome:等用户通知定制构建完成 → install-tools.sh 加 chrome 组(定制二进制 + CDP 配置 + 对接 vnc-screen.sh 的 :99 屏幕)→ 重跑流水线出终版镜像。
3. 已知遗留(不阻塞):webcrack 传递依赖 isolated-vm 原生模块 npm install script 被拦;frida windows-x86 server 多数版本未发布(容错);coffee-ldr nightly 编译失败(上游问题,留档);trivy db 为构建日快照。

## 复跑流水线命令

```bash
./scripts/build-base-image.sh   # 基础镜像(yaml 改了才需要)
incus launch ubuntu-24.04-base rt-build
incus file push scripts rt-build/root/ -r
incus exec rt-build -- bash /root/scripts/install-all.sh
# 验收后:incus stop rt-build && incus publish rt-build --alias pi-rs-runtime && incus delete rt-build
```

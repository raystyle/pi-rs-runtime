# 任务进度与历史轨迹(会话记忆)

最后更新:2026-10-09。本文是跨会话的工作记忆,接续时先读本文件与 `README.md`。

## 定位

智能体渗透测试运行时系统(pi-rs-runtime):Ubuntu 24.04 noble + Incus,离线可用(建成后无外网可干活),供智能体做渗透测试与 CTF。仓库只维护 yaml、脚本与文档,镜像产物不入库。

## 当前状态

- 最新发布链:9c63a0288d34(三缺口修复)→ f0bc3ee442c2(nasm 3.02 源码钉版 + donut 1.1)→ **`fd5b78bd8ec0`(当前线上版,19.8 GB)**;旧镜像与构建容器均已清,磁盘 49%。
- 本版新增(全部 ubuntu 复验绿):nim 2.2.12(choosenim,/opt/nim)、clickhouse 26.10(官方单二进制,`clickhouse local`)、nasm 3.02、donut 1.1、RustHound-CE(补 libkrb5-dev 后构建过)、praetorian 三件 nerva/brutus(走 /cmd 子路径)/aurelian(根模块)、fff-search 0.11 进 rust 库预热(fff-mcp 二进制用户裁定不装)。
- 归档三轴分类(grok 评审裁定,全文曾落 /tmp/grok-maldev-classification.md):`c2dev-ref/`(sliver/merlin/Empire/Covenant/mythic/SILENTTRINITY)、`payload-ref/`(generators{deserialization,pe-to-shellcode}、loaders{droppers,inproc}、evasion{ShellcodeFluctuation,crystal-palace}、curricula{zig,rust,nim,go}、analysis{donut-decryptor})、`tradecraft-ref/`(ad/bof/opsec);COFFLoader/bof-launcher 源码在 loaders/inproc 原地编译;atomic-bofs/BOF-CATALOG 在 tradecraft-ref/bof;Crystal Palace(cpsrc+cpdist)与 Tradecraft Garden(tcg-latest.tgz)官网源码归档;新 recon 组 /opt/recon-ref(mac-tracker/recog/hickory-dns)。语言只做教材次轴,SILENTTRINITY 是 C2 不是 Nim 教材,ysoserial 是反序列化生成器不是 C2。
- 网络面:proxy.ohmygh.com 实测**只代理 GitHub 系**(nim-lang.org/clickhouse.com/tradecraftgarden.org 均 TLS 重置),非 GitHub 站走直连;宿主 DNS 曾整挂(路由器 192.168.88.2 对 github.com 等返回无记录),wlo1 已指 223.5.5.5/223.6.6.6(DHCP 续约会恢复,复发照此处理)。
- 工作流原则(用户定):脚本幂等部署 + pin + 可升级;走「从发布镜像开实例 → 增量跑分类脚本 → 重 publish」路线。
- `GITHUB_MIRROR` 默认 `https://proxy.ohmygh.com/`(置空回直连)。
- 文档:`docs/install-surfaces/` 拆成四件(index/compilers/runtimes/tools),p0 逐项重写(21 包各一行带用途),inventory 同步三轴与全部新增;README 132 行薄入口。
- main 最新提交 `bc07faa`,工作区干净。

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

# 已知限制与未决项

本册只登记当前镜像与脚本的**真限制/未决项**;已规定项见 [adr/](adr/README.md)(尤其),离线机制边界见 [offline.md](offline.md),逐件问题见 [items/](items/README.md) 各册「问题与」节。返回 [README](../README.md)。

## 未锁定版本:例外清单,其余全部锁定在 scripts/lib/pins.sh

以下因渠道特性不锁定(软件源锁定,按当前形态接受):clickhouse(官方安装脚本设计即最新稳定线)、awscli v2(无干净版本索引)、msf omnibus(apt.metasploit.com 只发最新线;pins.sh 里 MSF_VERSION 留空)、pwsh(MS 仓 apt 浮动)、php/mono/apt 系(noble/sury 源冻结即锁定)、mono 的 nuget.exe(dist.nuget.org 只有 latest 链)、sdkman/choosenim/rustup 安装器本体、rustup stable/nightly 工具链、crystal-palace/tcg 官网 tgz、BOF-CATALOG raw 文件、pecl VLD。库缓存层六生态锁文件(go.mod/go.sum、Cargo.lock、package-lock.json、解析后 pom、build.zig.zon、dotnet csproj)已入库 `scripts/lock/`(2026-10-10 phase B,install-libcache.sh 消费,`scripts/sync-locks.sh` 再生);python/pwsh 无独立锁文件(pins.sh 锁定直接依赖,传递闭包仍在构建日解析)。`resolve-pins.sh` 解析失败的件会以未写锁定版本形态让消费点报错,不许静默漂。

## 无校验和件:路线已选,按当前形态接受

trufflehog release(上游 go.mod 带 replace 不能 `go install @版本`)、metasploit omnibus(`msfupdate.erb` + apt.metasploit.com)、zig 发行包(直下无验签,minisig 公钥 `RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U` 待接)、duckdb CLI、CyberChef zip、donut release、nasm 源码。

## 构建期已知失败/缺口:不阻塞

- webcrack 传递依赖 isolated-vm 原生模块 npm install script 被拦
- frida windows-x86/arm64 server 多数版本上游未发布(容错跳过)
- coffee-ldr nightly 编译失败(上游 `#!feature` 问题,留档;BOF 运行有 bof-launcher 与 mingw/wine 兜底),见 [items/tools-bof/coffee-ldr.md](items/tools-bof/coffee-ldr.md)
- trivy 漏洞库/Java 库、nuclei 模板为构建日快照;要新鲜数据回有网环境重跑对应组再 publish
- nuclei headless 模板依赖 Chrome,定制 Chrome 未合入前不可用(PROGRESS.md 待办 1)
- ~~VNC 屏幕无 Chrome 与 noVNC~~:桌面栈(xfce4+tigervnc+noVNC+websockify)烘焙进镜像(vnc 组),启动面 `vnc-screen desktop`,浏览器经 incus proxy 127.0.0.1:6080 进([items/tools-vnc/vnc.md](items/tools-vnc/vnc.md));Chrome 官方版仍不装;定制构建已合入(clean-chrome 155.0.8059.39,云端道 chrome.ohmygh.com
- `pi-box-dev` 镜像(pi 二进制、pi-web、定制 Chrome)的构建脚本不在本仓

## 行为边界:设计如此,不是缺陷

- **宿主层信号投递策略(2026-10-11 回归,非本镜像问题)**:本机构建机的容器内,除 pid1 外一切进程的信号 syscall(kill/tkill/tgkill/pidfd_send_signal)恒返回 EPERM:root/ubuntu 同、自信号 kill(self,0) 同、systemd scope 收割也不行;宿主进程正常、base 镜像新容器同样复现(Incus 6.0.5 + kernel 7.0 层策略)。影响面:容器内 pkill/kill/timeout 收割全部失效(timeout 会等到子进程自然退出才返回)、msf/gdb 等进程管理类动作受限、vnc-screen.sh 的 stop/chrome-stop 只能摘端口进程摘不掉(进程留到容器重启)。绕行:进程管理移宿主侧,或接受「进程起满生命周期」的用法;容器 `incus restart` 可清残留
- 离线期 `apt install` 新件不可用(lists 已清,快失败属预期);五生态拉新件亚秒报错()
- `incus exec` 非登录 shell 不读 /etc/profile.d 与 /etc/environment;离线必需的件一律走 per-user 配置/默认路径软链/wrapper,profile.d 只是登录备份面
- npm `--prefix` 会连 prefix 级 npmrc 一起丢;uv 用户级 ~/.config/uv/uv.toml 存在则系统级整份失效
- alias 只在交互登录 shell 生效,运行期行为修正必须落 wrapper 文件
- ubuntu 用户无免密 sudo(设计态):vnc-screen.sh 的 setup/setup-desktop 面(apt 装)只有 root 能跑;start/desktop/stop 不需要 sudo

本仓只维护 yaml、脚本与文档;镜像产物不入库;distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`,失败后可手动清理。

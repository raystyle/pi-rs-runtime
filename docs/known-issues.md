# 已知限制与未决项

本册只登记当前镜像与脚本的**真限制/未决项**;已裁定项见 [adr/](adr/README.md)(尤其 [ADR-0006 用户裁定留痕](adr/ADR-0006-user-rulings-log.md)),离线机制边界见 [offline.md](offline.md),逐件坑见 [items/](items/README.md) 各册「坑与留痕」节。返回 [README](../README.md)。

## 未钉版本(升级即漂)

temurin 小版本随 tuna Adoptium 目录;`dlv`/`gopls`/`golangci-lint` 与 projectdiscovery 全家桶、Go 安全工具组用 `@latest`(`have && skip` = 首次装到的那份,升级要删了重跑);rizin、rz-ghidra、sigdb、SecLists、yara 规则、Responder、参考克隆批均 `--depth 1` 未钉提交;pwndbg 从 git 源装未钉 rev;uv 本体、nushell 等随官方安装器最新。

## 无校验和件(路线已选,留痕接受)

trufflehog release(上游 go.mod 带 replace 不能 `go install @版本`)、metasploit omnibus(`msfupdate.erb` + apt.metasploit.com)、zig 发行包(直下无验签,minisig 公钥 `RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U` 待接)、duckdb CLI、CyberChef zip、donut release、nasm 源码。

## 构建期已知失败/缺口(不阻塞)

- webcrack 传递依赖 isolated-vm 原生模块 npm install script 被拦
- frida windows-x86/arm64 server 多数版本上游未发布(容错跳过)
- coffee-ldr nightly 编译失败(上游 `#!feature` 问题,留档;BOF 运行有 bof-launcher 与 mingw/wine 兜底)——见 [items/tools-bof/coffee-ldr.md](items/tools-bof/coffee-ldr.md)
- trivy 漏洞库/Java 库、nuclei 模板为构建日快照;要新鲜数据回有网环境重跑对应组再 publish
- nuclei headless 模板依赖 Chrome,定制 Chrome 未合入前不可用(PROGRESS.md 待办 1)
- VNC 屏幕无 Chrome 与 noVNC;Chrome 官方版不装(ADR-0006)
- `pi-box-dev` 镜像(pi 二进制、pi-web、定制 Chrome)的构建脚本不在本仓

## 行为边界(设计如此,不是缺陷)

- 离线期 `apt install` 新件不可用(lists 已清,快失败属预期);五生态拉新件亚秒报错([ADR-0004](adr/ADR-0004-offline-first-fail-fast.md))
- `incus exec` 非登录 shell 不读 /etc/profile.d 与 /etc/environment;离线必需的件一律走 per-user 配置/默认路径软链/wrapper,profile.d 只是登录备份面
- npm `--prefix` 会连 prefix 级 npmrc 一起丢;uv 用户级 ~/.config/uv/uv.toml 存在则系统级整份失效
- alias 只在交互登录 shell 生效,运行期行为修正必须落 wrapper 文件

本仓只维护 yaml、脚本与文档;镜像产物不入库;distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`,失败后可手动清理。

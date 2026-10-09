# 已知限制与未决项

本册登记当前镜像与脚本的已知限制，不阻塞流水线的问题在 [PROGRESS.md](../PROGRESS.md) 待办节跟踪。返回 [README](../README.md)。

- 版本未钉：temurin 小版本随 tuna Adoptium 目录取最新；`dlv`、`gopls`、`golangci-lint` 与 projectdiscovery 全家桶、Go 安全工具组用 `@latest`(`have && skip` 意味着“首次装到的那份”);rizin、rz-ghidra、sigdb、SecLists、yara 规则均为 `--depth 1` 未钉提交；pwndbg 从 git 源装、未钉 rev。
- 未钉且无校验和的件（同上路线，不重排）：trufflehog release（上游 go.mod 带 replace 不能 `go install @版本`，tag 经 git ls-remote + `sort -V` 取）、metasploit omnibus 安装器（`msfupdate.erb` 加 apt.metasploit.com 仓）。ghidra/herdr/nasm/Go/node 另有 sha256 或 SHASUMS 校验。
- zig 发行包无国内镜像，直下且无验签。minisig 公钥：`RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U`。验签未做。
- `/root` 0700 的残留面：rust 工具链在 `/opt`（`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`),rust 段新装产物都归 /opt;ast-grep、Rust 安全工具、代理跳板、coffee-ldr 与 fnm 经 root 的 `~/.cargo` 安装再链到 `/usr/local/bin`;tools 各组 `GOPATH=/opt/go`(dlv/gopls/golangci-lint、projectdiscovery 全家桶、Go 安全工具、代理跳板归 /opt/go 并链出）；基础 CLI 组的 yq 与 gh 未设 GOPATH，产物在 /root/go 且只链 yq,`ubuntu` 用户对 gh 不可执行。已有的 /root/.cargo、/root/go 环境不受影响。
- `install_secrust` 装 rustscan、feroxbuster、RustHound-CE 三件；findomain 不装，依赖多常编不过，注释建议改用 [Findomain/Findomain releases](https://github.com/Findomain/Findomain/releases) 预编译。
- `install_php` 中 PHP 7.4 已无官方支持，样本动态执行需在无网络、无生产数据挂载的环境里跑，并加 `-d opcache.jit=off`；当前部署链未强制该隔离面。python2 同理（已通过实测含 `import ssl`)。
- VNC 屏幕无 Chrome 与 noVNC;Chrome 官方版不装，后续定制构建。
- C2 框架（sliver、merlin、Empire、Covenant、mythic、SILENTTRINITY、AdaptixC2）只克隆到 `/opt/c2dev-ref` 作参考，不安装不运行；载荷与开发模板（maldev 组 41 仓，外加 Crystal Palace/Tradecraft Garden 官网 tgz）同样只克隆，按工件角色轴归档 `/opt/payload-ref` 与 `/opt/tradecraft-ref`；侦察指纹库（recon 组 4 仓）只克隆到 `/opt/recon-ref`；.NET 参考项目（pz 组）同样只克隆。
- 用户裁定留痕（grok 评审建议后裁定）：移除批（gospider、httprobe、assetfinder、waybackurls、Covenant、SILENTTRINITY）与 EOL 运行时（python2、PHP 7.4/8.1、JDK 11、Node 18/20）**全保留**；impacket 不用 noble apt 冻结版，改 `uv tool install impacket` 上游版（老镜像 apt 版增量迁移自动卸）；fff-mcp 不装二进制，fff-search 只进 rust 库预热；grok 库评审的 BananaPhone、go-clr、garble、obfstr、boost、Detours、JsonSpirit、webshell 样本库与哥斯拉/冰蝎/蚁剑操作台均裁定不进镜像。
- `pi-box-dev` 镜像（pi 二进制、pi-web、定制 Chrome）的构建脚本不在本仓，`build.sh` 未做。
- 备选路线：单个实例可直接 `incus launch images:ubuntu/24.04`,`incus stop` 后 `incus publish --alias <名>` 固化，不经 distrobuilder。

本仓只维护 yaml、脚本与文档；镜像产物不入库；distrobuilder 构建缓存与根目录在 `/tmp/distrobuilder`，失败后可手动清理。

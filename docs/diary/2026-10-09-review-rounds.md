# 2026-10-09 评审双批、归档三轴与全做批

> 归档自 PROGRESS.md 历史节(文档解耦轮);当时完整上下文以 git 历史为准。

## 红队评审批(grok,X API+红队社区实证)

装 bloodhound-ce、certipy 5.1.0、bloodyAD、bofhound、urlfinder、cvemap 等;克隆 AdaptixC2、TrustedSec BOF 两套、Rubeus、Goffloader、SpecterOps/skills、PoC-in-GitHub 索引。用户裁定(ADR-0006):移除批与 EOL 运行时全保留;impacket 改 uv 上游版。

## 库评审批(grok)

windows-sys 进 rust 预热;ApiHashing/HellHall/Stardust 只克隆;BananaPhone/go-clr/garble 等评审不进(ADR-0006)。bof-launcher 上游是库无 CLI,装示例执行器 bof_lin_<arch>。

## 归档三轴分类(grok 评审裁定 → ADR-0002)

c2dev-ref(C2 框架)、payload-ref(generators/loaders/evasion/curricula/analysis)、tradecraft-ref(ad/bof/opsec);COFFLoader/bof-launcher 源码原地编译;Crystal Palace/Tradecraft Garden 官网源码归档;recon 组 /opt/recon-ref。语言只做教材次轴,SILENTTRINITY 是 C2 不是 Nim 教材,ysoserial 是反序列化生成器不是 C2。

## 全做批(逐项容器验证)

tradecraft-ref/privesc 新叶;cli 加 fzf/bat/htop/ncdu/moreutils/vim;pentest 批 33→36 包(openvpn/wireguard-tools/masscan setcap);secgo 加 trufflehog(release 钉 tag,上游 go.mod 带 replace 拒 go install);red 加 semgrep(uv tool)、evil-winrm(ruby-dev+gem);bof 加 wine 9.0(noble wine64 包无 PATH 命令,补 wine 包链 wine64;只 64 位不开 i386);新 msf 组(omnibus,Framework 6.5.3);recon 加 poc-search wrapper + clickhouse parquet 索引 25988 条;libcache python 链 vol/volshell。

## 本版新增

nim 2.2.12(choosenim)、clickhouse 26.10(官方单二进制,`clickhouse local`)、nasm 3.02、donut 1.1、RustHound-CE、praetorian 三件(nerva/brutus/aurelian)、fff-search 进 rust 库预热(fff-mcp 用户裁定不装)。

## 容器实证三修

red 组 venv 链接循环曾把 bin/python3 链到 /usr/local/bin 劫持系统 python 并成环 ELOOP(semgrep 受害),排除 python*/pip*/*activate*/*.bat(后演进为 ADR-0003 白名单);noble wine64 包 dpkg -L 无 bin/(loader 在 /usr/lib/wine/),/usr/bin/wine 在 wine 包;CeWL 幂等判据 -d 改 -f。

## grok 评审轮(F1+G5 全吸收)

F1:red 组 venv 全目录链把依赖 CLI(httpx/idna/normalizer)链出盖掉 pd 组 Go httpx 且 have-skip 不自愈 → 白名单重构;bloodhound-python wrapper 无条件重写(曾被 bofhound 链盖)。G 级:trufflehog tag 排序 sort -V;just 兜底 /opt/cargo;poc-search 空命中文案+CVE 格式校验;文档 wine/masscan 口径追齐;无校验和件留痕。

# maldev 组册:恶意开发模板参考库,41 仓 + 官网 tgz 两件

> 载荷开发与操作技法参考仓。只克隆,不编译,不运行。按工件角色归档 ｜ 状态:参考克隆 ｜ 组:`install-tools.sh maldev`

## 版本

- 41 个 Git 仓都由 pins.sh 的 `GIT_PIN` 锁定提交;`clone_pin` 在 HEAD 等于锁定提交时跳过;解析日 2026-10-10;升级:执行 `scripts/resolve-pins.sh`;Crystal Palace 与 Tradecraft Garden 没有 Git 仓;官网的 `latest` tgz 没有锁定版本;pins.sh 没有收录这两件的锁定项;这两件没有校验和。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_maldev`;GitHub 克隆经 `GITHUB_MIRROR`;每个仓失败后重试一次;仍然失败时输出「本次不安装。再次执行该组时安装」;这次失败不阻塞本批。
- Crystal Palace 取 `cpsrc-latest.tgz` 与 `cpdist-latest.tgz`。
- 这两件是 PIC 链接器;Tradecraft Garden 取 `tcg-latest.tgz`;这件是能力加载器集。
- 下载地址是 [tradecraftgarden.org](https://tradecraftgarden.org) 的 `/download`。
- 下载后解包。

## 文件

- `/opt/payload-ref` 与 `/opt/tradecraft-ref` 按工件角色分目录;`/opt/c2dev-ref` 属于 c2 组。本组不写这个目录。

| 根 | 叶 | 内容 |
| --- | --- | --- |
| /opt/payload-ref | generators | 字节,或变形后的二进制 |
| /opt/payload-ref | loaders | 执行这些字节的进程 |
| /opt/payload-ref | evasion | 贴到 loader 上的原语 |
| /opt/payload-ref | curricula | 教材,按语言分叶 |
| /opt/payload-ref | analysis | 防御向 |
| /opt/tradecraft-ref | ad、bof、opsec、privesc、skills | 上线后的操作员动作 |

## 配置

- 无;只克隆,不写配置;仓本体就是固化缓存;Git 克隆的幂等判据是 `.git` 目录是否存在。

## 离线行为

- 支持。克隆仓只读磁盘,不访问网络。见 [offline.md](../../offline.md)。
- 关闭 eth0 后,`find /opt/payload-ref /opt/tradecraft-ref -maxdepth 4 -name .git | wc -l` 的结果 ≥ 41。
- bof 组与 rust-security 组在同一根下的克隆会让这个计数更大;两件 tgz 没有 `.git`,不计入这个数。

## 限制

- 归档轴按工件角色,不按语言;SILENTTRINITY 是 C2,归 c2 组;ysoserial 是反序列化生成器,归 `generators/deserialization`;donut-decryptor 是防御向,归 analysis;它不被当作进攻模板抄写;语言只出现在 curricula 这个次级轴。
- COFFLoader、bof-launcher、atomic-bofs、RustHound-CE 不在本组 41 仓内。
- 它们由 bof 组或 rust-security 组各自克隆并构建;归档根与本组相同;tcg 的幂等判据是内容存在;判据是资产内的顶层目录 `tcg/`;失败时 `rm -rf`,避免空目录把后续执行卡住;crystal-palace 的幂等判据只看目录是否存在;cpsrc 成功而 cpdist 失败时,目录已经存在;重跑时整段跳过,cpdist 不会补上;两条判据不对称;只克隆,不运行。见 [known-issues.md](../../known-issues.md)。

## 参见

- [c2.md](../tools-c2/c2.md)
- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## 成员清单

41 仓与 2 件 tgz 的对账表:

| 仓 | 归档叶(/opt/ 下) |
|---|---|
| [frohoff/ysoserial](https://github.com/frohoff/ysoserial) | payload-ref/generators/deserialization/ysoserial |
| [pwntester/ysoserial.net](https://github.com/pwntester/ysoserial.net) | payload-ref/generators/deserialization/ysoserial.net |
| [wabzsy/gonut](https://github.com/wabzsy/gonut) | payload-ref/generators/pe-to-shellcode/gonut |
| [Zuigetzu/Donut-CustomHost](https://github.com/Zuigetzu/Donut-CustomHost) | payload-ref/generators/pe-to-shellcode/Donut-CustomHost |
| [n1xbyte/donutCS](https://github.com/n1xbyte/donutCS) | payload-ref/generators/pe-to-shellcode/donutCS |
| [Binject/go-donut](https://github.com/Binject/go-donut) | payload-ref/generators/pe-to-shellcode/go-donut |
| [monoxgas/sRDI](https://github.com/monoxgas/sRDI) | payload-ref/generators/pe-to-shellcode/sRDI |
| [hasherezade/pe_to_shellcode](https://github.com/hasherezade/pe_to_shellcode) | payload-ref/generators/pe-to-shellcode/pe_to_shellcode |
| [phra/PEzor](https://github.com/phra/PEzor) | payload-ref/generators/pe-to-shellcode/PEzor |
| [blinkenl1ghts/donloader](https://github.com/blinkenl1ghts/donloader) | payload-ref/loaders/droppers/donloader |
| [optiv/ScareCrow](https://github.com/optiv/ScareCrow) | payload-ref/loaders/droppers/ScareCrow |
| [boku7/BokuLoader](https://github.com/boku7/BokuLoader) | payload-ref/loaders/droppers/BokuLoader |
| [benheise/TitanLdr](https://github.com/benheise/TitanLdr) | payload-ref/loaders/droppers/TitanLdr |
| [xuanxuan0/DripLoader](https://github.com/xuanxuan0/DripLoader) | payload-ref/loaders/droppers/DripLoader |
| [icyguider/Shhhloader](https://github.com/icyguider/Shhhloader) | payload-ref/loaders/droppers/Shhhloader |
| [praetorian-inc/goffloader](https://github.com/praetorian-inc/goffloader) | payload-ref/loaders/inproc/goffloader |
| [fortra/No-Consolation](https://github.com/fortra/No-Consolation) | payload-ref/loaders/inproc/No-Consolation |
| [fancycode/MemoryModule](https://github.com/fancycode/MemoryModule) | payload-ref/loaders/inproc/MemoryModule |
| [DarthTon/Blackbone](https://github.com/DarthTon/Blackbone) | payload-ref/loaders/inproc/Blackbone |
| [mgeeky/ShellcodeFluctuation](https://github.com/mgeeky/ShellcodeFluctuation) | payload-ref/evasion/ShellcodeFluctuation |
| [Cracked5pider/Stardust](https://github.com/Cracked5pider/Stardust) | payload-ref/evasion/Stardust |
| Crystal Palace(cpsrc+cpdist,官网 tgz) | payload-ref/evasion/crystal-palace |
| Tradecraft Garden(tcg-latest,官网 tgz) | payload-ref/loaders/tradecraft-garden |
| [CX330Blake/Black-Hat-Zig](https://github.com/CX330Blake/Black-Hat-Zig) | payload-ref/curricula/zig/Black-Hat-Zig |
| [darkr4y/OffensiveZig](https://github.com/darkr4y/OffensiveZig) | payload-ref/curricula/zig/OffensiveZig |
| [trickster0/OffensiveRust](https://github.com/trickster0/OffensiveRust) | payload-ref/curricula/rust/OffensiveRust |
| [skerkour/black-hat-rust](https://github.com/skerkour/black-hat-rust) | payload-ref/curricula/rust/black-hat-rust |
| [byt3bl33d3r/OffensiveNim](https://github.com/byt3bl33d3r/OffensiveNim) | payload-ref/curricula/nim/OffensiveNim |
| [Enelg52/OffensiveGo](https://github.com/Enelg52/OffensiveGo) | payload-ref/curricula/go/OffensiveGo |
| [Maldev-Academy/ApiHashing](https://github.com/Maldev-Academy/ApiHashing) | payload-ref/curricula/cpp/ApiHashing |
| [Maldev-Academy/HellHall](https://github.com/Maldev-Academy/HellHall) | payload-ref/curricula/cpp/HellHall |
| [volexity/donut-decryptor](https://github.com/volexity/donut-decryptor) | payload-ref/analysis/donut-decryptor |
| [g0h4n/IsWebClientRunning-rs](https://github.com/g0h4n/IsWebClientRunning-rs) | tradecraft-ref/ad/IsWebClientRunning-rs |
| [g0h4n/HasSession-rs](https://github.com/g0h4n/HasSession-rs) | tradecraft-ref/ad/HasSession-rs |
| [g0h4n/LocalGroups-rs](https://github.com/g0h4n/LocalGroups-rs) | tradecraft-ref/ad/LocalGroups-rs |
| [g0h4n/PassTheCert-rs](https://github.com/g0h4n/PassTheCert-rs) | tradecraft-ref/ad/PassTheCert-rs |
| [icedracon/dcerpc](https://github.com/icedracon/dcerpc) | tradecraft-ref/ad/dcerpc |
| [icedracon/adhammer](https://github.com/icedracon/adhammer) | tradecraft-ref/ad/adhammer |
| [GhostPack/Rubeus](https://github.com/GhostPack/Rubeus) | tradecraft-ref/ad/Rubeus |
| [g0h4n/dende-rs](https://github.com/g0h4n/dende-rs) | tradecraft-ref/opsec/dende-rs |
| [carlospolop/PEASS-ng](https://github.com/carlospolop/PEASS-ng)(linpeas/winpeas) | tradecraft-ref/privesc/PEASS-ng |
| [mzet-/linux-exploit-suggester](https://github.com/mzet-/linux-exploit-suggester) | tradecraft-ref/privesc/linux-exploit-suggester |
| [SpecterOps/skills](https://github.com/SpecterOps/skills) | tradecraft-ref/skills/skills |

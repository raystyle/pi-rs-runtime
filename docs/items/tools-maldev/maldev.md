# maldev 组册:恶意开发模板参考库(41 仓 + 官网 tgz 两件)

> 载荷开发与操作技法参考仓,只克隆不编译不运行,按工件角色轴归档 ｜ 状态:参考克隆 ｜ 组:`install-tools.sh maldev`

- **版本钉**:41 仓全部 `git clone --depth 1` 未钉提交(升级靠重跑组);Crystal Palace / Tradecraft Garden 无 Git 仓,官网 `latest` tgz 未钉、无校验和
- **来源与安装**:GitHub 经 `GITHUB_MIRROR` 循环克隆(`scripts/install-tools.sh install_maldev`),每仓失败重试一次、仍败 echo 「下轮补」不阻塞批;Crystal Palace(`cpsrc-latest.tgz` + `cpdist-latest.tgz`,PIC 链接器)与 Tradecraft Garden(`tcg-latest.tgz`,能力加载器集)自 [tradecraftgarden.org](https://tradecraftgarden.org) `/download` 直下解包
- **落点**:三轴归档(裁定见 [ADR-0002](../../adr/ADR-0002-reference-clone-three-axis.md)):`/opt/payload-ref`(generators 产物是字节或变形二进制 / loaders 产物是执行字节的进程 / evasion 往 loader 贴的原语 / curricula 教材按语言分叶 / analysis 防御向)与 `/opt/tradecraft-ref`(上线后的操作员动作:ad/bof/opsec/privesc/skills);`/opt/c2dev-ref` 属 c2 组,本组不落。41 仓 + 2 件 tgz 对账表:

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

- **配置与缓存**:无(只克隆不写配置;仓本体即固化缓存,git 克隆幂等判据是 `.git` 目录在否)
- **离线行为**:✅ 断网在位核验——断网冒烟覆盖「参考库在位」面([离线机制 §验证](../../offline.md),2026-10-10 轮 78/0);克隆仓纯读盘不触网。验证:`ip link set eth0 down` 后 `find /opt/payload-ref /opt/tradecraft-ref -maxdepth 4 -name .git | wc -l` ≥ 41(bof/secrust 组同轴仓另增计数,tgz 两件无 .git 不计)
- **坑与留痕**:归档是工件角色轴不是语言轴——SILENTTRINITY 是 C2 走 c2 组,ysoserial 是反序列化生成器归 generators/deserialization,donut-decryptor 是防御向归 analysis(避免被当进攻模板抄),语言只做 curricula 次轴([ADR-0002](../../adr/ADR-0002-reference-clone-three-axis.md));有编译产物的仓(COFFLoader/bof-launcher/atomic-bofs/RustHound-CE)由 bof/secrust 组各自克隆构建、落点同轴,不在本组 41 仓内;tcg 幂等以内容存在(资产内 `tcg/` 顶层目录)为判据、失败 rm -rf 目录不被空目录卡住,crystal-palace 幂等却只看目录在否——cpsrc 成而 cpdist 败时目录已在,重跑整段跳过(两判据不对称,留痕);只克隆不运行的裁定留痕 [known-issues](../../known-issues.md)

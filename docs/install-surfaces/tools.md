# 安装面清单 · 工具(`install-tools.sh`)

组卡只写机制;逐件事实在 [items/tools-<组>/](../items/README.md#toolsinstall-toolssh41-册)。

## 组机制(共性)

- Go 工具批(pd/secgo):`go install` 进 GOPATH=/opt/go/bin 再链 /usr/local/bin;`@latest` + `have` 早退 = 「首次装到的那份」,升级要删了重跑;v2/v3/v8 模块路径产物改名回原名(ffuf/gobuster/gitleaks)
- uv tool 批(red):UV_TOOL_DIR=/opt/uv-tools,venv 外链到 /usr/local/bin 必须白名单化(ADR-0003)
- Release 钉版批:tag 经 `git ls-remote` 取(api.github.com 限流 403 实证),资产名校验架构映射;无校验和的件在 known-issues 留痕
- git 克隆批:`--depth 1` 钉 /opt,升级靠重跑;参考克隆只归档不安装(ADR-0002)
- apt 批:阿里云源(image-defs/ubuntu.yaml 钉入),整批一条命令,成员表在组册
- wrapper 层:/usr/local/bin 压过 PATH 后段,承载运行期行为修正(trivy/nuclei/capa/responder/bloodhound-python 等;ADR-0004——alias 在非交互 shell 不生效)
- 收尾卫生:clean-image.sh(install-all.sh 末尾)清可再生缓存,不碰 /opt 固化件

## 册索引

| 组 | 册 |
|---|---|
| fd / astgrep / cli / herdr | [fd](../items/tools-fd/fd.md) · [astgrep](../items/tools-astgrep/astgrep.md) · [cli(15 件)](../items/tools-cli/cli.md) · [herdr](../items/tools-herdr/herdr.md) |
| ghidra / re | [ghidra](../items/tools-ghidra/ghidra.md) · [re(逆向稳定链)](../items/tools-re/re.md) |
| pd / secgo / secrust | [pd(20 CLI)](../items/tools-pd/pd.md) · [nuclei](../items/tools-pd/nuclei.md) · [secgo(18 CLI)](../items/tools-secgo/secgo.md) · [trufflehog](../items/tools-secgo/trufflehog.md) · [secrust(3 件)](../items/tools-secrust/secrust.md) |
| pivot / p0 | [pivot(6 件)](../items/tools-pivot/pivot.md) · [p0(apt 20 包)](../items/tools-p0/p0.md) · [nasm](../items/tools-p0/nasm.md) · [impacket](../items/tools-p0/impacket.md) · [apktool](../items/tools-p0/apktool.md) · [capa](../items/tools-p0/capa.md) · [pwndbg](../items/tools-p0/pwndbg.md) · [jadx](../items/tools-p0/jadx.md) |
| c2 / bof / pz | [c2(7 仓参考)](../items/tools-c2/c2.md) · [bof](../items/tools-bof/bof.md) · [wine](../items/tools-bof/wine.md) · [bof-launcher](../items/tools-bof/bof-launcher.md) · [coffee-ldr](../items/tools-bof/coffee-ldr.md) · [pz(4 仓)](../items/tools-pz/pz.md) |
| maldev / recon / nu | [maldev(41 仓+官网 tgz)](../items/tools-maldev/maldev.md) · [recon(4 仓)](../items/tools-recon/recon.md) · [poc-search](../items/tools-recon/poc-search.md) · [nu](../items/tools-nu/nu.md) |
| pentest / red / msf / vnc | [pentest(36 apt+接线)](../items/tools-pentest/pentest.md) · [hashcat](../items/tools-pentest/hashcat.md) · [responder](../items/tools-pentest/responder.md) · [donut](../items/tools-pentest/donut.md) · [frida](../items/tools-pentest/frida.md) · [red(24 件)](../items/tools-red/red.md) · [bloodhound-ce](../items/tools-red/bloodhound-ce.md) · [enum4linux-ng](../items/tools-red/enum4linux-ng.md) · [evil-winrm](../items/tools-red/evil-winrm.md) · [cyberchef](../items/tools-red/cyberchef.md) · [trivy](../items/tools-red/trivy.md) · [msf](../items/tools-msf/msf.md) · [vnc(桌面+noVNC Web 面)](../items/tools-vnc/vnc.md) |

返回 [安装面清单](index.md)。

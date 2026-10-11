# REQ-0003 CTF/渗透必备库与数据资产物化预热:P0+P1

> 状态:draft ｜ 提出:2026-10-11 ｜ 研究:grok prt-08 回执(P0/P1/P2 判例) ｜ 关联:六域归档(env 分面)、libcache 六生态

## 需求

R1 P0 落地:one_gadget(GEM_PIN 1.10.0;2.1.1 要 Ruby>=3.3 系统是 3.2.3,取 3.2 面最新)
R2 P0 契约入册:pwn/ROPgadget 只用系统 /usr/bin/python3(apt 面),re-venv 没有 pwn 是设计;frida 绑定只在 uv tool 环境(与 server 17.23.3 对齐),不复制进 re-venv
R3 P1:seccomp-tools 1.7.1(GEM_PIN)、qiling 1.4.6(PYPI_PIN 进 re-venv+wheelhouse)
R4 P1 数据资产(clone_pin 钉 sha,kind=data):GTFOBins、LOLBAS、enthec/webappanalyzer(指纹库)
R5 裁定项(待用户):exploit-db(GitLab 道,GITHUB_MIRROR 不代理,需直连或 Kali orig tar)、angr 10.0.3(单独 /opt/angr-venv+独立轮子切片,禁 extra)、HackTricks(约 1GiB)
R6 不做清单(grok prt-08 不建议项全收):ropper/pwninit/libc-database 全量/NVD 全量/bin-sploits/cfr/dex2jar/sage/PyPI pwn 空包

## trace:实现回填

- T1 REQ 立单(2026-10-11)
- T2 pins:GEM_PIN one_gadget=1.10.0/seccomp-tools=1.7.1、PYPI_PIN qiling=1.4.6、GIT_PIN LOLBAS/webappanalyzer/exploitdb(exploit-db 走 GitLab 直连,GITHUB_MIRROR 不代理)
- T3 install-tools.sh data 组落地:三仓 clone(GitLab 钉克隆内联);gem 段入 pentest 组(初版误入 red 段已挪);qiling 入 re 组 re-venv
- T4 实例装+断烟:seccomp-tools 1.7.1 过、one_gadget 1.10.0 过(2.1.1 Ruby>=3.3 拒)、qiling 1.4.6 断网 import 过、exploitdb 47799 文件/LOLBAS/webappanalyzer 三仓在位
- T5 册 tools-data/dataref.md+契约两句(p0/frida 册)+catalog 403+计数 80;GTFOBins 通道暂拒(代理 401)挂起

## 验收判据

- one_gadget/seccomp-tools/qiling 断网 `--version/-h` 过;三数据仓在 /opt 有册可搜;契约两句进 pwn 相关册

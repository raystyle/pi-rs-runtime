# 皓玄宿主影子跑 runbook:镜像消费方,agent-base 分支契约

> 镜像:pi-rs-runtime-agent-20261015-0659(fingerprint 2e5c3342aef2…89468,3.6GiB)
> 落点:皓玄网关宿主 10.10.10.16 本地 incus;本文即镜像消费契约,改动须同步出版方。

## 1. 宿主前置:一次性

- incus 安装(系统发行版包或 zabbly 稳定仓);`incus admin init` 默认向导(zfs 或 dir 存储池皆可)。
- **隔离 project**,影子期隔离爆炸半径:
  ```
  incus project create haoxuan
  incus project switch haoxuan   # 或每条命令 --project haoxuan
  ```
- 网络:默认 incusbr0(NAT 出网,容器需达 overcast 网关 10.10.10.9:8317 与尾网);宿主需在尾网(tailscale0 上 10.10.10.16)。

## 2. 镜像导入

```
# 出版方递来的 tar.gz 约 3.6GB;sha256 随件,先验后导
incus image import pi-rs-runtime-agent-20261015-0659.tar.gz \
  --alias pi-rs-runtime-agent-20261015-0659
```

- 版本契约:每次出版双别名,版本别名 `pi-rs-runtime-agent-<ts>` + 浮动 `pi-rs-agent-current`;fingerprint/sha256 随件出 VERSION 清单。
- 消费方验:`incus image list | grep agent`;摘要不符拒导。

## 3. 起影子实例

```
incus launch pi-rs-runtime-agent-20261015-0659 haoxuan-agent-1
sleep 25   # 首启:acpsup systemd 自起 + 键自生(无手工注入)
incus exec haoxuan-agent-1 -- systemctl is-active acpsup   # = active
```

- 键提取(唯一一次手工面;后续批改为网关铸造):
  ```
  incus exec haoxuan-agent-1 -- cat /var/lib/acpsup/token
  ```
- 对外引出(网关形态是本机容器,可只引到宿主回环/尾网,按你们的面定):
  ```
  incus config device add haoxuan-agent-1 acp proxy \
    listen=tcp:10.10.10.16:7663 connect=tcp:127.0.0.1:7663
  ```

## 4. 网关接线语义:与现役同形

- acpsup 在容器内 127.0.0.1:7663;端点 /health /session/new /session/prompt /session/model /session/resume /events /permission /file /vnc;Bearer 鉴权。
- 网关(Go)对它的调用即「容器内 agent 壳」的 HTTP 面:桥侧行为不变,镜像内组件零改动。
- 会话 cwd 白名单 `/srv/work/<案件>` 前缀(R5 收紧:去 /tmp 调试遗留,共识 room/hx-arch seq49;ACPSUP_CWD_ALLOW env 可扩);前缀匹配后 EvalSymlinks 防逃逸。持久卷建议挂 `/srv/work/`(案件工作目录)与 `/root/.pi-rs`(resume 会话文件),卷寿=案件。

## 5. 验收面:影子跑过闸标准

- 出版方验收脚本:`scripts/smoke-agent-base.sh`(root+ubuntu 双视角;断网自证/版本面/五面孔/VNC 栈/实跑;40+28 项)。
- E2E 最小集:三后端(claude/codex/pi)`/session/new`+`/session/prompt` 回环;claude 换模 ds-cc-flash(重建道 {ok,rebuilt});`GET /vnc?sessionId=` 升级后 RFB 003.008 横幅。
- 语义在册:换模 claude=重建道(resume 续接),codex=set 直通;会话空闲 30 分钟逐出(逐出后 /vnc 404 属预期)。
- 常驻桌面(2026-10-15 补面批,desktop 组):三 unit `xvfb99`/`xfce-desktop`/`x11vnc99` 自起,`systemctl is-active` 三绿 + X99 套接字 + 5900 回环 RFB 横幅为过闸项;**VncPanel 主道 = b 道 `GET /vnc?display=desktop`**(WS 桥,同 7663 端点同键权同 binary 子协议;RFB 鉴权口令先经 admin `GET /vnc/desktop` 取 {password});a 道 proxy device 直连 127.0.0.1:5900 备用(原生 RFB 客户端)。按需会话栈(:100-:131)保留为回退道。桌面里浏览器不预启,agent 按需起(agent spawn env 已注 DISPLAY=:99+XAUTHORITY,agent 起的 chrome 上桌面可见)。
- 单 agent 实例(一 agent 一容器):`incus config set <实例> environment.ACPSUP_AGENTS=pi`(逗号/空格分隔多名;未设=全量;未注册名=启动硬错)。

## 6. 已知边界:消费方须知

- 容器内 kill 族 EACCES(宿主安全策略):进程回收全走自退道(acpsup 内建;勿引入依赖信号杀进程的编排逻辑)。
- `incus publish` 压缩期实例冻结约 10 分钟(固有窗口;出版方发起时预告)。
- 凭证不烤镜像:token/keys.json 首启自生, publish 前由出版方删净;消费方镜像里永远无键。桌面凭证同律:`/var/lib/desktop/` 下 X 授权与 VNC 口令由 `desktop-auth-gen` 首启自生,publish 前一并删净。
- 尾网可达性:容器内模型推理走 10.10.10.9:8317(尾网),宿主必须常驻尾网。

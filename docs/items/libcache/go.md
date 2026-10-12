# Go 库缓存:模块预热

> 渗透/代理/协议/AD/PE 向 Go 库字节构建期写入模块缓存,断网 `go build` 直编 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh go`

## 版本

- 19 个库在构建日由 `GOFLAGS=-mod=mod go mod tidy` 解析。
- 精确版本写回 `/opt/go-prewarm/go.mod` 与 `go.sum`。
- 锁文件即锁定版本,已入库 `scripts/lock/go/`(go.mod 与 go.sum)。
- 有锁时用 `GOFLAGS=-mod=mod go build` 消费。
- 再生执行 `scripts/sync-locks.sh`。
- pspy 与 go-winres 由 pins.sh 锁定版本。
- `GO_PIN[github.com/dominicbreuker/pspy]` = v1.2.1。
- `GO_PIN[github.com/tc-hib/go-winres]` = v0.3.3。
- 这两个命令经 go_install_pin 安装。解析日 2026-10-10。
- 升级:执行 `scripts/resolve-pins.sh`,再在有网阶段重跑本组。

## 来源与安装

- 各库官方仓经 `GOPROXY`。
- common.sh 里 `GOPROXY` 的默认值是 `https://goproxy.cn,direct`。
- `GOSUMDB=sum.golang.google.cn`。
- 脚本:`scripts/install-libcache.sh` 的 `install_go`。
- 预热工程是 `/opt/go-prewarm`。
- go.mod 声明 `go 1.23`。
- main.go 以 blank-import 引入 19 个库。
- `go mod tidy` 把字节写入模块缓存。
- pspy 与 go-winres 以命令身份执行 `go install`,同时把模块写入缓存。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/go/pkg/mod | GOMODCACHE,库字节 |
| /opt/go-prewarm | 预热工程与锁文件,兼作离线冒烟样例 |
| /opt/go/bin/pspy、/opt/go/bin/go-winres | 命令件,链到 /usr/local/bin/ |

## 配置

- 运行期发现靠 per-user go env 文件。
- `install-compilers.sh` 的 golang 组在早退之前直接写该文件。
- root 与 ubuntu 各一份 `~/.config/go/env`。
- 非登录 shell 也读这个文件。
- 文件内容:`GOPROXY=off`、`GOSUMDB=sum.golang.google.cn`、`GOPATH=/opt/go`、`GOMODCACHE=/opt/go/pkg/mod`。
- 机制分层见 [offline.md](../../offline.md) 第 1 节与第 3 节。

## 离线行为

- 支持:关闭 eth0 后,`cd /opt/go-prewarm && go build .` 退出码 0。
- 支持:拉取未缓存的模块时立即返回 `module lookup disabled by GOPROXY=off`。
- 在线拉取需要显式覆盖 `GOPROXY=https://goproxy.cn,direct`。
- 构建脚本经 common.sh 自动带上该覆盖。

## 限制

- `go install` 只适合带 main 的命令。
- 库必须用 `go mod tidy` 解析进缓存。
- go-winres 是命令,不是库。
- 把它 import 进预热清单时,`go build` 报 `is a program`。
- go-winres 已改为 `go install`,不在预热 import 清单里。
- pspy 的仓名是小写 dominicbreuker。
- 大写仓名会被 go 拒绝。
- GOTOOLCHAIN 的下载走 GOPROXY。
- 离线时 GOTOOLCHAIN 的下载立即失败。
- 工具链本体与 go env 的写入面见 [golang 册](../compilers/golang.md)。

## 参见

- [offline.md](../../offline.md)
- [golang 册](../compilers/golang.md)

## rctl 面,机器行

- rctl: pspy kind=tool path=/usr/local/bin/pspy env=工具环境 note=无 root 进程刺探(GO_PIN 单独锁定,实装在 /opt/go/bin)

## 成员清单

19 个库加 2 个命令,以脚本 `install_go` 为准。

| 类 | 成员 |
|---|---|
| 跳板/代理 | armon/go-socks5、elazarl/goproxy、hashicorp/yamux、quic-go/quic-go、xtaci/smux、golang.org/x/net/proxy |
| 密码/系统 | golang.org/x/crypto/ssh、golang.org/x/sys/unix |
| CLI 骨架/配置 | spf13/cobra、gopkg.in/yaml.v3 |
| 协议 | google/gopacket、miekg/dns、refraction-networking/utls |
| AD/横向 | go-ldap/ldap/v3、hirochachacha/go-smb2、jcmturner/gokrb5/v8/client、masterzen/winrm |
| PE/资源 | klauspost/compress/zstd、saferwall/pe |
| 命令(go_install_pin 锁定版本) | pspy(dominicbreuker/pspy,GO_PIN v1.2.1)、go-winres(tc-hib/go-winres,GO_PIN v0.3.3) |

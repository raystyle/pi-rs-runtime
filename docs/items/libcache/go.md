# Go 库缓存(模块预热)

> 渗透/代理/协议/AD/PE 向 Go 库字节构建期钉进模块缓存,断网 `go build` 直编 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh go`

- **版本钉**:构建日 `GOFLAGS=-mod=mod go mod tidy` 解析最新,精确版本写回 `/opt/go-prewarm/go.mod` 与 `go.sum`(锁文件即钉版,不入仓);pspy、go-winres 两个命令 `go install @latest` 未钉。升级=有网阶段重跑本组
- **来源与安装**:各库官方仓经 `GOPROXY`(common.sh 默认 `https://goproxy.cn,direct`)与 `GOSUMDB=sum.golang.google.cn`;脚本面 `scripts/install-libcache.sh` `install_go()`——预热工程 `/opt/go-prewarm`(go.mod 声明 `go 1.23`,main.go blank-import 19 库)`go mod tidy` 把字节钉进模块缓存,pspy/go-winres 以命令身份 `go install` 顺带缓存模块
- **落点**:`/opt/go/pkg/mod`(GOMODCACHE,库字节);`/opt/go-prewarm`(预热工程与锁文件,兼作离线冒烟样例);命令件 `/opt/go/bin/{pspy,go-winres}` 链 `/usr/local/bin/`
- **配置与缓存**:运行期发现靠 per-user go env 文件(`install-compilers.sh golang` 组早退前直写,root+ubuntu 各一份 `~/.config/go/env`,非登录 shell 也读):`GOPROXY=off GOSUMDB=sum.golang.google.cn GOPATH=/opt/go GOMODCACHE=/opt/go/pkg/mod`;机制分层见 [offline.md](../../offline.md) §1/§3
- **离线行为**:✅ 断网构建实证(断网冒烟 78/0 轮):`ip link set eth0 down` 后 `cd /opt/go-prewarm && go build .` 退 0;✅ 拉新件瞬时 `module lookup disabled by GOPROXY=off`(五生态快失败轮);在线拉件需 `GOPROXY=https://goproxy.cn,direct` 显式覆盖(构建脚本经 common.sh 自动带)
- **坑与留痕**:`go install` 只适合带 main 的命令,库必须 `go mod tidy` 解析进缓存;go-winres 是命令不是库,import 进预热清单会让 `go build` 报 "is a program"(已剔出改 go install);pspy 仓名已改小写 dominicbreuker(大写被 go 拒);GOTOOLCHAIN 下载同样走 GOPROXY,离线期快失败([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));工具链本体与 go env 写入面的坑见 [../compilers/golang.md](../compilers/golang.md)

成员清单(19 库 + 2 命令,以脚本 `install_go()` 为准):

| 类 | 成员 |
|---|---|
| 跳板/代理 | armon/go-socks5、elazarl/goproxy、hashicorp/yamux、quic-go/quic-go、xtaci/smux、golang.org/x/net/proxy |
| 密码/系统 | golang.org/x/crypto/ssh、golang.org/x/sys/unix |
| CLI 骨架/配置 | spf13/cobra、gopkg.in/yaml.v3 |
| 协议 | google/gopacket、miekg/dns、refraction-networking/utls |
| AD/横向 | go-ldap/ldap/v3、hirochachacha/go-smb2、jcmturner/gokrb5/v8/client、masterzen/winrm |
| PE/资源 | klauspost/compress/zstd、saferwall/pe |
| 命令(go install @latest) | pspy(dominicbreuker/pspy)、go-winres(tc-hib/go-winres) |

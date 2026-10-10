# Go 工具链

> Go 编译器与黄金三件(dlv/gopls/golangci-lint)+ 库预热 ｜ 状态:已装 ｜ 组:`install-compilers.sh golang` + `install-libcache.sh go`

- **版本钉**:`GOLANG_VERSION=1.27.1`(lib/common.sh;两个维护线内取最新),tarball sha256 实时取 golang.google.cn/dl/?mode=json 校验
- **来源与安装**:南大镜像(`GO_DOWNLOAD`)tarball → `/usr/local/go`,`go`/`gofmt` 链 /usr/local/bin;黄金三件 `go install` 进 /opt/go/bin 再链出
- **落点**:`/usr/local/go`;`/usr/local/bin/go`;`/opt/go/bin/{dlv,gopls,golangci-lint,pspy,go-winres}`
- **配置与缓存**:go env per-user 文件 root+ubuntu 各一份(`~/.config/go/env`):`GOPROXY=off GOSUMDB=sum.golang.google.cn GOPATH=/opt/go GOMODCACHE=/opt/go/pkg/mod`;库预热工程 `/opt/go-prewarm`(代理/协议/AD/PE 库清单,go mod tidy 钉版进模块缓存)
- **离线行为**:✅ 断网 `cd /opt/go-prewarm && go build .` 实证;拉新件瞬时 `module lookup disabled by GOPROXY=off`;在线拉件需 `GOPROXY=https://goproxy.cn,direct` 显式覆盖(构建脚本经 common.sh 自动带)
- **坑与留痕**:go env 写入必须放 golang 组早退前且直写文件(早期用 `go env -w` 且在早退后,增量重跑刷不上);ubuntu 需要自己的 go env 文件(root 0700 家目录帮不到);go-winres 是命令不是库,import 进预热清单会让 `go build` 报 "is a program";pspy 仓名已改小写 dominicbreuker(大写被 go 拒);GOTOOLCHAIN 下载走 GOPROXY,离线期同样快失败([ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md))

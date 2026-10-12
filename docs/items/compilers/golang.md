# Go 工具链

> Go 编译器与黄金三件(dlv/gopls/golangci-lint)+ 库预热 ｜ 状态:已装 ｜ 组:`install-compilers.sh golang` + `install-libcache.sh go`

## 版本

- `GOLANG_VERSION=1.27.1`(`lib/common.sh`;两个维护线内取最新)。
- tarball 的 sha256 实时取 `golang.google.cn/dl/?mode=json` 校验。

## 来源与安装

- 南大镜像(`GO_DOWNLOAD`)的 tarball 解到 `/usr/local/go`。
- `go` 与 `gofmt` 链到 `/usr/local/bin`。
- 黄金三件经 `go install` 进入 `/opt/go/bin`,再链出。

## 文件

| 路径 | 内容 |
| --- | --- |
| /usr/local/go | Go 工具链 |
| /usr/local/bin/go | go 入口 |
| /opt/go/bin/dlv | dlv |
| /opt/go/bin/gopls | gopls |
| /opt/go/bin/golangci-lint | golangci-lint |
| /opt/go/bin/pspy | pspy |
| /opt/go/bin/go-winres | go-winres |

## 配置

- root 与 ubuntu 各有一份 `~/.config/go/env`。
- 该文件写入 `GOPROXY=off`、`GOSUMDB=sum.golang.google.cn`、`GOPATH=/opt/go`、`GOMODCACHE=/opt/go/pkg/mod`。
- 库预热工程在 `/opt/go-prewarm`,清单覆盖代理、协议、AD、PE。
- `go mod tidy` 把锁定版本写入模块缓存。

## 离线行为

- 支持:关闭 eth0 后,`cd /opt/go-prewarm && go build .` 可完成。
- 支持:拉新件立即返回 `module lookup disabled by GOPROXY=off`。
- 在线拉件需要显式覆盖 `GOPROXY=https://goproxy.cn,direct`。构建脚本经 common.sh 自动带上该值。

## 限制

- go env 的写入必须放在 golang 组早退之前,并且直接写文件。
- ubuntu 需要自己的 go env 文件。root 的家目录是 0700,不能代替 ubuntu 的那一份。
- go-winres 是命令,不是库。把它 import 进预热清单时,`go build` 报 "is a program"。
- pspy 仓库名是小写 `dominicbreuker`。大写名称会被 go 拒绝。
- GOTOOLCHAIN 的下载走 GOPROXY。离线期同样立即失败。

## 参见

- [offline.md](../../offline.md)
- [go 库缓存](../libcache/go.md)

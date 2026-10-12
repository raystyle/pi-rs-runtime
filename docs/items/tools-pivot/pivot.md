# 代理与隧道工具集

> 内网代理跳板与隧道:gost、frps、frpc、wstunnel、rathole、bore ｜ 状态:已装 ｜ 组:`install-tools.sh pivot`

## 版本

- 解析日 2026-10-10。升级:运行 `scripts/resolve-pins.sh` 后删对应产物再重跑本组(`have` 判装跳过意味着重跑不升级)。

| 件 | 锁定方式 |
| --- | --- |
| gost | `GO_PIN[github.com/go-gost/gost/cmd/gost]`=v0.0.0-20261007023108-0793f4730f8d(无 tag 仓库锁定 HEAD 伪版本) |
| frps / frpc | `FRP_VERSION`=v0.71.0(未写锁定版本回退 api.github.com latest) |
| wstunnel | `GIT_PIN[erebe/wstunnel]` 锁定 sha;`cargo install --git --rev` |
| rathole | `CRATE_PIN[rathole]`=0.5.0;git 退路锁定 `GIT_PIN[rathole-org/rathole]` sha |
| bore | `CRATE_PIN[bore-cli]`=0.6.0 |

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_pivot`。
- Go 栈模块经 goproxy.cn(common.sh `GOPROXY`)。
- Rust 栈 crate 经 /opt/cargo/config.toml 的 sparse 索引(默认 rsproxy.cn;`CRATES_INDEX` 可覆盖)。
- frp tarball 直连 GitHub;wstunnel 与 rathole 的 git 源经 GITHUB_MIRROR(自锁定版本起)。

## 文件

| 件 | 来源 | 安装方式 |
| --- | --- | --- |
| gost | [go-gost/gost](https://github.com/go-gost/gost) v3(失败退 ginuerzh/gost) | go_install_pin 锁定伪版本;产物 /opt/go/bin/gost 链出 |
| frps | [fatedier/frp](https://github.com/fatedier/frp) releases | 按 FRP_VERSION 下 release tarball;`install -m755` 直落 /usr/local/bin;架构自动取 amd64/arm64 |
| frpc | 同上(同一 tarball) | 同上,直落 /usr/local/bin |
| wstunnel | [erebe/wstunnel](https://github.com/erebe/wstunnel) | 不在 crates.io;`cargo install --git --locked --rev` 锁定 sha;产物 /opt/cargo/bin 链出 |
| rathole | [rathole-org/rathole](https://github.com/rathole-org/rathole) | cargo_install_pin 锁定 0.5.0;失败退 git 锁定 sha;产物 /opt/cargo/bin 链出 |
| bore | [ekzhang/bore](https://github.com/ekzhang/bore) | cargo_install_pin 锁定 0.6.0(crate 名 bore-cli,二进制 bore);产物 /opt/cargo/bin 链出 |

- Go 产物落 /opt/go/bin(`GOPATH=/opt/go`)再 `ln -sf` 到 /usr/local/bin。
- Rust 产物落 /opt/cargo/bin(`CARGO_HOME=/opt/cargo`;~/.cargo 是 /opt/cargo 的软链)再链 /usr/local/bin。
- frps 与 frpc 例外:直落 /usr/local/bin。
- 六件入口名同件名。

## 配置

- 无。不写配置、不做 wrapper、不固化缓存。
- 构建期 go/cargo 在线面由 lib/common.sh 提供(导出 GOPROXY、CARGO_NET_OFFLINE=false);运行期离线默认见 [offline.md](../../offline.md) 第 4 节。

## 离线行为

- 未验证:server 端起 listener、client 连内网目标均不依赖外网;断外网(内网可达)下可用;eth0 全断退化为 loopback 对连。
- bore 默认公网服务器 bore.pub 这类天然面向外网的用法断网不可用,属设计(见 [offline.md](../../offline.md) 边界规定)。
- 验证:关闭 eth0 后 `gost -V && frps -v && bore --version` 退出码 0。

## 限制

- frp 不走 go install:go.mod 带 replace 被拒、源码 build 又缺 web/dist(embed 失败),改 release 预编译。
- 注释「arm 机器改 FRP_ARCH」是旧规定;代码已自动按架构取值,以代码为准。
- rathole 锁定 0.5.0;其老锁在新 rustc 上可能编不过,cargo_install_pin 失败则退 git 锁定 sha 退路。
- 升级任一件需先删 /opt/go/bin 或 /opt/cargo/bin 对应产物再重跑本组。
- gost 曾由版本锁定批直装进 /opt/go/bin(不经本组循环),组尾链接循环没再跑致 /usr/local/bin 缺链、非登录 shell 不可用;重跑本组即愈(链接循环按 $gobin 存在性无条件链)。

## 参见

- [offline.md](../../offline.md)
- [docs/params.md](../../params.md)

## rctl 收录行

- rctl: gost kind=tool path=/usr/local/bin/gost note=代理跳板(go-gost v3)
- rctl: frps kind=tool path=/usr/local/bin/frps note=frp 服务端
- rctl: frpc kind=tool path=/usr/local/bin/frpc note=frp 客户端
- rctl: wstunnel kind=tool path=/usr/local/bin/wstunnel note=WebSocket 隧道
- rctl: rathole kind=tool path=/usr/local/bin/rathole note=Rust 隧道
- rctl: bore kind=tool path=/usr/local/bin/bore note=TCP 隧道(默认公网服务器)

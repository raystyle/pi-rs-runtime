# 代理与隧道工具集(pivot 组册)

> 内网代理跳板与隧道:gost/frps/frpc/wstunnel/rathole/bore ｜ 状态:已装 ｜ 组:`install-tools.sh pivot`

- **版本钉**:全组未钉——gost `go install @latest`、frps/frpc release latest(api.github.com 实时取 tag)、wstunnel/rathole/bore cargo 未钉;`have` 判装跳过意味「首次装到的那份」,重跑不升级(留痕 [known-issues](../../known-issues.md) 版本未钉节)
- **来源与安装**:`install-tools.sh` `install_pivot` 段;Go 栈模块经 goproxy.cn(common.sh `GOPROXY`),Rust 栈 crate 经 /opt/cargo/config.toml 的 sparse 索引(默认 rsproxy.cn,`CRATES_INDEX` 可覆盖);frp tarball 与 wstunnel/rathole 的 git 源直连 GitHub,本组不经 `GITHUB_MIRROR`。成员表(6 件,与脚本对账):

  | 件 | 来源 | 安装方式 |
  |---|---|---|
  | gost | [go-gost/gost](https://github.com/go-gost/gost)(v3;失败退回 [ginuerzh/gost](https://github.com/ginuerzh/gost)) | `go install …/cmd/gost@latest` → /opt/go/bin/gost 链出 |
  | frps | [fatedier/frp](https://github.com/fatedier/frp) releases | api.github.com 取 latest tag 下 tarball,`install -m755` 直落 /usr/local/bin;架构按 `dpkg --print-architecture` 自动取 amd64/arm64 |
  | frpc | 同上(同一 tarball) | 同上,直落 /usr/local/bin |
  | wstunnel | [erebe/wstunnel](https://github.com/erebe/wstunnel) | 不在 crates.io,`cargo install --git … --locked` → /opt/cargo/bin 链出 |
  | rathole | [rathole-org/rathole](https://github.com/rathole-org/rathole) | `cargo install rathole`(不带 --locked),失败退 `cargo install --git` 主干 → /opt/cargo/bin 链出 |
  | bore | [ekzhang/bore](https://github.com/ekzhang/bore) | `cargo install bore-cli --locked`(crate 名 bore-cli,二进制 bore) → /opt/cargo/bin 链出 |

- **落点**(批量机制):Go 产物落 /opt/go/bin(`GOPATH=/opt/go`)再 `ln -sf` 到 /usr/local/bin;Rust 产物落 /opt/cargo/bin(`CARGO_HOME=/opt/cargo`;链接循环用 root 的 ~/.cargo/bin 做存在判断,~/.cargo 是 /opt/cargo 的软链)再链 /usr/local/bin;frps/frpc 例外,直落 /usr/local/bin。六件入口名同件名
- **配置与缓存**:无——不写配置、不做 wrapper、不固化缓存;构建期 go/cargo 在线面由 lib/common.sh 提供(导出 `GOPROXY`、`CARGO_NET_OFFLINE=false`),运行期离线默认见 [offline.md](../../offline.md) §4
- **离线行为**:☐ [推断:] server 端起 listener、client 连内网目标均不依赖外网,断外网(内网可达)下可用,eth0 全断退化为 loopback 对连;bore 默认公网服务器 bore.pub 这类天然面向外网的用法断网不可用,属设计([offline.md](../../offline.md) 边界同口径)。发布门禁断网冒烟 78/0 通过(覆盖面含渗透工具面,逐件明细未归档)。建议验证:`ip link set eth0 down` 后 `gost -V && frps -v && bore --version` 退 0
- **坑与留痕**:frp 不走 go install——go.mod 带 replace 被拒、源码 build 又缺 web/dist(embed 失败),改 release 预编译(脚本注释实证);注释「arm 机器改 FRP_ARCH」是旧口径,代码已自动按架构取值,以代码为准;rathole 0.5.0 老锁在新 rustc 上编不过,故不带 --locked 并备 git 主干退路;升级任一件需先删 /opt/go/bin 或 /opt/cargo/bin 对应产物再重跑本组

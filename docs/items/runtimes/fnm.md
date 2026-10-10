# fnm(Node 版本管理器)

> fnm 多版本 node 管理器,预装 18/20/22/24 四条线 ｜ 状态:已装 ｜ 组:`install-runtimes.sh fnm`

- **版本钉**:fnm 本体 pins.sh 钉版(`CRATE_PIN[fnm]`=1.39.0,cargo_install_pin 带 `--locked`;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh(构建期 crates 索引走 rsproxy,lib/common.sh `CRATES_INDEX`);node 各线 `FNM_NODE_VERSIONS="18 20 22 24"`(lib/common.sh,大版本内取最新)
- **来源与安装**:[Schniz/fnm](https://github.com/Schniz/fnm) 经 cargo 装(`RUSTUP_HOME=/opt/rustup`、`CARGO_HOME=/opt/cargo`,依赖 rust 组先就位);node 二进制 `fnm install --node-dist-mirror "$NODE_MIRROR"` 逐线装(npmmirror);默认版本取 `fnm ls` 里 `sort -uV` 最新(24 线),`fnm default` 带 `|| true` 不致命
- **落点**:fnm 本体 `/opt/cargo/bin/fnm`(脚本不链 /usr/local/bin);node 各版本 `~/.local/share/fnm/node-versions/<版本>/installation/`(构建期只填 root 的);`/etc/profile.d/fnm.sh` 登录面:PATH 加 `$HOME/.local/share/fnm` + `eval "$(fnm env)"`;**不改 /usr/local/bin**——系统 node 仍是 /opt/node 的 24.21.0(全局 npmrc/bun/tsc 都挂那个 prefix),项目切版本用 `fnm use` / `fnm exec`
- **配置与缓存**:尾部兜底循环给 root+ubuntu 两侧各 fnm 版本写 prefix 级 `etc/npmrc` 离线键(`offline=true` + `fetch-retries=0` + mintimeout 500/maxtimeout 1000,与 /opt/node 同形;先 sed 清旧键再追加,幂等)
- **离线行为**:☐ fnm 各版本的 `npm install` 离线快失败 [推断:prefix npmrc 与 /opt/node 逐键同形,机制实证见 [node 册](node.md),无 fnm 版本专属断网实证记录];✅ js-lab 固化包经 libcache 组软链进 fnm 各版本 prefix 的 `lib/node`(脚本循环盖 /root 的 fnm 目录),断网 require 面与系统 node 同([offline.md](../../offline.md) §1 登记「各 node prefix」,断网冒烟覆盖 node require)
- **坑与留痕**:首轮 install-all 时 [node 册](node.md) 里的 fnm npmrc 顺写必落空(RUNTIMES_ALL 顺序 node 先于 fnm,版本目录尚不存在,grok G)——本组尾部兜底循环是修正,且多盖 ubuntu 视角;[known-issues](../../known-issues.md) 旧口径「fnm 经 root ~/.cargo 安装再链 /usr/local/bin」与现行脚本不符(现行 CARGO_HOME=/opt/cargo、未链 /usr/local/bin,以脚本为准)

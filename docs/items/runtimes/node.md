# Node.js 运行时

> Node.js LTS 基座 + npm 全局件(tsc/prettier/eslint/dotnetjs)与 corepack(pnpm/yarn) ｜ 状态:已装 ｜ 组:`install-runtimes.sh node`

## 版本

- `NODE_VERSION=24.21.0`(`lib/common.sh`;当前 Active LTS Krypton)。
- tarball 经 npmmirror 的 `SHASUMS256.txt`,用 `sha256sum -c` 校验。
- typescript、prettier、eslint、dotnetjs 均为 npm 全局安装,未锁定版本。pins.sh 无 npm 映射。
- corepack 的 pnpm 与 yarn 随 node 自带。

## 来源与安装

- 二进制来自 [nodejs.org](https://nodejs.org),经 npmmirror 的 `NODE_MIRROR`(`registry.npmmirror.com/-/binary/node`)。
- `tar --strip-components=1` 解进 `/opt/node`;registry 指向 npmmirror;黄金件:`npm install -g typescript prettier eslint`。
- dotnetjs 来自 [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs),是 .NET Framework BCL 的 JS 实现,用于分析与复现 .NET 行为。
- `COREPACK_NPM_REGISTRY` 指向 npmmirror 后执行 `corepack enable`。

## 文件

- prefix 是 `/opt/node`。
- `/usr/local/bin` 软链出 node、npm、npx、tsc、tsserver、prettier、eslint。
- 全局件本体在 `/opt/node/lib/node_modules`,bin 落在 `/opt/node/bin`。
- corepack 的 pnpm 与 yarn shim 也在 `/opt/node/bin`。脚本不把它们链到 `/usr/local/bin`。
- dotnetjs 只安装,不链出。安装失败不致命(`|| echo`)。

## 配置

- prefix 级全局 npmrc 是 `/opt/node/etc/npmrc`,对所有用户生效。只写 root 的 `~/.npmrc` 不够。
- registry 由 `npm config set --location=global` 写入。
- `disturl=https://npmmirror.com/mirrors/node` 与 `electron_mirror=https://npmmirror.com/mirrors/electron/` 直接写进文件。
- npm 11 的 `config set` 拒绝这两个键。
- npm 把任意键以 `npm_config_*` 传给生命周期脚本。node-gyp 与 electron 按这个方式读取。
- 离线双保险是 `offline=true` 与 `fetch-retries=0`,并写 mintimeout 500、maxtimeout 1000。
- 幂等写法:先用 sed 清掉旧键,再追加;同形 npmrc 顺写给已经存在的 fnm 各版本。见 [fnm 册](fnm.md)。
- 构建期在线面由 common.sh 导出 `NPM_CONFIG_OFFLINE=false` 与 `NPM_CONFIG_FETCH_*`。环境变量恒优先于配置文件。

## 离线行为

- 支持:断网 `npm install <新件>` 在亚秒内返回 `ENOTCACHED`。
- `offline=true` 走 cache-only。npm cache 已被 clean-image 清掉,必未命中。
- `fetch-retries=0` 兜住绕过 cache 的解析路径。默认重试会挂起 70 秒以上。
- 验证:关闭 eth0 后,`mkdir -p /tmp/nt && cd /tmp/nt && npm install lodash` 立即 `ENOTCACHED`。
- 支持:js-lab 固化包。关闭 eth0 后,`node -e "require('node-forge')"` 可用。
- libcache 组把包软链进 `<prefix>/lib/node`。`Module.globalPaths` 只认这条路径。机制见 [offline.md](../../offline.md) 第 1 节。
- 同一包的 `npm install` 仍然 `ENOTCACHED`。两条消费路径语义不同。
- corepack 的 pnpm 与 yarn 不读 npmrc。规定不给它们写默认离线。见 [offline.md](../../offline.md) 第 4 节。

## 限制

- `npm --prefix` 会连 prefix 级 npmrc 一起丢掉。这是 npm 的行为。项目内用法才吃到该 npmrc。见 [offline.md](../../offline.md) 第 4 节。
- `sha256sum -c` 的校验行必须写绝对路径。裸文件名按 CWD 解析,裸写会导致安装失败。
- npmrc 在 `/opt/node` 内。node 升级执行 `rm -rf /opt/node` 之后,脚本每次重写把它补回。
- 该配置写在早退判据之外,所以幂等成立;首次 install-all 时 fnm 的版本目录还不存在,node 组的顺写落空。fnm 组尾部补写。

## 参见

- [offline.md](../../offline.md)
- [fnm 册](fnm.md)

## rctl 收录行

- rctl: npm kind=runtime path=/usr/local/bin/npm note=node 包管理器(face)
- rctl: npx kind=runtime path=/usr/local/bin/npx
- rctl: tsc kind=runtime path=/usr/local/bin/tsc note=typescript 编译器(npm 全局件)

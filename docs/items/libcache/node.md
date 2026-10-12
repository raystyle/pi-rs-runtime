# Node 库缓存:js-lab

> 加密/PKI/反混淆/解析向 24 个纯 JS/wasm 包固化进 /opt/js-lab,断网裸 `require` 直用 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh node`

## 版本

- 24 个直接依赖按 `NPM_PIN` 精确锁定版本;package.json 由 pins.sh 生成;缺少锁定版本即失败;传递闭包锁在 `scripts/lock/node/package-lock.json`;构建消费走 `npm ci`;再生执行 `scripts/sync-locks.sh`。
- 升级是 `scripts/resolve-pins.sh` 与 `scripts/sync-locks.sh` 两步。

## 来源与安装

- npmjs 经 `NPM_REGISTRY`;common.sh 里该变量的默认值是 npmmirror;脚本:`scripts/install-libcache.sh` 的 `install_node`;工程目录是 `/opt/js-lab`;有锁时走 `npm ci`,锁文件在 `scripts/lock/node/`;无锁时在构建日解析,并打印「未锁」。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/js-lab/node_modules | 24 个直接依赖加传递依赖;[offline.md](../../offline.md) 第 1 节登记 161 个包 |
| /usr/local/bin | 本组无入口;纯库缓存 |

## 配置

- `require` 不查 npm 全局 node_modules。
- Module.globalPaths 只认 `~/.node_modules`、`~/.node_libraries`、`<prefix>/lib/node`。
- js-lab 的每个包软链进各 node prefix 的 `lib/node`,供裸 `require`。
- `lib/node` 默认不存在,需要 `install -d` 创建;同一批包也软链进 `lib/node_modules`,供 `npm -g` 与 bin。
- 覆盖范围是 /opt/node,以及 fnm 各版本 `/root/.local/share/fnm/node-versions/*/installation/`。
- `/etc/profile.d/jslab.sh` 写 `NODE_PATH=/opt/js-lab/node_modules`。
- 该变量只是登录 shell 的备份;机制见 [offline.md](../../offline.md) 第 1 节与第 3 节。

## 离线行为

- 支持:关闭 eth0 后,`node -e "require('node-forge')"` 退出码 0;断网冒烟清单包含这条 node require;fnm 各版本经各自的 `lib/node` 链接,形态相同,同样可用;支持:断网 `npm install <新件>` 在亚秒内返回 ENOTCACHED;prefix 级 npmrc 写 `offline=true` 与 `fetch-retries=0`;该 npmrc 由 install-runtimes.sh 的 node 组写入;clean-image 会清掉 npm cache。
- 因此同一包走 `require` 可以离线使用,走 `npm install` 仍然 ENOTCACHED。
- 这两条消费路径语义不同,见 [offline.md](../../offline.md) 第 4 节。

## 限制

- `npm --prefix` 不带上 prefix 级 npmrc;没有该文件时,安装可等待约 70 秒;bun 不读 npmrc;bun 的配置面是 bunfig;corepack 的 pnpm 与 yarn 同样不读 npmrc;这三处不写成默认离线;第一轮时,fnm 的 npmrc 写不上;原因是 node 组先于 fnm 运行,目录还不存在;`install_fnm` 的尾部再写一遍。

## 参见

- [offline.md](../../offline.md)
- [fnm 册](../runtimes/fnm.md)

## 成员清单

24 个依赖,全部为 `"*"`,以脚本 `install_node` 为准。

| 类 | 成员 |
|---|---|
| 证书/PKI | node-forge、pkijs、asn1js、pvtsutils、pvutils |
| 加密/token | crypto-js、jsonwebtoken、libsodium-wrappers |
| 反混淆/AST | @babel/parser、@babel/traverse、@babel/generator、@babel/types、webcrack |
| 解析 | cheerio、fast-xml-parser、protobufjs、js-yaml、iconv-lite |
| 网络/web | ws、express |
| 打包/数据 | jszip、sql.js、pdf-lib、postject |

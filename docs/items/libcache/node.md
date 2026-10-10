# Node 库缓存(js-lab)

> 加密/PKI/反混淆/解析向 24 个纯 JS/wasm 包固化进 /opt/js-lab,断网裸 `require` 直用 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh node`

- **版本钉**:24 个依赖按 `NPM_PIN` 精确钉(package.json 由 pins.sh 生成,缺钉即响),传递闭包再锁进 `scripts/lock/node/package-lock.json`(构建消费走 `npm ci`;再生跑 `scripts/sync-locks.sh`,升级=`resolve-pins.sh`+sync-locks 两件套)
- **来源与安装**:npmjs 经 `NPM_REGISTRY`(common.sh 默认 npmmirror);脚本面 `scripts/install-libcache.sh` `install_node()`——`/opt/js-lab` 工程有锁走 `npm ci`(scripts/lock/node/),无锁才构建日解析并打印「未锁」
- **落点**:`/opt/js-lab/node_modules`(24 直接依赖+传递依赖,[offline.md](../../offline.md) §1 登记 161 包);无 `/usr/local/bin` 入口(纯库缓存)
- **配置与缓存**:运行期发现机制——`require` 不查 npm 全局 node_modules,只认 Module.globalPaths(实证:`~/.node_modules`、`~/.node_libraries`、`<prefix>/lib/node`);故把 js-lab 每个包软链进各 node prefix 的 `lib/node`(裸 require 面;lib/node 默认不存在,要 `install -d`)与 `lib/node_modules`(npm -g/bin 面),覆盖 /opt/node 与 fnm 各版本(`/root/.local/share/fnm/node-versions/*/installation/`);`/etc/profile.d/jslab.sh` 的 `NODE_PATH=/opt/js-lab/node_modules` 只是登录 shell 备份面。机制见 [offline.md](../../offline.md) §1/§3
- **离线行为**:✅ 断网 `require` 实证(node require 在断网冒烟清单):`ip link set eth0 down` 后 `node -e "require('node-forge')"` 退 0(fnm 各版本经各自 lib/node 链同形可用);✅ `npm install <新件>` 断网 ENOTCACHED 亚秒快失败(prefix 级 npmrc `offline=true`+`fetch-retries=0`,install-runtimes.sh node 组写);注意 npm cache 被 clean-image 清掉——js-lab 的包走 `require` 离线可用,走 `npm install` 同一包仍 ENOTCACHED,两条消费路径语义不同([offline.md](../../offline.md) §4)
- **坑与留痕**:`npm --prefix` 会连 prefix 级 npmrc 一起丢(npm 天性,实证 70s 假象,[ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md));bun 不读 npmrc(bunfig 才是它的面)、corepack 的 pnpm/yarn 同理,不钉默认;fnm npmrc 首轮写不上(node 组先于 fnm 跑,目录尚不存在),install_fnm 尾部兜底再写一遍

成员清单(24 依赖,全 `"*"`,以脚本 `install_node()` 为准):

| 类 | 成员 |
|---|---|
| 证书/PKI | node-forge、pkijs、asn1js、pvtsutils、pvutils |
| 加密/token | crypto-js、jsonwebtoken、libsodium-wrappers |
| 反混淆/AST | @babel/parser、@babel/traverse、@babel/generator、@babel/types、webcrack |
| 解析 | cheerio、fast-xml-parser、protobufjs、js-yaml、iconv-lite |
| 网络/web | ws、express |
| 打包/数据 | jszip、sql.js、pdf-lib、postject |

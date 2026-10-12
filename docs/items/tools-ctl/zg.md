# zg

> zvec-grep 语义检索引擎。rctl search 的向量与 fts 混排腿,带 ripgrep 面与 BM25 ｜ 状态:已装 ｜ 组:`install-tools.sh ctl`

## 版本

- pins.sh `GIT_PIN[zvec-ai/zvec-grep]` 锁定上游 HEAD。
- CLI 面由 `install_zg` 的自检把关。
- `ZG_MODEL_REF` = `local/qwen3-embedding-0.6b`。
- 格式是 Q8_0 GGUF。
- 语种是中文优先的多语模型。
- 体积是 610M。
- `ZG_MODEL_SHA256` 是校验锚。
- 升级:重跑 `scripts/resolve-pins.sh` 更换锁定版本,再执行 ctl 组。
- 构建版本标记变化时,自动重建索引。

## 来源与安装

- 脚本:`scripts/install-tools.sh` 的 `install_zg`。
- `clone_pin` 到 `/opt/zvec-grep-src`。
- 构建命令是 `CARGO_NET_OFFLINE=false cargo build --release -p zg`。
- llama.cpp 与 ort 的链接需要 cmake 与 gcc。
- 这是构建期在线面。见 [offline.md](../../offline.md)。
- 安装 `/usr/local/bin/zg`。
- `libzvec_c_api.so` 装入 `/usr/local/lib`,然后 `ldconfig`。
- 模型由 zg 自己的下载器获取。
- 标记文件由 zg 自己维护。
- 模型先进入烤库,再做 sha256 校验。
- 幂等判据是二进制存在,并且 `/var/lib/rctl/.zg-built-sha` 等于当前锁定版本。

## 文件

- 二进制是 `/usr/local/bin/zg`。
- 共享库是 `/usr/local/lib/libzvec_c_api.so`。
- 缺少该库时 zg 起不来。它与二进制一起安装。
- 模型烤库是 `/opt/zg-models`。
- 它属于构建日快照,与 trivy-db 同一类。
- `/root/.zvec-grep/config.json` 与 `/home/ubuntu/.zvec-grep/config.json` 形状相同。
- 内容是 `{"defaults":{"embedding":"local/qwen3-embedding-0.6b"},"version":1}`。

## 配置

- rctl 的语义腿始终带 `--model-cache /opt/zg-models`。
- `RCTL_ZG_PATH` 为 `0` 时禁用 zg。
- 禁用后 rctl 回退到词面。
- 索引写在检索目录内的 `.zvec-grep`。
- rctl 的镜像在 `/var/lib/rctl/semantic/`。

## 离线行为

- 支持。
- 关闭 eth0 后,fts 与 vector 查询命中,耗时为秒级。
- 模型与索引在构建期已经在盘上。
- 查询在本地完成,不访问网络。
- 冷索引是构建期的一次性动作。

## 限制

- 查询模式的检索根是当前工作目录。
- 检索根不是位置参数。
- 位置参数会被并进查询词。
- 调用方把当前工作目录设成检索根。
- pi-rs 的 spawn 使用同样的当前工作目录形式。
- config 子命令的形式是 `zg --config …`。
- 旧形式 `zg config …` 已经停用。
- `libzvec_c_api.so` 是伴生共享库。
- 安装二进制时必须同时安装该库,并执行 ldconfig。
- 上游锁定的是 HEAD。
- 对照物是 pi-rs 的 vendored fork。
- 该 fork 含提交 30c3160。
- 该 fork 还含 doc-header 与 per-file-cap 两项修复。
- 锁定的上游 HEAD 不含这两项修复。
- 本用途的检索单元是一行一条微文档,不是源码切块。
- 因此这两项修复不影响本用途。
- pi-rs 的调用位置是 `packages/rs-agent/src/extensions/rust_script/search-tool.ts`。
- 该调用使用 positional 与 `--fts` 两条腿,再用 `--fuse` 融合。
- 词表里没有的新造词由 fts 腿覆盖。
- 例子是 dbg_cli 与 postex。

## 参见

- [rctl.md](rctl.md)
- [offline.md](../../offline.md)

## rctl 收录行

- rctl: zg kind=tool path=/usr/local/bin/zg note=语义检索引擎,rctl search 向量腿

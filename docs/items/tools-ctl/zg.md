# zg

> zvec-grep 语义检索引擎:rctl search 的向量+fts 混排腿(ripgrep 面 + BM25) ｜ 状态:已装 ｜ 组:`install-tools.sh ctl`

- **版本**:pins.sh `GIT_PIN[zvec-ai/zvec-grep]`(上游 HEAD 锁定;CLI 面以 install_zg 自检把门);模型标量 `ZG_MODEL_REF`(local/qwen3-embedding-0.6b,Q8_0 GGUF,中文优先多语,610M)与 `ZG_MODEL_SHA256` 锚;升级=重跑 resolve-pins 更换锁定版本 + 重跑 ctl 组(构建版本标记变化自动重建)
- **来源与安装**:`install-tools.sh install_zg`:clone_pin 源码到 /opt/zvec-grep-src → `CARGO_NET_OFFLINE=false cargo build --release -p zg`(llama.cpp+ort 链要 cmake/gcc;构建期在线面,offline.md 规定)→ 装 /usr/local/bin/zg 与 libzvec_c_api.so 入 /usr/local/lib + ldconfig;模型走 zg 自下载器(标记文件自理)进烤库后 sha256 校验;幂等=二进制在且 /var/lib/rctl/.zg-built-sha==当前锁定的版本
- **文件**:二进制 /usr/local/bin/zg;共享库 /usr/local/lib/libzvec_c_api.so(缺它 zg 起不来,伴生装);模型烤库 /opt/zg-models(构建日快照类资产,同 trivy-db 例);默认模型双家配置 /root/.zvec-grep/config.json 与 /home/ubuntu/.zvec-grep/config.json(同形 {"defaults":{"embedding":"local/qwen3-embedding-0.6b"},"version":1})
- **配置与缓存**:rctl 语义腿恒带 `--model-cache /opt/zg-models`;`RCTL_ZG_PATH` 显式指二进制("0" 禁用,rctl 回退词面);索引落检索目录内 .zvec-grep(rctl 镜像在 /var/lib/rctl/semantic/)
- **离线行为**:已验(2026-10-12,eth0 down)语义查询 fts+vector 命中且秒级(模型与索引构建期在盘,查询纯本地零网络);冷索引为构建期一次性动作
- **限制**:查询模式检索根取 cwd,非 positional 参数(位置参会被并进查询词;pi-rs spawn 同款 cwd 形);config 子命令是 `zg --config …` 前缀(旧 `zg config …` 形已废);libzvec_c_api.so 是伴生共享库,装二进制必须连同 + ldconfig;上游 HEAD 锁定相对 pi-rs vendored fork(30c3160+doc-header/per-file-cap 修复)不含那两修复——本用途检索单元是一行微文档非源码切块,不受影响
- **调用先例**:pi-rs `packages/rs-agent/src/extensions/rust_script/search-tool.ts`(positional+--fts 双腿 --fuse 融合;词表没见过的新造词靠 fts 腿兜,dbg_cli 与 postex 两例 )

## rctl 收录行

- rctl: zg kind=tool path=/usr/local/bin/zg note=语义检索引擎,rctl search 向量腿

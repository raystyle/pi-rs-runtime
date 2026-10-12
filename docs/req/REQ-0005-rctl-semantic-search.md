# REQ-0005 rctl 语义搜索:zg 引擎接入(状态:implemented,2026-10-12)

## 需求

rctl search 需要语义搜索能力:词面子串之外,中文/英文自然语言查询能按含义召回相关件。实现走 zg(zvec-grep:ripgrep 面 + BM25 + 向量混排),编译进镜像,rctl 运行时接管排序;zg 不可用时行为完全不变(词面子串回退)。

## 决策

- **引擎**:zvec-grep,消费 pi-rs 仓 vendored fork(zvec-ai/zvec-grep @30c3160 + fix/doc-header-and-per-file-cap @d60aeb8;先例与调用面实证在 pi-rs `search-tool.ts`)。构建 `cargo build --release -p zg`(llama.cpp+ort 链),在实例内构建期在线面完成(`CARGO_NET_OFFLINE=false`,entc 同款),产物装 `/usr/local/bin/zg`。
- **模型**:qwen3-embedding-0.6b GGUF(ggml-org 面,Qwen 中文优先多语;默认 bge-small-en-v1.5 纯英文不贴中英混合 catalog)。构建期下载烤库 `/opt/zg-models`(zg `--model-cache` 指 past),运行期零网络;体积约 0.4-0.6GB,与 trivy-db 同属构建日快照类资产。备选 embeddinggemma-300m(更小,中文弱一档)。
- **检索单元**:每 catalog 行一微文档(id/desc/taskHint 词袋/kind/alias),沿 pi-rs 2026-10-09 用户裁定(短句描述语义召回最佳,全文稀释向量;英文码块会压过中文能力行)。
- **查询形状**:positional + `--fts <q>` 双腿(向量词表没见过的新造词靠 fts 兜住,pi-rs dbg_cli/postex 实证)+ `--fuse` 融合 + `--mode direct --compact --preview none --limit N`,镜像目录 cwd,增量索引(changed 或 `.zvec-grep` 缺失才重index,30s 兜底杀)。
- **回退序**:`RCTL_ZG_PATH`(显式指二进制,"0" 禁用)> `/usr/local/bin/zg` > 无 zg 则词面子串。语义腿失败(非零退出)同样回退词面,search 永不因引擎故障而空手。

## 验收判据

1. 实例断网(eth0 down)下 `rctl search <中文自然语言查询>` 返回相关件且零网络(语义查询不含目标件名与词典原词,例:「跨内网把流量转发出来」「破解 wifi 握手包」)。
2. zg 缺席(`RCTL_ZG_PATH=0`)时 search 行为与本单前完全一致,金标回归 test/search.test.ts 仍 9/0。
3. 语义路径的镜像与索引幂等:catalog 未变时二次查询零重索引。
4. 输出面标注当前引擎(人读面尾行 / --json 字段),agent 可判别。

## trace

- 2026-10-12 立单(draft);侦察:pi-rs vendored fork 调用面/模型目录/配置机制全读。
- 2026-10-12 实现 + 四验收全过(implemented):
  - 引擎:容器内冷构建约 10 分钟(llama.cpp+ort 链,cmake/gcc 在);伴生共享库 libzvec_c_api.so 必须同装入 /usr/local/lib + ldconfig(缺它 zg 起不来)。上游 HEAD 钉 1bbdadd(pi-rs fork 的 doc-header/per-file-cap 修复不含,但本用途是一行微文档非源码切块,不受影响)。
  - 模型:qwen3-embedding-0.6b Q8_0 GGUF 610M 落 /opt/zg-models,sha256 钉入 pins.sh 标量;下载走 zg 自下载器(标记文件自理)。
  - 索引:494 微文档全量索引一次性(构建期),产物 5.3M 落 /var/lib/rctl/semantic/.zvec-grep;增量重索引只补变化件;运行期查询约 1.3 秒/次。
  - 验收 1:断网(eth0 down)root 与 ubuntu 双视角 engine=zvec;「从windows域控导出凭据」top 命中 impacket/GetUserSPNs.py(纯语义,词面不含);「跨内网把流量转发出来」8 结果。
  - 验收 2:RCTL_ZG_PATH=0 → engine=lexical 行为不变;宿主 bun test 14/0(词面金标无回归)。
  - 验收 3:镜像未变零重索引(ensureMirror 内容比对 + .zvec-grep 标记,单测覆盖)。
  - 验收 4:engine=zvec|lexical 人读尾行 + --json meta.note。
  - 测试:test/semantic.test.ts(解析器中位锚单测、ensureMirror 增量单测、回退确定性恒跑;语义金标 5 例 zg 在位才跑,宿主无 zg 自动跳过)。
  - 坑:zg 查询根取 cwd 非 positional(位置参会并进查询词);`zg config` 旧形已废改 `zg --config`;容器内 kill 对 zg 索引进程无效(宿主信号策略 known-issue 再证,残留进程随容器重启清);resolve-pins 重跑发现 exploit-database/exploitdb 上游暂不可达(镜像与直连均 404,旧钉手工回填止损)。

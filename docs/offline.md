# 离线运行(建成后无外网可干活)

镜像定位的第一条承诺是离线可用。本文件登记离线机制、验证方法与边界。
判定口径:**断网 = `ip link set eth0 down` 后 DNS 与直连立即失败**;工具/构建链在该状态下完成真实动作才算过。

## 机制分层

### 1. 固化缓存(字节在构建期钉进 /opt,运行期不访问索引)

| 生态 | 固化位置 | 运行期如何被找到 |
|---|---|---|
| Go | `/opt/go/pkg/mod`(GOMODCACHE) | `go env -w` per-user 文件(root + ubuntu 各一份,非登录 shell 也读) |
| Rust | `/opt/cargo` registry + `/opt/rustup` | 家目录软链 `~/.cargo`→/opt/cargo、`~/.rustup`→/opt/rustup |
| Python | `/opt/wheelhouse`(轮子)+ `/opt/re-venv` + `/opt/uv-tools` | 消费:`pip install --no-index --find-links /opt/wheelhouse <包>` |
| Node | `/opt/js-lab/node_modules`(161 包) | 软链进每个 fnm 版本的全局 node_modules;NODE_PATH(profile.d)备份 |
| Java | `/opt/m2`(maven 本地仓) | `/opt/maven/conf/settings.xml` 写死 localRepository(不依赖 shell) |
| .NET | `/opt/nuget-packages` | NuGet.Config `fallbackPackageFolders`(NuGet 官方离线机制,root+ubuntu 各一份) |
| PowerShell | `/opt/psmodules` | 软链进 `/usr/local/share/powershell/Modules`(pwsh 默认系统模块路径) |
| Zig | `/opt/zig-cache` | 家目录软链 `~/.cache/zig`→/opt/zig-cache |
| 扫描器库 | `/opt/trivy-db`、`/opt/nuclei-templates`、capa 规则 | wrapper 注入(见下) |
| 数据 | SecLists、wordlists+rockyou、frida-server 八平台、PoC-in-GitHub 索引 | 直接读盘 |

### 2. wrapper 层(/usr/local/bin,压过 PATH 后段)

`nuclei`(-duc 禁更新检查)、`trivy`(默认 `TRIVY_CACHE_DIR=/opt/trivy-db` + `--skip-db-update`;`download-db-only` 直通真身)、`capa`、`poc-search`、`responder`、`enum4linux-ng`、`krbrelayx`、`bloodhound-python`、`cewl`、`jwt-tool`、`linkfinder`。

注意:**alias 在 `incus exec` 这类非交互 shell 不生效**,所有运行期行为修正都必须落成 wrapper 文件,不能只写 alias。

### 3. 非登录 shell 兼容(血泪教训)

智能体主通道是 `incus exec <容器> -- bash -c …`:**不读 /etc/profile.d 也不读 /etc/environment**。
凡离线必需的环境变量,必须改用 shell 无关的机制:
per-user 配置文件(go env、NuGet.Config)、默认路径软链(cargo/rustup/gradle/zig/psmodules/js-lab)、wrapper(trivy/nuclei)。
profile.d 只作登录 shell 的备份面。

### 4. offline() 快失败函数

`/etc/profile.d/offline.sh` 提供 `offline` 命令:`GOPROXY=off CARGO_NET_OFFLINE=true NPM_CONFIG_PREFER_OFFLINE=true UV_OFFLINE=1`。
离线期新依赖解析默认是长超时挂起,半静默最伤现场;登录 shell 里执行 `offline` 后新依赖立即报错。

## 边界(离线做不成的事,属设计)

- `apt install` 新件不可用:`/var/lib/apt/lists` 已清,离线新装=快失败,属预期。
- trivy 漏洞库、nuclei 模板、grype 类库是**构建日快照**;要新鲜数据回有网环境重跑对应组再 publish。
- trufflehog 的 verify、云 API 枚举、subfinder 被动源这类**天然面向外网**的动作,断网失败不是缺陷。
- objection 启动会查一次 PyPI 版本,断网时 DNS 快失败不阻塞;黑洞网络(丢包不拒绝)下可能等一个超时。

## 验证(每轮 publish 前可复跑)

断网冒烟脚本覆盖:编译器版本面、离线构建(go build GOPROXY=off / pip --no-index / node require / mvn -o / nuget restore)、
渗透工具面、分析工具面、参考库在位、断网确认。本轮结果与修复记录见 PROGRESS.md 离线轮条目。

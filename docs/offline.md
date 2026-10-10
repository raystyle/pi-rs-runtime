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
| Node | `/opt/js-lab/node_modules`(161 包) | 软链进各 node prefix 的 `lib/node`(Module.globalPaths 只认这条;`node_modules` 面的链仅供 npm -g/bin);NODE_PATH(profile.d)备份 |
| Java | `/opt/m2`(maven 本地仓) | `/opt/maven/conf/settings.xml` 写死 localRepository(不依赖 shell) |
| Gradle | `/opt/gradle-home` | 家目录软链 `~/.gradle`;缓存要可写(daemon/锁),piopt 组 + 默认 ACL 共享(见 §5) |
| .NET | `/opt/nuget-packages` | NuGet.Config `fallbackPackageFolders`(NuGet 官方离线机制,root+ubuntu 各一份);不再导出 NUGET_PACKAGES(global 与 fallback 同路径会让登录 restore 写固化仓) |
| PowerShell | `/opt/psmodules` | 软链进 `/usr/local/share/powershell/Modules`(pwsh 默认系统模块路径) |
| Zig | `/opt/zig-cache`(hash 钉在 `/opt/zig-prewarm/build.zig.zon`) | 家目录软链 `~/.cache/zig`;可写共享(piopt 组 + 默认 ACL,见 §5);cargo-zigbuild 缓存同形 |
| 扫描器库 | `/opt/trivy-db`、`/opt/nuclei-templates`、capa 规则 | wrapper 注入(见下) |
| 数据 | SecLists、wordlists+rockyou、frida-server 八平台、PoC-in-GitHub 索引 | 直接读盘 |

### 2. wrapper 层(/usr/local/bin,压过 PATH 后段)

`nuclei`(-duc 禁更新检查)、`trivy`(默认 `TRIVY_CACHE_DIR=/opt/trivy-db` + env 注入 `TRIVY_SKIP_DB_UPDATE/TRIVY_SKIP_JAVA_DB_UPDATE/TRIVY_SKIP_CHECK_UPDATE`;`--download-*` 按精确旗标直通真身)、`capa`、`poc-search`、`responder`、`enum4linux-ng`、`krbrelayx`、`bloodhound-python`、`cewl`、`jwt-tool`、`linkfinder`。

注意:**alias 在 `incus exec` 这类非交互 shell 不生效**,所有运行期行为修正都必须落成 wrapper 文件,不能只写 alias。

### 3. 非登录 shell 兼容(血泪教训)

智能体主通道是 `incus exec <容器> -- bash -c …`:**不读 /etc/profile.d 也不读 /etc/environment**。
凡离线必需的环境变量,必须改用 shell 无关的机制:
per-user 配置文件(go env、NuGet.Config)、默认路径软链(cargo/rustup/gradle/zig/psmodules/js-lab)、wrapper(trivy/nuclei)。
profile.d 只作登录 shell 的备份面。

### 4. 默认快失败(离线期拉新依赖立即报错,不挂起)

运行期配置把五生态钉成离线优先;构建脚本(source `lib/common.sh`)用 env 显式拿回在线面(env 优先级恒高于配置文件):

| 生态 | 运行期配置(默认面) | 离线行为(实证) | 在线覆盖(构建/手工) |
|---|---|---|---|
| Go | `~/.config/go/env` 里 `GOPROXY=off`(root+ubuntu) | `module lookup disabled by GOPROXY=off`,瞬时 | common.sh export GOPROXY=goproxy.cn |
| Rust | `/opt/cargo/config.toml` `[net] offline=true` | 未缓存 crate 立即报 not found | `CARGO_NET_OFFLINE=false` |
| Node | prefix 级 npmrc:`offline=true` + `fetch-retries=0` | `ENOTCACHED` 亚秒;**注意 `--prefix` 会连 npmrc 一起丢掉**(npm 的坑,实证) | `NPM_CONFIG_OFFLINE=false` + `NPM_CONFIG_FETCH_*` |
| uv | `/etc/uv/uv.toml` `offline=true` | 8ms 报 "network was disabled" | `UV_OFFLINE=0` |
| pip | `/etc/pip.conf` `[install] no-index=true find-links=/opt/wheelhouse` | 轮子内的包离线直装;轮子外立即 No matching distribution | `PIP_NO_INDEX=false` |

js-lab 的包走 `require`(全局链)离线可用,但 `npm install` 同一包仍 ENOTCACHED(npm cache 被 clean-image 清掉)——两条消费路径,语义不同,别混。

`/etc/profile.d/offline.sh` 的 `offline()` 函数保留作显式开关(登录 shell);默认面已快失败,它不再是必需品。
maven/gradle 没有干净的「配置离线+CLI 覆盖」对,不做默认离线:手工 `mvn -o` / `gradle --offline`;
另注意 gradle wrapper(`./gradlew`)会按 distributionUrl 重新下载发行包,离线期用系统 `gradle` 命令。

### 5. 可写共享缓存的权限模型

zig 全局缓存、gradle 家目录、cargo-zigbuild 缓存不是只读仓(编译要写 z/、daemon、锁)。
软链指到 /opt 后用共同组 `piopt`(root+ubuntu)+ **默认 ACL**(`setfacl -d -m g:piopt:rwX`)共享;
setgid 只作辅助——它单独压不住 umask 022(实证 zig 自建子目录 g=r-x,ubuntu 写不进),压住 umask 的是默认 ACL。
`setfacl` 缺失时 `shared_writable_cache` 直接 return 1(假绿比失败更伤)。
**不上 1777**——任意用户可写就能换掉 root 下次构建要用的缓存。只读消费面(node lib/node、psmodules、nuget fallback)保持 755。

## 边界(离线做不成的事,属设计)

- `apt install` 新件不可用:`/var/lib/apt/lists` 已清,离线新装=快失败,属预期。
- trivy 漏洞库、nuclei 模板、grype 类库是**构建日快照**;要新鲜数据回有网环境重跑对应组再 publish。
- trufflehog 的 verify、云 API 枚举、subfinder 被动源这类**天然面向外网**的动作,断网失败不是缺陷。
- objection 启动会查一次 PyPI 版本,断网时 DNS 快失败不阻塞;黑洞网络(丢包不拒绝)下可能等一个超时。

## 验证(每轮 publish 前可复跑)

断网冒烟脚本覆盖:编译器版本面、离线构建(go build GOPROXY=off / pip --no-index / node require / mvn -o / nuget restore)、
渗透工具面、分析工具面、参考库在位、断网确认。本轮结果与修复记录见 PROGRESS.md 离线轮条目。

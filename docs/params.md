# 参数表

本册汇总全部可调参数：构建脚本变量、镜像源覆盖、版本锁定、路径与工具集。镜像源与版本锁定均定义在 `scripts/lib/common.sh`，可用环境变量覆盖。返回 [README](../README.md)。

## 构建脚本（`build-base-image.sh`）

| 名称 | 类型 | 必填 | 默认 | 约束 |
|------|------|------|------|
| `RELEASE` | 环境变量 | 否 | `noble` | Ubuntu 套件代号，传给 `-o image.release`,yaml 不写死，必须显式给 |
| `ARCH` | 环境变量 | 否 | `amd64` | `amd64` 或 `arm64` |
| `ALIAS` | 环境变量 | 否 | `ubuntu-24.04-base` | 导入 Incus 的别名；同名旧别名先删后导 |

## 镜像源覆盖（`lib/common.sh`，全部可选）

| 名称 | 默认 | 约束 |
|------|------|------|
| `TUNA` | `https://mirrors.tuna.tsinghua.edu.cn` | 其余 tuna 系镜像的前缀 |
| `RUSTUP_DIST_SERVER` / `RUSTUP_UPDATE_ROOT` | `$TUNA/rustup`、`$TUNA/rustup/rustup` | 已 export，持久化到 `/etc/profile.d/rustup.sh` |
| `CRATES_INDEX` | `$TUNA/crates.io-index` | cargo sparse index |
| `GOPROXY` / `GOSUMDB` | `https://goproxy.cn,direct` / `sum.golang.google.cn` | 已 export,`go install` 子进程继承 |
| `GO_DOWNLOAD` | `https://mirror.nju.edu.cn/golang` | tuna 无 golang 发行包 |
| `NPM_REGISTRY` / `NODE_MIRROR` | `https://registry.npmmirror.com` 及其 `/-/binary/node` | npm registry 与 node 二进制分开 |
| `PIP_INDEX` | `https://mirrors.aliyun.com/pypi/simple` | 写 `/etc/pip.conf` 与 `/etc/uv/uv.toml`,uv 索引用同一个变量(2026-10-09 起阿里云,切换) |
| `ADOPTIUM_MIRROR` | `$TUNA/Adoptium` | temurin JDK 发行包 |
| `MAVEN_MIRROR` / `MAVEN_DEP_MIRROR` | `$ALIYUN/apache/maven` / `https://maven.aliyun.com/repository/public` | 发行包与 Central 依赖分开(2026-10-09 起发行包也阿里云,切换) |
| `NUGET_MIRROR` | `https://repo.huaweicloud.com/repository/nuget/v3/index.json` | 写各用户 `NuGet.Config`,`<clear/>` 后只留此源 |
| `PY2_MIRROR` | `https://mirrors.huaweicloud.com/python` | python2 源码包 |
| `SURY_MIRROR` | `https://mirror.nju.edu.cn/sury` | tuna 无 sury;GPG key 仍从官方取一次 |
| `GITHUB_MIRROR` | `https://proxy.ohmygh.com/` | GitHub 前置代理，拼在 `https://github.com` 前；置空则直连 |

## 版本锁定（`lib/common.sh`，全部可选）

| 名称 | 默认 | 约束 |
|------|------|------|
| `GOLANG_VERSION` | `1.27.1` | sha256 从 golang.google.cn 官方 JSON 取并校验 |
| `NODE_VERSION` | `24.21.0` | npmmirror `SHASUMS256.txt` 校验 |
| `FNM_NODE_VERSIONS` | `18 20 22 24` | fnm 预装的 node 大版本，空格分隔 |
| `DOTNET_SDK` | `dotnet-sdk-10.0` | noble 自带源(即 tuna);MS 仓仅 pwsh 注册 |

| 版本锁定 | [pins.sh](../scripts/lib/pins.sh) | go/crate/pypi/gem/nuget/git 五映射与标量,由 `scripts/resolve-pins.sh` 生成;升级时跑它再审 diff。库缓存锁文件是构建日锁定的版本 |
| `ZIG_VERSION` | `0.16.0` | ziglang.org 直下，无国内镜像；仅 amd64/arm64 |
| `MAVEN_VERSION` / `GRADLE_VERSION` | `3.9.16` / `8.14.3` | |
| `JAVA_VERSIONS` | `8 11 17 21 25` | sdkman 预装的 temurin 主版本；小版本随 tuna 目录取最新 |
| `PD_VERSION` | `latest` | projectdiscovery 全家桶 `go install` 版本 |
| `PY2_VERSION` | `2.7.18` | 源码编译，`--enable-shared` |
| `PHP_VERSIONS` | `7.4 8.1 8.3` | sury 源；VLD 逐版本尽力编译 |
| `PI_RS_CORE_VERSION` / `PI_RS_SHA256` | `0.3.0` / `fc666060…1bc1a0fb` | pi-rs-core GitHub Release 发行件锚;镜像道对该仓不可用,直连兜底,再兜宿主预推 /root;换版本两值同改 |
| `GHIDRA_VERSION` / `GHIDRA_DATE` / `GHIDRA_SHA256` | `12.1.3` / `20260817` / `93a5d11a9ad510622acaaf908c556a7b9b764d338e78a7567f3689bf5081fd54` | 三者配套，换版本时同步换 |
| `FASM_VERSION` | `1.73.32` | 见 `install-compilers.sh` 内 `install_c` |
| `JADX_VERSION` / `APKTOOL_VERSION` / `CAPA_VERSION` | `1.5.3` / `2.12.0` / `9.4.0` | 见 `install-tools.sh` 内 `install_analysis` |
| `HERDR_VERSION` / `HERDR_SHA256` | `0.9.3` / `18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7` | herdr.dev stable 频道；校验和只覆盖 linux-x86_64 资产，换版本重算 |
| `SECGO_VERSION` | `latest` | Go 安全工具组 `go install` 版本 |

## 路径与工具集

| 名称 | 默认 | 约束 |
|------|------|------|
| `RE_VENV` | `/opt/re-venv` | 逆向 Python 环境（uv venv):capstone、keystone-engine、unicorn、lief、yara-python 与 FLOSS、oletools、netexec |
| `VENV_ANALYTICS` | `/opt/analytics` | 分析 venv(uv venv):polars、pyarrow、chdb、duckdb；系统 python3 不装 pip 第三方包 |
| `PD_TOOLS` / `SECGO_TOOLS` | 见脚本内 `PD_TOOLS_DEFAULT` / `SECGO_TOOLS_DEFAULT` | 空格分隔清单，留空装默认全集；单工具编译失败不中断整组 |
| `VCPKG_PKGS` | `openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara` | vcpkg 源码编译，耗时较长 |
| `PI_IMAGE` | `pi-box-dev` | `dev-instance.sh` 启动用的镜像别名 |
| `VNC_RES` / `VNC_DISPLAY` / `VNC_PORT` | `1280x800x24` / `:99` / `5900` | `vnc-screen.sh`;VNC 只绑 `127.0.0.1` |
| `VNC_PASS` | 空 | 未提供且 `~/.vnc/passfile` 不存在时生成 12 位随机口令并打印 |



## 2026-10-11 新增标量锁定版本:agent 平台轮

| 标量 | 当前 | 面 |
|---|---|---|
| BUN_VERSION | 1.4.3 | bun(rctl/acpsup 编译期闸) |
| CLAUDE_CODE_VERSION / CODEX_VERSION | 2.1.296 / 0.162.1 | agent CLI |
| CLAUDE_ACP_VERSION / CODEX_ACP_VERSION | 0.89.1 / 2.2.2 | ACP 适配器 |
| ALIYUN_CLI_VERSION / TCCLI_VERSION | v3.5.1 / 3.1.180.1 | 云 CLI |
| STEGSEEK_VERSION + STEGSEEK_SHA256 | 0.6 + deb sha256 | stegseek(release deb 锚) |

npm/pypi/git/gem 新增锁定版本:rea-agents 6.3.0、aioquic 1.4.0、qiling 1.4.6、angr 10.0.3、git-dumper 1.0.9、apkid 3.1.0、one_gadget 1.10.0(Ruby3.2 面)、seccomp-tools 1.7.1、zsteg 0.2.14;git 新增锁定版本:LOLBAS/webappanalyzer/exploitdb(GitLab 直连道)/hacktricks(浅克隆文本面)/gtfobins(.github.io 源仓)/phpggc/commix/SSTImap。

## agent 网关(`install-tools.sh agents`,全部可选)

| 名称 | 默认 | 约束 |
|------|------|------|
| `AGENT_GATEWAY_URL` | 空 | overcast 网关地址,接线必填,部署时显式给;不给则跳过接线并保留盘上已有网关配置 |
| `AGENT_GATEWAY_TOKEN` | 空 | 网关令牌;不入库;经环境变量或 `AGENT_GATEWAY_TOKEN_PATH`(默认 `/root/.agent-gateway-token`)给;消费后删除;关鉴权期统一占位 `overcast` |
| `AGENT_CC_HAIKU` / `AGENT_CC_SUBAGENT` | `zp-cc-glm53fh[1m]` | claude haiku 与子代理模型映射 |
| `AGENT_CC_SONNET` / `AGENT_CC_OPUS` | `zp-cc-glm53[1m]` | claude sonnet 与 opus 模型映射 |
| `AGENT_CX_MODEL` | `zp-cx-glm53` | codex 模型 |

接线产物:claude 的 `/etc/claude-code/managed-settings.json` env、codex 的 `/etc/codex/models.json` 与三份 config(root/ubuntu/skel,0600);缺令牌重跑保留盘上已有网关配置。

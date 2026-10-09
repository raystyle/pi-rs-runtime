# 安装面清单 · 运行时（`install-runtimes.sh`）

组列中文名与脚本键对照：Node.js 运行时=`node`、Node 版本管理器=`fnm`、Bun 运行时=`bun`、Python 包管理器=`uv`、Python 3 运行时=`python`、Python 2 运行时=`python2`、DuckDB 分析引擎=`duckdb`、ClickHouse 分析引擎=`clickhouse`、PHP 运行时=`php`、Mono 运行时=`mono`、.NET 运行时=`dotnet`、PowerShell=`pwsh`、Java 工具链管理器=`sdkman`。返回 [安装面清单索引](index.md)。

## Node.js 运行时（`node`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| node、npm、npx | 24.21.0（`NODE_VERSION`） | [nodejs.org](https://nodejs.org) 二进制（npmmirror `NODE_MIRROR`，`SHASUMS256.txt` 校验） |
| 全局 npmrc（registry、disturl、electron_mirror） | — | npmmirror |
| typescript、prettier、eslint | npm 全局未钉 | [npmjs.com](https://www.npmjs.com)（npmmirror） |
| corepack（pnpm、yarn） | 随 node | [nodejs.org](https://nodejs.org) 自带 |
| dotnetjs | npm 全局未钉 | [pseudocc/dotnetjs](https://github.com/pseudocc/dotnetjs)（npmmirror） |

```bash
# node、npm、npx:node、npm、npx 链到 /usr/local/bin
curl -fSL ${NODE_MIRROR}/v24.21.0/node-v24.21.0-linux-x64.tar.xz
sha256sum -c
tar -C /opt/node -xJf --strip-components=1
# 全局 npmrc:直写 /opt/node/etc/npmrc 的 disturl=https://npmmirror.com/mirrors/node、electron_mirror=https://npmmirror.com/mirrors/electron/
npm config set --location=global registry ${NPM_REGISTRY}
# typescript、prettier、eslint:tsc、tsserver、prettier、eslint 链到 /usr/local/bin
npm install -g typescript
npm install -g prettier eslint
# corepack(pnpm、yarn)
COREPACK_NPM_REGISTRY=${NPM_REGISTRY} corepack enable
# dotnetjs
npm install -g dotnetjs
```

## Node 版本管理器（`fnm`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| fnm | cargo 未钉 | [Schniz/fnm](https://github.com/Schniz/fnm)（crates 经 tuna） |
| node 18、20、22、24 | 大版本内最新（`FNM_NODE_VERSIONS`） | nodejs.org 二进制（npmmirror） |

```bash
# fnm
cargo install fnm --locked
# node 18、20、22、24:20、22、24 与 18 同;profile.d 写 fnm env
fnm install --node-dist-mirror ${NODE_MIRROR} 18
fnm default <最新>
```

## Bun 运行时（`bun`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| bun、bunx | npm 全局未钉 | [bun.sh](https://bun.sh)（npmmirror） |

```bash
# bun、bunx:链到 /usr/local/bin;root 与 ubuntu 各写 .bunfig.toml 的 [install] registry = ${NPM_REGISTRY}
npm install -g bun
```

## Python 包管理器（`uv`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| uv | 官方安装器最新 | [astral.sh/uv](https://docs.astral.sh/uv/)（[astral-sh/uv](https://github.com/astral-sh/uv)） |

```bash
# uv:写 /etc/uv/uv.toml 的 [[index]] url = ${PIP_INDEX}、default = true
curl -LsSf https://astral.sh/uv/install.sh | sh
ln -sf ~/.local/bin/uv /usr/local/bin/uv
```

## Python 3 运行时（`python`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| python3 及 pip、venv、dev | noble 随源 | [python.org](https://www.python.org)（Ubuntu 打包，tuna） |
| ruff | uv tool 未钉 | [astral-sh/ruff](https://github.com/astral-sh/ruff) |
| /opt/analytics venv：polars、pyarrow、chdb | 未钉 | PyPI（tuna） |

```bash
# python3 及 pip、venv、dev:写 /etc/pip.conf 的 index-url = ${PIP_INDEX};不装任何第三方包
apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
# ruff
UV_TOOL_BIN_DIR=/usr/local/bin UV_TOOL_DIR=/opt/uv-tools uv tool install ruff
# /opt/analytics venv(polars、pyarrow、chdb)
uv venv /opt/analytics
VIRTUAL_ENV=/opt/analytics uv pip install polars pyarrow chdb
```

## Python 2 运行时（`python2`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| python 2.7 | 2.7.18（`PY2_VERSION`），`--enable-shared` | [python.org](https://www.python.org/downloads/release/python-2718/)（源码包经华为云 `PY2_MIRROR`） |

```bash
# python 2.7
apt-get install libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils libffi-dev
curl -fSL ${PY2_MIRROR}/2.7.18/Python-2.7.18.tgz
./configure --prefix=/usr/local --enable-shared && make -j$(nproc) && make altinstall
```

## DuckDB 分析引擎（`duckdb`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| duckdb python 绑定 | 未钉 | [duckdb/duckdb](https://github.com/duckdb/duckdb)（PyPI 经 tuna） |
| duckdb CLI | release latest | [duckdb/duckdb](https://github.com/duckdb/duckdb) releases |

```bash
# duckdb python 绑定
VIRTUAL_ENV=/opt/analytics uv pip install -U duckdb
# duckdb CLI:latest tag 经 api.github.com 取
curl -fSL https://github.com/duckdb/duckdb/releases/download/<tag>/duckdb_cli-linux-amd64.zip
install -m755 /usr/local/bin/duckdb
```

## ClickHouse 分析引擎（`clickhouse`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| clickhouse（单二进制，含 `local`、`client`、`server` 等子命令） | 官方安装脚本最新 | [clickhouse.com](https://clickhouse.com)（官方 `curl | sh` 安装器，`CLICKHOUSE_ONLY=1` 只取二进制不附带 clickhousectl） |

```bash
# clickhouse:单二进制装 /usr/local/bin/clickhouse;用法 clickhouse local,不存在 clickhouse-local 软链
curl -fsSL https://clickhouse.com/ | CLICKHOUSE_ONLY=1 sh
install -m755 clickhouse /usr/local/bin/clickhouse
```

## PHP 运行时（`php`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| php-cli、php-dev 多版本与 VLD | 7.4、8.1、8.3（`PHP_VERSIONS`） | [php.net](https://www.php.net)（Ondřej Surý 第三方打包，`SURY_MIRROR` 南大镜像；GPG key 从 packages.sury.org 取一次） |

```bash
# php-cli、php-dev 多版本与 VLD
apt-get install php${v}-cli php${v}-dev
apt-get install php-pear
yes '' | pecl -q -d php_suffix=${v} install vld-beta
phpenmod -v ${v} vld
```

## Mono 运行时（`mono`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| mono-devel、mono-xbuild | noble 随源 | [mono-project.com](https://www.mono-project.com)（Ubuntu 打包，tuna） |
| nuget.exe | latest | [nuget.org](https://www.nuget.org/downloads) |

```bash
# mono-devel、mono-xbuild
apt-get install -y --no-install-recommends mono-devel mono-xbuild
# nuget.exe
curl -fSL https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o /opt/nuget.exe
```

## .NET 运行时（`dotnet`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| .NET SDK | dotnet-sdk-10.0（`DOTNET_SDK`） | [dot.net](https://dot.net)（Ubuntu noble 源即 tuna；MS 仓 24.04 起不提供 .NET） |

```bash
# .NET SDK:root 与 ubuntu 写 NuGet.Config,<clear/> 后只留 ${NUGET_MIRROR}(华为 v3)
apt-get install -y dotnet-sdk-10.0
```

## PowerShell（`pwsh`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| PowerShell | powershell-lts 随仓 | [PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)（packages.microsoft.com，国内无镜像） |

```bash
# PowerShell:powershell-lts 不可用时退回 powershell
curl -fSL packages-microsoft-prod.deb && dpkg -i
apt-get install -y powershell-lts
```

## Java 工具链管理器（`sdkman`）

| 项目 | 版本 | 官方来源 |
|------|------|----------|
| sdkman 本体 | 安装器最新 | [sdkman.io](https://sdkman.io) |
| temurin JDK 8、11、17、21、25 | 小版本随 tuna 目录取最新（`JAVA_VERSIONS`） | [adoptium.net](https://adoptium.net)（tuna `ADOPTIUM_MIRROR`） |
| maven | 3.9.16（`MAVEN_VERSION`） | [maven.apache.org](https://maven.apache.org)（发行包经 tuna `MAVEN_MIRROR`） |
| gradle | 8.14.3（`GRADLE_VERSION`） | [gradle.org](https://gradle.org)（阿里云 distributions 镜像） |

```bash
# sdkman 本体:config 关 selfupdate、开 auto_env
curl -fSL https://get.sdkman.io -o sdkman-init.sh
SDKMAN_DIR=/usr/local/sdkman bash sdkman-init.sh
# temurin JDK 8、11、17、21、25:tuna 目录取最新 OpenJDK${major}U-jdk_x64_linux_hotspot_*.tar.gz;java、javac 链到 /usr/local/bin
tar -C /opt/jdk/temurin-<ver> --strip-components=1
sdk install java <ver>-tem <本地路径>
sdk default java <最后一个>
# maven:写 settings.xml mirror 指 ${MAVEN_DEP_MIRROR}(阿里云)
curl -fSL ${MAVEN_MIRROR}/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz
tar -C /opt/maven --strip-components=1
# gradle:root 与 ubuntu 写 .gradle/init.d/mirrors.gradle 指阿里云 public 与 gradle-plugin
curl -fSL https://mirrors.aliyun.com/gradle/distributions/v8.14.3/gradle-8.14.3-bin.zip
unzip -d /opt/gradle
```

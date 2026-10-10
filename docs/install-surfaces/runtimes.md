# 安装面清单 · 运行时(`install-runtimes.sh`)

组卡只写机制;逐件事实在 [items/runtimes/](../items/runtimes/)。

## 组机制

- node 直装 /opt/node 钉版 prefix(SHASUMS256 校验),npm/tsc 等链 /usr/local/bin;fnm 另管 18/20/22/24 历史版本,只设默认不改 /usr/local/bin;prefix 级 npmrc 写离线双保险(offline=true+fetch-retries=0,node 组与 fnm 组双写兜底)
- uv 独立安装器;`/etc/uv/uv.toml` offline=true(运行期默认)+ `uv-online.toml`(构建期经 common.sh UV_CONFIG_FILE 指过去,实证 UV_OFFLINE=0 无效)
- python 基座 apt 随源 + /etc/pip.conf([global] 索引 + [install] no-index+wheelhouse);python2 源码编译 altinstall
- dotnet 走 noble 自带源;NuGet.Config root/ubuntu 双写(华为镜像 + fallbackPackageFolders=/opt/nuget-packages),不再导出 NUGET_PACKAGES(ADR-0004 G3)
- sdkman 管 temurin 8/11/17/21/25 + maven + gradle;maven settings.xml 写 localRepository=/opt/m2 与阿里云 mirror;gradle init.d 盖插件解析,~/.gradle 软链 + piopt ACL(ADR-0005)
- pwsh 走 MS 仓(lts 不可用时退回);mono apt;php 多版本 sury;clickhouse 官方单二进制;duckdb CLI GitHub 直下

## 册索引

[node](../items/runtimes/node.md) · [fnm](../items/runtimes/fnm.md) · [bun](../items/runtimes/bun.md) · [uv](../items/runtimes/uv.md) · [python](../items/runtimes/python.md) · [python2](../items/runtimes/python2.md) · [duckdb](../items/runtimes/duckdb.md) · [clickhouse](../items/runtimes/clickhouse.md) · [php](../items/runtimes/php.md) · [mono](../items/runtimes/mono.md) · [dotnet](../items/runtimes/dotnet.md) · [pwsh](../items/runtimes/pwsh.md) · [sdkman](../items/runtimes/sdkman.md) · [java-jdks](../items/runtimes/java-jdks.md) · [maven](../items/runtimes/maven.md) · [gradle](../items/runtimes/gradle.md)

返回 [安装面清单](index.md)。

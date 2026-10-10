# 软件清单归档(计数对账面)

> 逐件事实(版本/来源/落点/离线行为/坑)已迁到 [items/](items/README.md) 逐件册,本册只留计数对账与形态分布;双写必漂移,新增件先加册再改这里的计数。

## 册数对账(与 items/README.md 一致)

| 面 | 册数 | 承载件数(批量件在组册成员表) |
|---|---|---|
| [items/compilers/](items/compilers/) | 6 | 6 组(含 build-essential 21 包、vcpkg 12 库) |
| [items/runtimes/](items/runtimes/) | 16 | 13 组键(sdkman 拆 4 册) |
| [items/libcache/](items/libcache/) | 8 | 八生态缓存固化 |
| [items/tools-*/](items/README.md#toolsinstall-toolssh41-册) | 43 | 21 组(含 apt 36+20 包、pd 20 CLI、secgo 18 CLI、参考克隆 41+7+4+4 仓、maldev 官网 tgz 2 件) |

## 形态分布

- **已装(二进制/CLI 可用)**:编译器 6 组、运行时 13 组、工具已装面(pd 20 + secgo 18 + secrust 3 + pivot 6 + p0 批 + pentest 批 + red 24 + msf + 各单件)
- **缓存固化(字节在 /opt,非安装)**:libcache 八生态 + trivy-db + nuclei-templates + capa-rules + SecLists/wordlists + frida-server 八平台 + js-lab
- **参考克隆(只克隆不安装不运行)**:c2dev-ref 7 仓、payload-ref/tradecraft-ref 41 仓+2 tgz、recon-ref 4 仓、pz 4 仓(ADR-0002)
- **隔离环境**:/opt/re-venv、/opt/analytics、/opt/uv-tools、fnm node 18/20/22/24、sdkman JDK 8/11/17/21/25、/opt/maven-prewarm 等预热工程

## 版本与来源口径

钉版变量集中在 `scripts/lib/common.sh`(见 [params.md](params.md));镜像源实测口径同册。未钉与无校验和件登记在 [known-issues.md](known-issues.md)。

返回 [docs 文档地图](README.md)。

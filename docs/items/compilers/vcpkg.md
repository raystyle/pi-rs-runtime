# vcpkg

> C/C++ 库包管理器 + 12 个常用库源码编译集(RE/安全方向实用集) ｜ 状态:已装 ｜ 组:`install-compilers.sh vcpkg`

- **版本钉**:本体 pins.sh 钉版(`GIT_PIN[microsoft/vcpkg]`=e456309491fd875487bf02b8a0dca76c1b1b00cc,clone_pin 幂等:HEAD==钉即跳过;解析日 2026-10-10),升级跑 scripts/resolve-pins.sh;12 库版本随 ports 树(同一钉 sha 钉住);bootstrap 出的 vcpkg 二进制随钉;`VCPKG_PKGS` 默认集 `openssl zlib curl sqlite3 libpcap fmt spdlog nlohmann-json rapidjson cpp-httplib mbedtls yara`(env 可覆盖)
- **来源与安装**:[microsoft/vcpkg](https://github.com/microsoft/vcpkg) GitHub 直连克隆(不经 GITHUB_MIRROR)→ `/opt/vcpkg`;`./bootstrap-vcpkg.sh -disableMetrics` 编出本体;先 apt 装 flex、bison(libpcap 等库源码构建依赖);`vcpkg install $VCPKG_PKGS` 逐库源码编译,耗时较长。脚本面:`scripts/install-compilers.sh` `install_vcpkg`
- **落点**:本体 `/opt/vcpkg`(含 ports 树、bootstrap 二进制;库产物在 `installed/` 下按 triplet 分目录);`/usr/local/bin/vcpkg` 软链
- **配置与缓存**:`/etc/profile.d/vcpkg.sh` 写 `VCPKG_ROOT=/opt/vcpkg` 与 PATH——只是登录 shell 备份面,`incus exec` 非登录不读([known-issues 血泪教训](../../known-issues.md));二进制/资产缓存未配置(量大可配 `VCPKG_BINARY_SOURCES` / `X_VCPKG_ASSET_SOURCES`,脚本头注释口径)
- **离线行为**:已装 12 库离线被构建消费 ☐ [推断:头文件与库全是 `installed/` 本地文件];`vcpkg install <新库>` 断网失败 ☐ [推断:ports 树虽在仓内,源 tarball 走各上游、GitHub 居多]。验证:`ip link set eth0 down` 后 `vcpkg install <未装的库>` 应立即报错
- **坑与留痕**:本体克隆与库资产下载都不经 GITHUB_MIRROR(GitHub 直连,脚本头注释);克隆失败先查 git 在不在(install-all 前置批装,脚本报错原文);boost/grpc 编译时长过高,裁定不进默认清单(脚本注释);clone_pin 幂等:HEAD==钉即跳过,漂离钉则 rm -rf 重取钉版——升级=跑 scripts/resolve-pins.sh 刷新钉值再重跑本组;bootstrap 每次重跑(已引导则快速过)

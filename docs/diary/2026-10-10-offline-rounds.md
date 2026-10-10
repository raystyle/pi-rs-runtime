# 2026-10-10 镜像卫生、纯离线三轮与 smali 批

> 归档自 PROGRESS.md 历史节(文档解耦轮);当时完整上下文以 git 历史为准。

## 镜像卫生轮

先量后清:/root/.cache 14.2 GB(go-build 10.9 GB+uv 3 GB)、/var/cache/apt 1.7 GB、NuGet http-cache 0.5 GB、journal 115 MB、nuclei-templates.bak 87 MB。新 scripts/clean-image.sh(幂等)删可再生缓存与一次性残留,不碰 /opt 固化离线缓存与 fnm node 多版本;install-all.sh 末尾自动调用。21.3 GB → 16.6 GB。grok 评审 CONFIRM,顺手裁定 /root/.local/share/gem 是安装根不删。

## 纯离线轮(grok 联合评估 → ADR-0004/0005)

断网实证(rt-offline,eth0 down)三缺口:①非登录 shell(incus exec)不读 /etc/profile.d 与 /etc/environment,NUGET_PACKAGES/GRADLE_USER_HOME/ZIG_GLOBAL_CACHE_DIR/NODE_PATH/PSModulePath 全失效,ubuntu 无 go env;②zig 五库固化空壳(/opt/zig-cache 4 KB,fetch 全败被静默吞);③trivy alias 非交互不生效,离线 FATAL first-run。

修复:go env 补 ubuntu 同款并挪早退前;NuGet.Config fallbackPackageFolders;gradle/zig 家目录软链(clean-image 对软链守卫);psmodules 链系统模块路径;js-lab 链各 node 的 lib/node(实证 require 只认 Module.globalPaths);trivy env wrapper(0.75 起 --skip-db-update 非 root 旗标);Responder/enum4linux-ng/krbrelayx wrapper;go 预热剔 go-winres(命令非库);pspy 仓名改小写;java pom 移除 org.jf:dexlib2(国内镜像无件);zig fetch 三修(git+→tarball,ohmygh 不支持 git smart-http;先 zig init,0.16 要求 cwd 是包;zlib 旧 tag zon 字符串名被 0.16 拒);缺一库即 return 1。断网冒烟 59/25 → 78/0。

grok 二轮:F1 软链指向 root 755 致 ubuntu 编译 AccessDenied → piopt 组+默认 ACL(setgid 压不住 umask,实证);G 级 trivy 精确旗标+java-db、zig 守卫加强、NUGET_PACKAGES 不再导出、cargo-zigbuild 同形。终审 F0:G1(粘性位)驳回——实证是 uutils coreutils mkdir 的行为,镜像三条缓存树 sticky 0 命中;G2 setfacl 缺失改 return 1。

## 离线快失败默认化

运行期配置钉死五生态:go env GOPROXY=off、cargo [net] offline=true、npmrc offline=true+fetch-retries=0、uv.toml offline=true、pip.conf no-index+find-links=/opt/wheelhouse(轮子内包免旗标直装);构建脚本经 common.sh env 拿回在线面。实证断网五向亚秒快失败、在线五向全过。坑:npm --prefix 会连 prefix 级 npmrc 一起丢(70s 假象);uv UV_OFFLINE=0 压不过配置文件(grok F,改 UV_CONFIG_FILE=/etc/uv/uv-online.toml);fnm npmrc 首轮写不上(node 组先于 fnm,install_fnm 尾部兜底)。

## smali 批

用户给 JesusFreke/smali 链接;实证该仓停更 v2.5.2,Google 接管为 google/smali 3.0.10,坐标在 GMaven 的 com.android.tools.smali(不在 Maven Central,早先留痕有误)。prewarm pom 加 GMaven 仓+两件钉版(dexlib2 经传递依赖回 /opt/m2,known-issues 销账);CLI 走 /opt/smali/lib 17 jar + wrapper。断网 roundtrip 过。

## 血泪教训汇总(本日新增)

跑批中的脚本不可换盘重推(bash 按字节偏移续读);heredoc 不是注释安全区(bash 注释混进 pom.xml 致 Non-parseable POM);trufflehog 3.99 filesystem 零命中退 1,断言看输出别看退出码;管道吃掉退出码;共享缓存权限必须 ubuntu 视角复验(root 冒烟天然看不见);增量验证推不出 fresh 成立(uv Checked 不走网)。

发布链:9c63a0288d34 → f0bc3ee442c2 → fd5b78bd8ec0 → 7babe55d20b9 → 34eea9e5e072 → 84e9697afa5f → 3fb1e1081c99 → 310095502aa6 → f355c683ebef → f9968c523ee4 → 31ccc42d8eaf。

#!/usr/bin/env bash
# 库缓存固化器:go / rust / python / node / java / powershell / dotnet / zig
# 在 Ubuntu 24.04 容器(或宿主)内运行,幂等,可重复执行。
# 目标:离线可用——构建期把库字节钉进 /opt 共享缓存(grok 八生态评审),
# 运行期不再访问索引;只锁清单不下字节,断网后等于没装。
# 版本钉策略:构建日用生态工具解析最新并写回锁文件(go.mod/go.sum、Cargo.lock、
# package-lock.json、pom、csproj),升级单独重跑本脚本。
# 用法:
#   ./install-libcache.sh            # 装全部
#   ./install-libcache.sh go node    # 只装指定项(可多个)
# 镜像源与版本经环境变量覆盖,见 lib/common.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/common.sh"

# ---- Go:库预热进 /opt/go/pkg/mod ------------------------------------------
# go install 只适合带 main 的命令;库必须 go mod tidy 解析进模块缓存
install_go() {
    log "Go 库预热(grok 清单:goperxy 系 + 渗透/协议/AD 库,构建日解析钉版)"
    export GOPATH=/opt/go GOMODCACHE=/opt/go/pkg/mod
    export PATH="$PATH:/usr/local/go/bin:/opt/go/bin"
    export GOPROXY GOSUMDB
    local dir=/opt/go-prewarm
    rm -rf "$dir" && install -d "$dir"
    cat > "$dir/go.mod" <<'EOF'
module prewarm

go 1.23
EOF
    cat > "$dir/main.go" <<'EOF'
package main

import (
	// 跳板/代理(原有)
	_ "github.com/armon/go-socks5"
	_ "github.com/elazarl/goproxy"
	_ "github.com/hashicorp/yamux"
	_ "github.com/quic-go/quic-go"
	_ "github.com/xtaci/smux"
	_ "golang.org/x/net/proxy"
	// 密码/系统
	_ "golang.org/x/crypto/ssh"
	_ "golang.org/x/sys/unix"
	// CLI 骨架与配置
	_ "github.com/spf13/cobra"
	_ "gopkg.in/yaml.v3"
	// 协议
	_ "github.com/google/gopacket"
	_ "github.com/miekg/dns"
	_ "github.com/refraction-networking/utls"
	// AD / 横向
	_ "github.com/go-ldap/ldap/v3"
	_ "github.com/hirochachacha/go-smb2"
	_ "github.com/jcmturner/gokrb5/v8/client"
	_ "github.com/masterzen/winrm"
	// PE 与资源
	_ "github.com/klauspost/compress/zstd"
	_ "github.com/saferwall/pe"
	_ "github.com/tc-hib/go-winres"
)

func main() {}
EOF
    ( cd "$dir" && GOFLAGS=-mod=mod go mod tidy ) \
        && echo "Go 库已预热进 /opt/go/pkg/mod,解析版本:" \
        && grep -E '^\s' "$dir/go.mod" | grep -v '^go ' || echo "!! go 预热失败"
    # pspy 是命令不是库:go install 进 /usr/local/bin,模块顺带缓存
    have pspy || go install github.com/DominicBreuker/pspy@latest 2>/dev/null \
        && ln -sf /opt/go/bin/pspy /usr/local/bin/pspy 2>/dev/null || echo "pspy 失败(可忽略)"
    true
}

# ---- Rust:cargo add 钉版 + fetch 进 /opt/cargo ------------------------------
# 安装器在 install-compilers.sh 的 rust 组有 29 个件 crate 预热(* 未钉);
# 这里用 cargo add 追加 grok 清单,cargo add 会解析精确版本写进 Cargo.toml
install_rust() {
    log "Rust 库预热(grok 清单:RustCrypto/iced-x86/goblin/证书/tokio-tungstenite 等)"
    export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
    . /opt/cargo/env 2>/dev/null || true
    export PATH="$PATH:/opt/cargo/bin"
    local pw=/opt/rust-prewarm-libs
    rm -rf "$pw" && install -d "$pw/src" && printf 'fn main(){}\n' > "$pw/src/main.rs"
    ( cd "$pw"
      printf '[package]\nname = "prewarm-libs"\nversion = "0.0.0"\nedition = "2021"\n\n[dependencies]\n' > Cargo.toml
      local c
      for c in aes-gcm chacha20poly1305 rsa p256 x25519-dalek md-5 pbkdf2 argon2 \
               jsonwebtoken rcgen x509-parser pem rasn goblin object iced-x86 nom \
               ldap3 pnet quinn tokio-tungstenite clap serde thiserror tracing \
               flate2 zip memmap2 nix fff-search; do
          cargo add "$c" 2>/dev/null || echo "cargo add $c 失败"
      done
      cargo fetch --locked 2>/dev/null || cargo fetch \
        && echo "Rust 库已 fetch 进 /opt/cargo,锁文件: $pw/Cargo.lock" \
        || echo "!! rust 预热失败"
    ) || echo "!! rust 预热工程失败"
    rm -rf "$pw"
    true
}

# ---- Python:re-venv 扩展 + /opt/wheelhouse 轮子离线重装 ----------------------
install_python() {
    log "Python 库固化(grok 清单:z3/construct/pefile/pypykatz/volatility3 等 + wheelhouse)"
    . "$HOME/.local/bin/env" 2>/dev/null || true
    [ -x "$RE_VENV/bin/python" ] || uv venv "$RE_VENV"
    local pkgs="pycryptodome cryptography gmpy2 sympy z3-solver construct pefile pyelftools dnfile pypykatz malduck volatility3 r2pipe httpx beautifulsoup4 lxml pyjwt dpkt xortool"
    # shellcheck disable=SC2086
    VIRTUAL_ENV="$RE_VENV" uv pip install $pkgs || echo "部分 python 库失败(逐个 tolerant)"
    # wheelhouse:离线重装源(只锁 requirements 不够,断网后没有索引)
    # uv 无 pip download 子命令;给 venv 装 pip 后用 pip download 拉轮子
    install -d /opt/wheelhouse
    VIRTUAL_ENV="$RE_VENV" uv pip install pip >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    [ -x "$RE_VENV/bin/pip" ] && "$RE_VENV/bin/pip" download -d /opt/wheelhouse \
        --index-url "$PIP_INDEX" $pkgs 2>/dev/null \
        && ls /opt/wheelhouse | wc -l || echo "wheelhouse 下载部分失败(pip 未装进 venv?)"
    # RsaCtfTool:RSA 题框架,克隆并锁依赖进同一份 venv
    local gh="${GITHUB_MIRROR}https://github.com"
    if [ ! -d /opt/RsaCtfTool/.git ]; then
        git clone --depth 1 "${gh}/RsaCtfTool/RsaCtfTool" /opt/RsaCtfTool || echo "RsaCtfTool 克隆失败"
    fi
    [ -f /opt/RsaCtfTool/requirements.txt ] \
        && VIRTUAL_ENV="$RE_VENV" uv pip install -r /opt/RsaCtfTool/requirements.txt 2>/dev/null \
        && echo "RsaCtfTool 依赖已进 $RE_VENV" || true
    true
}

# ---- Node:/opt/js-lab 工程 npm ci 固化 node_modules --------------------------
install_node() {
    log "Node 库固化(grok 清单:forge/pkijs/babel+webcrack/sql.js 等,全纯 JS/wasm)"
    export PATH="$PATH:/opt/node/bin"
    export NPM_CONFIG_REGISTRY="$NPM_REGISTRY"
    local dir=/opt/js-lab
    install -d "$dir"
    cat > "$dir/package.json" <<'EOF'
{
  "name": "js-lab",
  "version": "0.0.0",
  "private": true,
  "dependencies": {
    "node-forge": "*", "pkijs": "*", "asn1js": "*", "pvtsutils": "*", "pvutils": "*",
    "crypto-js": "*", "jsonwebtoken": "*",
    "@babel/parser": "*", "@babel/traverse": "*", "@babel/generator": "*", "@babel/types": "*",
    "webcrack": "*", "cheerio": "*", "fast-xml-parser": "*",
    "ws": "*", "express": "*", "jszip": "*", "sql.js": "*",
    "protobufjs": "*", "js-yaml": "*", "iconv-lite": "*",
    "libsodium-wrappers": "*", "pdf-lib": "*", "postject": "*"
  }
}
EOF
    if ( cd "$dir" && npm install --no-audit --no-fund ); then
        printf 'export NODE_PATH=/opt/js-lab/node_modules\n' > /etc/profile.d/jslab.sh
        echo "js-lab 就位: $dir/node_modules ($(ls "$dir/node_modules" | wc -l) 个包)"
    else
        echo "!! npm install 失败"
    fi
    true
}

# ---- Java:/opt/maven-prewarm dependency:go-offline 进 /opt/m2 ---------------
# 默认 profile 只含当前安全版本;study profile 隔离钉旧版(CVE 复现坐标)
install_java() {
    log "Java 库固化(grok 清单:BC/ASM/Jackson/Spring 等 + study 研究 profile)"
    # 非交互 shell 没有 JAVA_HOME,从 sdkman current 推(install-runtimes 已装)
    export JAVA_HOME="${JAVA_HOME:-/usr/local/sdkman/candidates/java/current}"
    local dir=/opt/maven-prewarm
    install -d "$dir"
    cat > "$dir/pom.xml" <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>pi</groupId><artifactId>prewarm</artifactId><version>0</version>
  <packaging>jar</packaging>
  <properties><maven.compiler.source>17</maven.compiler.source><maven.compiler.target>17</maven.compiler.target></properties>
  <dependencies>
    <dependency><groupId>org.bouncycastle</groupId><artifactId>bcprov-jdk18on</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.bouncycastle</groupId><artifactId>bcpkix-jdk18on</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.ow2.asm</groupId><artifactId>asm</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.ow2.asm</groupId><artifactId>asm-commons</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.ow2.asm</groupId><artifactId>asm-util</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.javassist</groupId><artifactId>javassist</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>com.fasterxml.jackson.core</groupId><artifactId>jackson-databind</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>com.google.code.gson</groupId><artifactId>gson</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.springframework</groupId><artifactId>spring-core</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.springframework</groupId><artifactId>spring-beans</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.springframework</groupId><artifactId>spring-context</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>com.nimbusds</groupId><artifactId>nimbus-jose-jwt</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.jsoup</groupId><artifactId>jsoup</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>com.squareup.okhttp3</groupId><artifactId>okhttp</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>cn.hutool</groupId><artifactId>hutool-all</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>info.picocli</groupId><artifactId>picocli</artifactId><version>[0,)</version></dependency>
    <dependency><groupId>org.jf</groupId><artifactId>dexlib2</artifactId><version>[0,)</version></dependency>
  </dependencies>
  <profiles>
    <profile><id>study</id><activation><activeByDefault>false</activeByDefault></activation><dependencies>
      <dependency><groupId>com.alibaba</groupId><artifactId>fastjson</artifactId><version>1.2.47</version></dependency>
      <dependency><groupId>com.alibaba</groupId><artifactId>fastjson</artifactId><version>1.2.68</version></dependency>
      <dependency><groupId>com.alibaba</groupId><artifactId>fastjson</artifactId><version>1.2.83</version></dependency>
      <dependency><groupId>org.apache.logging.log4j</groupId><artifactId>log4j-core</artifactId><version>2.14.1</version></dependency>
      <dependency><groupId>org.apache.shiro</groupId><artifactId>shiro-core</artifactId><version>1.2.4</version></dependency>
      <dependency><groupId>commons-collections</groupId><artifactId>commons-collections</artifactId><version>3.2.1</version></dependency>
      <dependency><groupId>commons-io</groupId><artifactId>commons-io</artifactId><version>[0,)</version></dependency>
      <dependency><groupId>commons-codec</groupId><artifactId>commons-codec</artifactId><version>[0,)</version></dependency>
    </dependencies></profile>
  </profiles>
</project>
EOF
    # 版本钉:写 [0,) 区间,构建日 versions:resolve-ranges 解析成精确版本写回 pom,
    # 再 dependency:go-offline 把字节拉进 /opt/m2(study profile 一并解析)
    ( cd "$dir" && mvn -q -B versions:resolve-ranges 2>/dev/null \
        && mvn -q -B -DskipTests dependency:go-offline ) \
        && echo "Java 库已进 /opt/m2(默认 profile)" \
        || echo "!! mvn 默认 profile 失败(有网阶段重跑可补)"
    ( cd "$dir" && mvn -q -B -Pstudy -DskipTests dependency:go-offline ) \
        && echo "study profile(CVE 复现坐标)已进 /opt/m2" \
        || echo "!! study profile 失败(不影响默认 profile)"
    true
}

# ---- PowerShell:Save-PSResource 固化(PSGallery 无国内镜像,构建期直连) ----------
install_pwsh() {
    log "PowerShell 模块固化(grok 清单:Posh-SSH/ImportExcel/Pester 等,Save-PSResource 含依赖)"
    have pwsh || { echo "pwsh 未装,先跑 install-runtimes.sh pwsh"; return 0; }
    # 旧 PackageManagement(Save-Module)在 noble + pwsh 7.4 上段错误;走 inbox PSResourceGet
    install -d /opt/psmodules
    pwsh -NoProfile -Command "
        Save-PSResource -Name Posh-SSH,powershell-yaml,ImportExcel,PowerHTML,Pester,PSScriptAnalyzer,Microsoft.PowerShell.SecretManagement,Microsoft.PowerShell.SecretStore -Path /opt/psmodules -TrustRepository -Quiet -ErrorAction SilentlyContinue
    " || echo "Save-PSResource 部分失败(Gallery 国内不稳,重跑可补)"
    cat > /etc/profile.d/psmodules.sh <<'EOF'
export PSModulePath=/opt/psmodules:${PSModulePath:-}
EOF
    ls /opt/psmodules 2>/dev/null || true
    true
}

# ---- .NET:预热工程 restore 进 /opt/nuget-packages + 八 RID runtime pack -----
install_dotnet() {
    log ".NET 库固化(grok 清单:dnlib/Iced/ReferenceAssemblies/ilspycmd + 8 RID)"
    have dotnet || { echo "dotnet 未装,先跑 install-runtimes.sh dotnet"; return 0; }
    export NUGET_PACKAGES=/opt/nuget-packages DOTNET_CLI_TELEMETRY_OPTOUT=1
    export PATH="$PATH:/usr/local/bin"
    local dir=/opt/dotnet-prewarm
    rm -rf "$dir"
    dotnet new classlib -o "$dir" --framework net10.0 >/dev/null 2>&1 || dotnet new classlib -o "$dir" >/dev/null
    local p
    for p in dnlib AsmResolver AsmResolver.PE AsmResolver.DotNet Iced Mono.Cecil \
             ICSharpCode.Decompiler CommandLineParser YamlDotNet Newtonsoft.Json \
             BouncyCastle.Cryptography System.DirectoryServices.Protocols \
             Microsoft.NETFramework.ReferenceAssemblies Microsoft.Data.Sqlite SharpZipLib \
             System.CommandLine; do
        ( cd "$dir" && dotnet add package "$p" 2>/dev/null ) || echo "dotnet add $p 失败"
    done
    ( cd "$dir" && dotnet restore --packages /opt/nuget-packages ) || echo "restore 失败"
    # 八 RID 的 self-contained runtime pack(grok 矩阵)
    local rid
    for rid in linux-x64 linux-arm64 linux-musl-x64 linux-musl-arm64 win-x64 win-arm64 osx-x64 osx-arm64; do
        ( cd "$dir" && dotnet restore -r "$rid" --packages /opt/nuget-packages ) || echo "RID $rid restore 失败"
    done
    # ilspycmd 全局工具到 /opt/dotnet-tools
    install -d /opt/dotnet-tools
    dotnet tool install --tool-path /opt/dotnet-tools ilspycmd 2>/dev/null || echo "ilspycmd 失败"
    ln -sf /opt/dotnet-tools/ilspycmd /usr/local/bin/ilspycmd 2>/dev/null || true
    ls /opt/nuget-packages 2>/dev/null | wc -l
    true
}

# ---- Zig:zig fetch 固化缓存(zon hash 必须用镜像内 zig 0.16 现场算) ----------
install_zig() {
    log "Zig 库固化(grok 清单:allyourcodebase 系交叉 C 库,zig fetch 进 /opt/zig-cache)"
    export ZIG_GLOBAL_CACHE_DIR=/opt/zig-cache
    export PATH="$PATH:/opt/zig:/usr/local/bin"
    have zig || { echo "zig 未装,先跑 install-compilers.sh zig"; return 0; }
    local dir=/opt/zig-prewarm
    rm -rf "$dir" && install -d "$dir" && cd "$dir"
    # zig fetch --save 会把依赖写进 build.zig.zon 并填充全局缓存;hash 以 0.16 输出为准
    local spec
    for spec in \
        "git+https://github.com/allyourcodebase/zlib.git#1.3.1" \
        "git+https://github.com/allyourcodebase/zstd.git" \
        "git+https://github.com/allyourcodebase/sqlite3.git" \
        "git+https://github.com/allyourcodebase/mbedtls.git" \
        "git+https://github.com/allyourcodebase/libxml2.git"; do
        zig fetch --save "$spec" 2>/dev/null || echo "zig fetch $spec 失败(无 Zig 包镜像,GitHub 直下)"
    done
    ls build.zig.zon 2>/dev/null && echo "zig-prewarm zon 已生成;缓存: /opt/zig-cache" || echo "!! zig fetch 全失败"
    true
}

LIBCACHE_ALL=(go rust python node java pwsh dotnet zig)
run_category LIBCACHE_ALL "$@"

# Python 库缓存(re-venv 扩展 + wheelhouse)

> 逆向/CTF 向 19 个 PyPI 包装进 /opt/re-venv、轮子下载进 /opt/wheelhouse,断网 pip 免索引重装 ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh python`

- **版本钉**:19 包 `uv pip install` 构建日最新未钉(`PIP_INDEX` 默认阿里云镜像);wheelhouse 轮子与 re-venv 同批构建日快照;RsaCtfTool `--depth 1` 未钉。升级=有网阶段重跑本组
- **来源与安装**:PyPI 经 `PIP_INDEX`(common.sh);脚本面 `scripts/install-libcache.sh` `install_python()`——`uv pip install` 19 包进 `$RE_VENV`(默认 /opt/re-venv,单包失败只 echo 不中断)→ venv 内装 pip 后 `pip download -d /opt/wheelhouse --index-url $PIP_INDEX` 拉轮子 → RsaCtfTool 克隆 `/opt/RsaCtfTool` 并 `uv pip install -r requirements.txt` 把依赖锁进同一 venv
- **落点**:`/opt/re-venv`(19 包 + RsaCtfTool 依赖,与逆向五库/工具同一 venv);`/opt/wheelhouse`(pip 轮子离线重装源);`/opt/RsaCtfTool`(参考克隆);volatility3 的 CLI 链 `/usr/local/bin/{vol,volshell}`
- **配置与缓存**:运行期消费面是 `/etc/pip.conf`(install-runtimes.sh python 组写):`[install] no-index=true find-links=/opt/wheelhouse`,`pip install <轮子内包>` 免旗标直装;uv 面是 `/etc/uv/uv.toml` `offline=true`(runtimes uv 组)。机制见 [offline.md](../../offline.md) §1/§4
- **离线行为**:✅ 轮子内包断网直装实证(五生态快失败轮,`pip --no-index` 在断网冒烟清单):`ip link set eth0 down` 后 `pip install --no-index --find-links /opt/wheelhouse pefile` 退 0;✅ 轮子外的包立即 No matching distribution 快失败;vol/volshell 断网可用 ☐ [推断:二进制与依赖全在 /opt/re-venv 盘上,运行不触网]
- **坑与留痕**:uv 无 `pip download` 子命令,须先给 venv 装 pip 再拉轮子(`pip download` 不受 pip.conf `[install]` 节影响,构建期不被离线面拦);volatility3 的 CLI 随包装进 venv,不链出就没有 vol 命令;只锁 requirements 断网等于没装(没有索引可解析),必须固化轮子字节;uv 不合并配置——用户级 `~/.config/uv/uv.toml` 一旦存在,系统级 `/etc/uv/uv.toml` 整份被忽略,离线默认随之失效(实证 uv 0.12.15,[ADR-0004](../../adr/ADR-0004-offline-first-fail-fast.md))

成员清单(19 包 + RsaCtfTool,以脚本 `install_python()` 为准):

| 类 | 成员 |
|---|---|
| 密码/数学 | pycryptodome、cryptography、gmpy2、sympy、z3-solver |
| 格式解析 | construct、pefile、pyelftools、dnfile |
| 取证/恶意代码 | pypykatz、malduck、volatility3(CLI vol/volshell) |
| 调试/HTTP | r2pipe、httpx |
| 杂项 | beautifulsoup4、lxml、pyjwt、dpkt、xortool |
| RSA 题框架 | RsaCtfTool(`--depth 1` 克隆 /opt/RsaCtfTool,依赖锁进 re-venv) |

# Python 库缓存

> 逆向与 CTF 向 Python 库固化:re-venv 扩展 + wheelhouse ｜ 状态:缓存固化 ｜ 组:`install-libcache.sh python`

## 版本

- 19 个 PyPI 包逐件锁定版本,键为 `PYPI_PIN[<包>]`;缺少锁定版本即失败,不静默漂移。
- 示例锁定值:pycryptodome 3.24.0;volatility3 2.28.2;z3-solver 5.1.0.0(解析日 2026-10-10)。
- RsaCtfTool 按 `GIT_PIN[RsaCtfTool/RsaCtfTool]` 锁定提交。
- wheelhouse 轮子按同一组锁定值执行 `pip download`。
- 升级:运行 `scripts/resolve-pins.sh` 更换锁定版本,在有网阶段重跑本组。本层无独立锁文件,锁定在 pins.sh。

## 来源与安装

- 脚本:`scripts/install-libcache.sh` 的 `install_python`。
- PyPI 索引:`PIP_INDEX`(common.sh)。
- 步骤:
  1. `uv pip install` 19 个包进 /opt/re-venv;单包失败仅记录,不中断。
  2. venv 内安装 pip,`pip download -d /opt/wheelhouse` 拉取轮子。
  3. 克隆 RsaCtfTool 到 /opt/RsaCtfTool,`uv pip install -r requirements.txt` 将依赖装入同一 venv。

## 文件

| 路径 | 内容 |
| --- | --- |
| /opt/re-venv | 19 个包与 RsaCtfTool 依赖;与逆向五库、工具同一 venv |
| /opt/wheelhouse | pip 轮子;离线重装源 |
| /opt/RsaCtfTool | 参考克隆 |
| /usr/local/bin/vol、/usr/local/bin/volshell | volatility3 CLI |

## 配置

- /etc/pip.conf(install-runtimes.sh python 组写入):`[install] no-index=true`、`find-links=/opt/wheelhouse`。轮子内的包免旗标直装。
- /etc/uv/uv.toml(runtimes uv 组写入):`offline=true`。
- 机制说明见 [offline.md](../../offline.md) 第 1 节与第 4 节。

## 离线行为

- 支持:轮子内包直装。关闭 eth0 后,`pip install --no-index --find-links /opt/wheelhouse pefile` 退出码 0。
- 支持:轮子外的包立即报 No matching distribution,不挂起。
- 未验证:vol 与 volshell 的运行;二进制与依赖全在盘上,无网络动作。

## 限制

- uv 没有 `pip download` 子命令;须先给 venv 装 pip 再拉轮子。`pip download` 不受 pip.conf `[install]` 节影响,构建期不被离线面拦截。
- 只锁 requirements 而不固化轮子字节时,断网无法解析依赖,等同未安装。
- volatility3 的 CLI 随包装进 venv;不链出则没有 vol 命令。
- uv 不合并配置:用户级 `~/.config/uv/uv.toml` 一旦存在,系统级 `/etc/uv/uv.toml` 整份失效,离线默认随之失效(uv 0.12.15 实测,0.13 未重测)。

## 参见

- [offline.md](../../offline.md)
- [known-issues.md](../../known-issues.md)

## rctl 收录行

- rctl: vol kind=tool path=/usr/local/bin/vol env=工具环境 note=volatility3 CLI(PYPI_PIN 单独锁定,re-venv 链出)
- rctl: volshell kind=tool path=/usr/local/bin/volshell env=工具环境
- rctl: netexec kind=tool path=/usr/local/bin/netexec env=工具环境 note=NetExec(原 CrackMapExec 续作,re-venv 链出)
- rctl: floss kind=tool path=/usr/local/bin/floss env=逆向环境 note=FLARE 伪代码字符串提取(re-venv 链出)

## 成员清单

19 个包 + RsaCtfTool,以脚本 `install_python` 为准。

| 类 | 成员 |
| --- | --- |
| 密码/数学 | pycryptodome、cryptography、gmpy2、sympy、z3-solver |
| 格式解析 | construct、pefile、pyelftools、dnfile |
| 取证/恶意代码 | pypykatz、malduck、volatility3(CLI:vol、volshell) |
| 调试/HTTP | r2pipe、httpx |
| 杂项 | beautifulsoup4、lxml、pyjwt、dpkt、xortool |
| RSA 题框架 | RsaCtfTool(锁定 sha 克隆 /opt/RsaCtfTool,依赖锁进 re-venv) |

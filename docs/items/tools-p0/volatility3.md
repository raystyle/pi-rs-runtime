# volatility3

> 内存取证框架(CLI:vol/volshell)｜ 状态:已装 ｜ 组:`install-tools.sh re`(re-venv 链出)

- **版本钉**:pins.sh `PYPI_PIN[volatility3]`
- **来源与安装**:uv pip 进 re-venv,vol/volshell 链 /usr/local/bin;轮子在 wheelhouse(重装面)
- **落点**:`/opt/re-venv`,入口 `/usr/local/bin/vol`、`volshell`
- **配置与缓存**:符号表按需(缺符号的内存镜像离线面受限,属语料边界)
- **离线行为**:过,CLI 本地读;2026-10-11 从 libcache/python 册拆出一事实一册,原处留链接
- **坑与留痕**:内存取证是工具环境不是逆向(prt-09 裁)

- rctl: vol kind=tool path=/usr/local/bin/vol env=工具环境 note=volatility3 CLI
- rctl: volshell kind=tool path=/usr/local/bin/volshell env=工具环境

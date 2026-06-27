# windows-config

这是 `spmw` 的 Windows 配置仓库。

`spmw` 本身只提供能力层；本仓库提供实际配置，包括要安装的 packages、用户目录 links、开始菜单 shortcuts 等。`spmw` 会把本仓库作为特殊的 `main` package 同步到本地，然后读取其中的 `config.spmw.json` 生成安装计划。

## 文件

- `config.spmw.json`：主配置文件。
- `user/`：同步到用户目录的配置文件，例如 `.wezterm.lua`。

当前配置包含：

- `CascadiaNextSC`：安装 Cascadia Next SC Nerd Font。
- `TermSCP`：安装 `termscp.exe`，并链接到 `~/.local/bin`。
- `WezTerm`：安装 WezTerm nightly，并在开始菜单 `SPMW` 子菜单中创建快捷方式。

## 同步方式

生产环境中，`spmw` 会通过 GitHub Atom feed 读取本仓库 `main` 分支的最新 commit，然后下载该 commit 对应的 source tarball：

```text
https://github.com/hh9527/windows-config/commits/main.atom
https://github.com/hh9527/windows-config/archive/<commit>.tar.gz
```

这样下载地址由 commit 固定，避免可变 URL 进入 package 安装流程。

## 本地开发

在 `spmw` 仓库中，`tws/links/windows-config` 指向本仓库。执行：

```bash
tws/pack-tarballs.sh
python3 tws/serve.py --host 127.0.0.1 --port 10922
```

Windows 侧通过 SSH 端口转发后 bootstrap：

```powershell
$env:SPMW_DEV_HOST = "127.0.0.1:10922"
irm "http://127.0.0.1:10922/bootstrap.ps1" | iex
```

存在 `SPMW_DEV_HOST` 时，`spmw update` 会采用本地配置优先，便于调试覆盖远端配置。

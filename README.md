# windows-config

这是 `spmw` 的 Windows 配置仓库。

`spmw` 本身只提供能力层；本仓库提供实际配置，包括要安装的 packages、用户目录 links、开始菜单 shortcuts 等。`spmw` 会把本仓库作为特殊的 `main` package 同步到本地，然后读取其中的 `config.spmw.json` 生成安装计划。

## 文件

- `config.spmw.json`：主配置文件。
- `bootstrap.ps1`：一键 bootstrap 入口。
- `user/`：同步到用户目录的配置文件，例如 `.wezterm.lua`。

当前配置包含：

- `main`：同步本仓库自身。
- `spmw`：安装/更新 `spmw` 能力层。
- `CascadiaNextSC`：安装 Cascadia Next SC Nerd Font。
- `TermSCP`：安装 `termscp.exe`，并链接到 `~/.local/bin`。
- `WezTerm`：安装 WezTerm nightly，并在开始菜单 `SPMW` 子菜单中创建快捷方式。

## Bootstrap

Windows 上执行：

```powershell
irm "https://raw.githubusercontent.com/hh9527/windows-config/main/bootstrap.ps1" | iex
```

`bootstrap.ps1` 会下载 `spmw` latest release 的 `spmw.tar.gz` 到 `~/.spmw/bootstrap/`，从完整配置中过滤出只包含 `main`、`spmw` 和正式 CLI link 的 bootstrap config，然后先用 bootstrap CLI 安装正式 `spmw-cli.ps1`，再切换到正式 CLI 完成完整安装。

## 同步方式

生产环境中，`spmw` 会通过 GitHub Atom feed 读取本仓库 `main` 分支的最新 commit，然后下载该 commit 对应的 source tarball：

```text
https://github.com/hh9527/windows-config/commits/main.atom
https://github.com/hh9527/windows-config/archive/<commit>.tar.gz
```

这样下载地址由 commit 固定，避免可变 URL 进入 package 安装流程。

## 本地开发

在 `spmw` 仓库中生成 dev 分发产物，然后和本仓库的 bootstrap/config 放到同一个 HTTP 根目录：

```bash
cd ../spmw
scripts/make-dist.sh dev target

mkdir -p /tmp/spmw-bootstrap
cp target/spmw.*.tar.gz target/spmw.tar.gz.sha256 /tmp/spmw-bootstrap/
cp ../windows-config/bootstrap.ps1 ../windows-config/config.spmw.json /tmp/spmw-bootstrap/
python3 -m http.server 10922 --bind 127.0.0.1 --directory /tmp/spmw-bootstrap
```

Windows 侧通过 SSH 端口转发后 bootstrap：

```powershell
$env:SPMW_DEV_HOST = "127.0.0.1:10922"
irm "http://127.0.0.1:10922/bootstrap.ps1" | iex
```

存在 `SPMW_DEV_HOST` 时，`spmw update` 会采用本地配置优先，便于调试覆盖远端配置。

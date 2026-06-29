# windows-config

这是 `spmw` 的 Windows 配置仓库。

`spmw` 本身只提供能力层；本仓库提供实际配置，包括要安装的 packages、用户目录 links、开始菜单 shortcuts 等。`spmw` 会把本仓库作为 `source.main` 同步到本地，然后读取其中的 `config.spmw.json` 生成安装计划。

## 文件

- `config.spmw.json`：主配置文件。
- `user/`：同步到用户目录的配置文件，例如 `.wezterm.lua`。

当前配置包含：

- `CascadiaNextSC`：安装 Cascadia Next SC Nerd Font。
- `TermSCP`：安装 `termscp.exe`，并链接到 `~/.local/bin`。
- `WezTerm`：安装 WezTerm nightly，并在开始菜单 `SPMW` 子菜单中创建快捷方式。

## 安装

先安装 [`spmw`](https://github.com/hh9527/spmw)，然后在 Windows 上执行：

```powershell
spmw-cli.ps1 source add main gh-src:hh9527/windows-config/main
spmw-cli.ps1 update
spmw-cli.ps1 install
```

这会把本仓库追加为本机 source，并安装本仓库声明的配置。

## 同步方式

生产环境中，`spmw-cli.ps1 source add main gh-src:hh9527/windows-config/main`
会向 `~/sources.spmw.json` 写入 `source.main`。`spmw update` 会通过 GitHub
Atom feed 读取本仓库 `main` 分支的最新 commit，然后下载该 commit 对应的
source tarball：

```text
https://github.com/hh9527/windows-config/commits/main.atom
https://github.com/hh9527/windows-config/archive/<commit>.tar.gz
```

这样下载地址由 commit 固定，避免可变 URL 进入 package 安装流程。

## 本地开发

在 `spmw` 仓库中生成 dev 分发产物：

```bash
cd ../spmw
scripts/make-dist.sh dev
python3 -m http.server 10922 --bind 127.0.0.1 --directory dev-dist
```

Windows 侧通过 SSH 端口转发后，先按 `spmw` 仓库说明安装 dev 版本，再执行：

```powershell
spmw-cli.ps1 source add main gh-src:hh9527/windows-config/main
spmw-cli.ps1 update
spmw-cli.ps1 install
```

如果要调试本仓库的本地改动，可以先提交到临时分支，然后把 `gh-src` 的 branch
段改为对应分支名。

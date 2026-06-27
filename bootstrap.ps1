Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$WindowsConfigUrl = "https://raw.githubusercontent.com/hh9527/windows-config/main/config.spmw.json"
$SpmwTarballUrl = "https://github.com/hh9527/spmw/releases/latest/download/tarball.tar.gz"

$UserProfile = [Environment]::GetFolderPath("UserProfile")
$SpmwRoot = Join-Path $UserProfile ".spmw"
$BootstrapRoot = Join-Path $SpmwRoot "bootstrap"
$BootstrapConfigPath = Join-Path $BootstrapRoot "bootstrap.config.json"
$InstalledCli = Join-Path $UserProfile ".local\bin\spmw-cli.ps1"

if ([string]::IsNullOrWhiteSpace($env:SPMW_DEV_HOST)) {
    $ConfigUrl = $WindowsConfigUrl
} else {
    $BaseUrl = "http://$env:SPMW_DEV_HOST"
    $ConfigUrl = "$BaseUrl/config.spmw.json"
    $SpmwSha256Url = "$BaseUrl/sha256.txt"
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Invoke-Download {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutFile
    )

    Ensure-Directory (Split-Path -Parent $OutFile)
    $tmp = "$OutFile.tmp"
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Force
    }

    Write-Host "fetching $Url ..."
    & curl.exe -fL --progress-bar --retry 3 --connect-timeout 20 -o $tmp $Url
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $Url"
    }
    Move-Item -LiteralPath $tmp -Destination $OutFile -Force
}

function Invoke-ReadText {
    param([Parameter(Mandatory)][string]$Url)

    Write-Host "reading $Url ..."
    $text = & curl.exe -fLsS --retry 3 --connect-timeout 20 $Url
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $Url"
    }
    return ([string]::Join("`n", @($text))).Trim()
}

Ensure-Directory $SpmwRoot

$fullConfig = Invoke-ReadText -Url $ConfigUrl
$config = $fullConfig | ConvertFrom-Json
if (-not $config.packages.main -or -not $config.packages.spmw) {
    throw "bootstrap config requires packages.main and packages.spmw"
}
$bootstrapConfig = [ordered]@{
    schema = if ($config.schema) { $config.schema } else { 1 }
    packages = [ordered]@{
        main = $config.packages.main
        spmw = $config.packages.spmw
    }
}
if ($config.links -and $config.links."bin:spmw-cli.ps1") {
    $bootstrapConfig["links"] = [ordered]@{
        "bin:spmw-cli.ps1" = $config.links."bin:spmw-cli.ps1"
    }
} else {
    throw "bootstrap config requires links.'bin:spmw-cli.ps1'"
}

if (-not [string]::IsNullOrWhiteSpace($env:SPMW_DEV_HOST)) {
    $sha256 = Invoke-ReadText -Url $SpmwSha256Url
    $SpmwTarballUrl = "$BaseUrl/tarball.$sha256.tar.gz"
}

$tarball = Join-Path $SpmwRoot "bootstrap.tar.gz"
Invoke-Download -Url $SpmwTarballUrl -OutFile $tarball

if (Test-Path -LiteralPath $BootstrapRoot) {
    Remove-Item -LiteralPath $BootstrapRoot -Recurse -Force
}
Ensure-Directory $BootstrapRoot
Set-Content -Encoding UTF8 -Path $BootstrapConfigPath -Value ($bootstrapConfig | ConvertTo-Json -Depth 80)

& tar.exe -xf $tarball -C $BootstrapRoot
if ($LASTEXITCODE -ne 0) {
    throw "tar failed for $tarball"
}

$cli = Join-Path $BootstrapRoot "bin\spmw-cli.ps1"
if (-not (Test-Path -LiteralPath $cli)) {
    throw "Missing spmw cli in bootstrap tarball: $cli"
}

& powershell.exe -ExecutionPolicy Bypass -File $cli update -Bootstrap $BootstrapConfigPath
if ($LASTEXITCODE -ne 0) {
    throw "bootstrap spmw update failed"
}

& powershell.exe -ExecutionPolicy Bypass -File $cli install
if ($LASTEXITCODE -ne 0) {
    throw "bootstrap spmw install failed"
}

if (-not (Test-Path -LiteralPath $InstalledCli)) {
    throw "Missing installed spmw cli: $InstalledCli"
}

& powershell.exe -ExecutionPolicy Bypass -File $InstalledCli update
if ($LASTEXITCODE -ne 0) {
    throw "spmw update failed"
}

& powershell.exe -ExecutionPolicy Bypass -File $InstalledCli install
if ($LASTEXITCODE -ne 0) {
    throw "spmw install failed"
}

Write-Host "SPMW bootstrap complete"

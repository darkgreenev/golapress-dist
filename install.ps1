$ErrorActionPreference = "Stop"

$Repo = "darkgreenev/golapress-dist"
$Version = if ($args.Count -gt 0) { $args[0] } else { "latest" }
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($env:PROCESSOR_ARCHITECTURE -notin @("AMD64", "x86_64")) {
    throw "install.ps1 currently supports Windows amd64 only."
}

$Asset = "golapress-windows-amd64.zip"
if ($Version -eq "latest") {
    $Url = "https://github.com/$Repo/releases/latest/download/$Asset"
} else {
    $Url = "https://github.com/$Repo/releases/download/$Version/$Asset"
}

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("golapress-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    $ZipPath = Join-Path $TempDir $Asset
    Write-Host "Downloading $Asset from $Url"
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath

    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "bin") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "data\media") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "themes") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "plugins") | Out-Null

    Copy-Item -Path (Join-Path $TempDir "golapress-windows-amd64\golapress.exe") -Destination (Join-Path $RootDir "bin\golapress.exe") -Force

    $EnvPath = Join-Path $RootDir ".env"
    if (-not (Test-Path $EnvPath)) {
        Copy-Item -Path (Join-Path $RootDir ".env.example") -Destination $EnvPath
        Write-Host "Created .env from .env.example. Change ADMIN_PASSWORD before exposing the app."
    }

    Write-Host "Installed goLaPress to $(Join-Path $RootDir 'bin\golapress.exe')"
    Write-Host "Run: .\examples\run-windows.ps1"
} finally {
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
}

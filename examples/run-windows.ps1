$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

$EnvPath = Join-Path $RootDir ".env"
if (Test-Path $EnvPath) {
    Get-Content $EnvPath | ForEach-Object {
        $Line = $_.Trim()
        if ($Line -eq "" -or $Line.StartsWith("#")) { return }
        $Parts = $Line.Split("=", 2)
        if ($Parts.Count -eq 2) {
            [Environment]::SetEnvironmentVariable($Parts[0].Trim(), $Parts[1].Trim(), "Process")
        }
    }
}

if (-not $env:APP_ENV) { $env:APP_ENV = "production" }
if (-not $env:APP_PORT) { $env:APP_PORT = "8076" }
if (-not $env:APP_URL) { $env:APP_URL = "http://localhost:$env:APP_PORT" }
if (-not $env:DB_DRIVER) { $env:DB_DRIVER = "sqlite" }
if (-not $env:DB_DSN) { $env:DB_DSN = "file:./data/golapress.db?_foreign_keys=on" }
if (-not $env:MEDIA_DIR) { $env:MEDIA_DIR = "./data/media" }

New-Item -ItemType Directory -Force -Path "data\media" | Out-Null
New-Item -ItemType Directory -Force -Path "themes" | Out-Null
New-Item -ItemType Directory -Force -Path "plugins" | Out-Null

& ".\bin\golapress.exe"

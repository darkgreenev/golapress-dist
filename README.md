# goLaPress Distribution

This repository is the public binary distribution for goLaPress.

The application source code is not published here. This repo contains installer scripts, runtime examples, release metadata, and links to downloadable binaries.

## Quick Start: Linux

```bash
git clone https://github.com/darkgreenev/golapress-dist.git
cd golapress-dist
./install.sh
```

Edit `.env` and change `ADMIN_PASSWORD`, then run:

```bash
./examples/run-linux.sh
```

Open:

- Public site: `http://localhost:8076`
- Admin: `http://localhost:8076/admin`

## Quick Start: Windows PowerShell

```powershell
git clone https://github.com/darkgreenev/golapress-dist.git
cd golapress-dist
.\install.ps1
```

Edit `.env` and change `ADMIN_PASSWORD`, then run:

```powershell
.\examples\run-windows.ps1
```

## Configuration

The installer creates `.env` from `.env.example` if it does not already exist.

Important settings:

- `APP_URL`: public origin, default `http://localhost:8076`
- `APP_PORT`: listen port, default `8076`
- `DB_DRIVER`: `sqlite` by default
- `DB_DSN`: SQLite database path
- `MEDIA_DIR`: uploaded media directory
- `ADMIN_EMAIL`: initial admin email
- `ADMIN_PASSWORD`: initial admin password. Change this before exposing the app.

## Release Assets

Latest release metadata is tracked in:

- `latest.json`
- `checksums.txt`

Binaries are attached to GitHub Releases instead of being committed to git history.

Expected release assets:

- `golapress-linux-amd64.tar.gz`
- `golapress-linux-arm64.tar.gz`
- `golapress-windows-amd64.zip`
- `checksums.txt`
- `latest.json`

## Runtime Data

The default local layout is:

```text
golapress-dist/
  bin/
  data/
    golapress.db
    media/
  themes/
  plugins/
  .env
```

Back up `data/` before replacing binaries.

# goLaPress

goLaPress is a focused CMS written in Go. It uses a WordPress-familiar content model and admin flow while keeping the runtime narrow: server-rendered admin screens, MySQL-first production persistence, native Go services, bounded hooks, trusted plugins, and template-based themes.

## Quick Start

Prerequisites:

- Go 1.21 or newer
- local filesystem access

Start the app:

```bash
make run
```

or:

```bash
./scripts/dev.sh
```

Explicit local database modes:

```bash
make run-sqlite
make run-mysql
```

Open:

- public site: `http://localhost:8076`
- admin: `http://localhost:8076/admin`
- health: `http://localhost:8076/healthz`
- readiness: `http://localhost:8076/readyz`

Default local admin login for `scripts/dev.sh`:

- email: `admin@example.com`
- password: `admin12345`

Set `ADMIN_PASSWORD` before using any shared or remote environment.

Local dev database behavior:

- `./scripts/dev.sh` loads `.env` as defaults when that file exists.
- already-exported shell variables still win over `.env`.
- if neither the shell nor `.env` sets `DB_DRIVER`, the script falls back to SQLite.
- this repo's local `.env` may point at MySQL, so `make run` is not guaranteed to mean SQLite.
- use `make run-sqlite` or `make run-mysql` when you want an explicit local mode.

## Docker

Copy the environment template and adjust the admin password:

```bash
cp .env.example .env
```

Start with Compose:

```bash
docker compose up --build
```

Compose starts MySQL by default and stores database data, uploaded media, installed themes, and installed plugins in named volumes.

### Pre-built Binary Variants (No Go Install Required)

For a quick start using the latest released binary:

- **Standalone (Standard):** `./scripts/run-standard.sh` (or `make docker-standard`). This uses local `./data`, `./themes`, and `./plugins` folders on your host.
- **All-in-One (withData):** `./scripts/run-with-data.sh` (or `make docker-with-data`). This includes a MySQL database inside the container.
- **VPS install without Docker:** `./scripts/install-vps.sh --site-dir /var/www/golapress --db-dsn 'user:pass@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'`. See [docs/vps_binary_install.md](docs/vps_binary_install.md).

These methods:
1. Automatically fetch the latest `golapress` binary from the [distribution repo](https://github.com/darkgreenev/golapress-dist).
2. Configure the admin account automatically.
3. Avoid a local Go toolchain.
4. The VPS installer uses `systemd` when available and falls back to a managed background process when it is not.

## Development Commands

```bash
make run            # start local dev server using exported vars or .env defaults
make run-sqlite     # force local SQLite dev mode
make run-mysql      # force local MySQL dev mode
make test           # run Go tests
make test-mysql     # run MySQL integration test through Docker Compose
make build          # build bin/golapress
go run ./cmd/golapress snapshot-site # create an ignored DB backup under APP_SITE_DIR/backups
make docker-up      # start with Docker Compose
make docker-dev     # start Compose with local data/themes/plugins bind mounts
make docker-standard # run standard binary variant with host data volume
make docker-with-data # run all-in-one binary variant with MySQL
make docker-down
```

For Docker-based development with local state and local theme/plugin folders mounted into the container:

```bash
make docker-dev
```

This uses `compose.dev.yaml` on top of the default Compose file.

## Configuration

The main environment variables are:

- `APP_URL`: public origin, default `http://localhost:8076`
- `APP_SITE_DIR`: path to the site directory containing `data/`, `themes/`, and `plugins/`, default `./my-site`
- `APP_SITE_GIT_INIT`: automatically run `git init` at the site directory if it is not already a repo, default `true`
- `APP_UPDATE_LATEST_URL`: release metadata URL used by the admin self-updater
- `APP_HOST`: listen host, default `0.0.0.0` (all interfaces)
- `APP_PORT`: listen port, default `8076`
- `SMTP_RELAY_URL`, `SMTP_RELAY_TOKEN`: outbound email relay settings for future password-reset mail delivery
- `DB_DRIVER`: `mysql` or `sqlite`; contributor `scripts/dev.sh` falls back to `sqlite` only when neither the shell nor `.env` sets it
- `DB_DSN`: MySQL or SQLite DSN; contributor `scripts/dev.sh` falls back to `file:./my-site/data/golapress.db?_foreign_keys=on` only when neither the shell nor `.env` sets it
- `MEDIA_DIR`: uploaded media directory
- `PLUGINS_DIR`: trusted local plugin manifest directory
- `THEMES_DIR`: local installed theme directory
- `APP_DEV_RELOAD_ENABLED`: enables the development-only admin reload action when `APP_ENV=development`
- `APP_TRUSTED_PROXY_HEADERS`: enable forwarded client IP header handling, default `false`
- `APP_TRUSTED_PROXY_CIDRS`: comma-separated trusted reverse proxy IPs/CIDRs; forwarded client IP headers are ignored unless the immediate peer matches one of these entries
- `ENABLED_PLUGINS`: comma-separated startup-enabled plugin IDs
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_DISPLAY_NAME`
- `SESSION_COOKIE_NAME`, `SESSION_TTL`

See [.env.example](.env.example) for the current template.

## Current Feature Surface

- posts, pages, categories, and public category archives
- revisions and restore flows for pages and posts
- media upload, listing, metadata editing, replacement, deletion, serving, and featured images
- server-rendered admin screens
- admin/editor auth with session cookies and policy helpers
- active theme selection, native theme zip upload/install, and bundled default theme rendering
- trusted plugin discovery, persisted enable/disable actions, and built-in activity-log plus SEO plugins
- security audit log screen for login/logout/password events
- bounded hook bus with public theme-render plus content/media lifecycle events
- MySQL-first bootstrap migrations plus explicit SQLite support for local development and small installs

## Project Docs

- [docs/](docs/) contains architecture and strategy notes.
- [docs/local_mysql_dev.md](docs/local_mysql_dev.md) covers the explicit local MySQL contributor workflow.
- [todos/](todos/) contains genuinely open implementation follow-ups.
- [workdone/](workdone/) contains completed implementation records moved out of the active todo queue.
- [deployments/README.md](deployments/README.md) covers the current deployment path.

## Scope Limits

The current delivery path is intentionally MySQL-first for production and distribution installs. SQLite remains supported for local development, tests, and small explicit installs. Public plugin marketplaces, arbitrary third-party runtime loading, broad WordPress compatibility, and production Postgres automation are not part of the current slice.

Current plugin behavior:

- a folder under `plugins/*/plugin.json` makes a plugin discoverable in admin/API surfaces
- a plugin becomes activatable when it has either a compiled-in trusted runtime implementation or a valid external executable declared in `plugin.json`
- this is not yet a public ABI or marketplace installation model

Recommended database posture:

- use SQLite for local development, evaluations, internal tools, and single-node production deployments with disciplined backups
- use MySQL for production and distribution installs
- treat SQLite-to-MySQL migration as maintenance tooling; `golapress migrate-store --dry-run` validates source/target readiness, and `--confirm` copies known database tables into an empty MySQL target before a manual operator cutover; successful migration writes completed runtime metadata and still requires an explicit `DB_DRIVER=mysql` cutover

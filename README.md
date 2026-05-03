# goLaPress

goLaPress is a focused CMS written in Go. It uses a WordPress-familiar content model and admin flow while keeping the runtime narrow: server-rendered admin screens, SQLite-first local persistence, native Go services, bounded hooks, trusted plugins, and template-based themes.

## Quick Start

Prerequisites:

- Go 1.21 or newer
- SQLite-compatible local filesystem access

Start the app:

```bash
make run
```

or:

```bash
./scripts/dev.sh
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

## Docker

Copy the environment template and adjust the admin password:

```bash
cp .env.example .env
```

Start with Compose:

```bash
docker compose up --build
```

Compose stores SQLite data and uploaded media in the `golapress_data` named volume.

### Self-Contained Docker Trial (One Command)

For a quick trial with MySQL and the latest release binary in a single, self-contained container:

```bash
./trial.sh
```

(Or `make docker-trial` if you have `make` installed).

This method:
1. Builds a Docker image based on Ubuntu.
2. Installs and starts a local MySQL service inside the container.
3. Automatically fetches the latest `golapress` binary from the [distribution repo](https://github.com/darkgreenev/golapress-dist).
4. Configures the database and admin account automatically.

No host-level dependencies (other than Docker) are required.

## Development Commands

```bash
make run        # start local dev server
make test       # run Go tests
make test-mysql # run MySQL integration test through Docker Compose
make build      # build bin/golapress
make docker-up  # start with Docker Compose
make docker-dev # start Compose with local data/themes/plugins bind mounts
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
- `APP_PORT`: listen port, default `8076`
- `SMTP_RELAY_URL`, `SMTP_RELAY_TOKEN`: outbound email relay settings for future password-reset mail delivery
- `DB_DRIVER`: `sqlite` or `mysql`, default `sqlite`
- `DB_DSN`: SQLite or MySQL DSN, default `file:./data/golapress.db?_foreign_keys=on`
- `MEDIA_DIR`: uploaded media directory
- `PLUGINS_DIR`: trusted local plugin manifest directory
- `APP_DEV_RELOAD_ENABLED`: enables the development-only admin reload action when `APP_ENV=development`
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
- bounded hook bus with public theme-render plus content/media lifecycle events
- SQLite-first bootstrap migrations plus fresh MySQL install support covered by `make test-mysql`

## Project Docs

- [docs/](docs/) contains architecture and strategy notes.
- [todos/](todos/) contains genuinely open implementation follow-ups.
- [workdone/](workdone/) contains completed implementation records moved out of the active todo queue.
- [deployments/README.md](deployments/README.md) covers the current deployment path.

## Scope Limits

The current delivery path is intentionally SQLite-first and single-node. Public plugin marketplaces, arbitrary third-party runtime loading, broad WordPress compatibility, and production Postgres automation are not part of the current slice.

Current plugin behavior:

- a folder under `plugins/*/plugin.json` makes a plugin discoverable in admin/API surfaces
- a plugin only becomes activatable when the binary includes a matching trusted runtime implementation
- this is not yet a public ABI or marketplace installation model

Recommended database posture:

- use SQLite for local development, evaluations, internal tools, and single-node production deployments with disciplined backups
- choose MySQL at install time when you need an external database or a production posture that exceeds filesystem-level SQLite backup and restore workflows
- treat SQLite-to-MySQL migration as maintenance tooling; `golapress migrate-store --dry-run` validates source/target readiness, and `--confirm` copies known database tables into an empty MySQL target before a manual operator cutover; successful migration writes completed runtime metadata and still requires an explicit `DB_DRIVER=mysql` cutover

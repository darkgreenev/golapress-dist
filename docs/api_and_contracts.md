# API And Contracts

This document lists the public-facing contracts that plugin authors, theme authors, operators, and AI agents can rely on in a goLaPress install.

It is not a full internal architecture dump. It is the current operational contract.

## Site Layout

The main site-owned areas are:

- `data/`: database files, logs, backups, admin-managed env files
- `themes/`: installed local themes
- `plugins/`: installed local plugins

On VPS installs the application binary is usually outside the site directory, for example:

- binary: `/usr/local/bin/golapress`
- site: `/var/www/golapress`

## Main Runtime Configuration

Common environment variables:

- `APP_URL`
- `APP_PORT`
- `APP_SITE_DIR`
- `DB_DRIVER`
- `DB_DSN`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
- `CODEX_AI_ENABLED`
- `CODEX_RUNTIME`
- `CODEX_API_KEY`
- `CODEX_MODEL`

Operator-managed Codex settings are typically written to `data/admin.env`.

## Public HTTP Routes

Current public route families include:

- `/`
- `/healthz`
- `/readyz`
- `/wp-json`
- `/robots.txt`
- `/sitemap.xml`
- `/account`
- `/account/login`
- `/account/register`
- `/account/logout`
- `/account/profile`
- `/account/password`
- `/account/forgot-password`
- `/account/reset-password`
- `/media/`
- `/category/`
- `/preview/appearance`
- `/preview/share/`
- `/preview/pages/`
- `/preview/posts/`
- `/posts/`
- `/p/`
- `/plugins/`
- `/assets/`

Notes:

- `/plugins/` is the public mount point for plugin-owned routes.
- `/assets/` serves theme assets.
- `/p/` serves pages.
- `/posts/` serves posts.

## Admin HTML Routes

Current admin route families include:

- `/admin`
- `/admin/login`
- `/admin/forgot-password`
- `/admin/reset-password`
- `/admin/logout`
- `/admin/assets/`

## JSON API Routes

Current JSON API routes are mounted under `/api/v1/`.

Current families include:

- `/api/v1/bootstrap`
- `/api/v1/login`
- `/api/v1/logout`
- `/api/v1/password-reset/request`
- `/api/v1/password-reset/confirm`
- `/api/v1/me`
- `/api/v1/themes`
- `/api/v1/themes/:id`
- `/api/v1/themes/active`
- `/api/v1/themes/default`
- `/api/v1/settings`
- `/api/v1/settings/theme`
- `/api/v1/types`
- `/api/v1/statuses`
- `/api/v1/taxonomies`
- `/api/v1/plugins`
- `/api/v1/plugins/:id`
- `/api/v1/media`
- `/api/v1/media/:id`
- `/api/v1/users`
- `/api/v1/users/:id`
- `/api/v1/categories`
- `/api/v1/categories/:slug`
- `/api/v1/tags`
- `/api/v1/tags/:slug`
- `/api/v1/comments`
- `/api/v1/comments/:id`
- `/api/v1/menus`
- `/api/v1/menus/:id`
- `/api/v1/menu-locations`
- `/api/v1/posts`
- `/api/v1/posts/:slug`
- `/api/v1/pages`
- `/api/v1/pages/:slug`

These are the right surfaces for structured admin integrations. They are preferable to scraping HTML or mutating database tables directly.

## Theme Contract

Themes are directory-based installs with a required `theme.json` manifest and HTML templates.

The usual structure is:

```text
my-theme/
├── theme.json
├── templates/
└── assets/
```

Themes should rely on:

- Go `html/template` syntax
- the host-provided render context
- documented plugin slot names

See `theme_development.md`.

## Plugin Contract

Plugins are discovered from immediate child directories under `plugins/` that contain a `plugin.json`.

Current manifest fields include:

- `id`
- `name`
- `version`
- `author`
- `description`
- `enabled_by_default`
- `executable`
- `type`
- `migrations`
- `field_registrations`
- `slot_registrations`
- `shortcode_registrations`

Current plugin types:

- `builtin`
- `binary`

Plugin IDs must be lowercase slug-style identifiers.

See `plugin_development.md`.

## Binary Plugin RPC Contract

Binary plugins use Hashicorp `go-plugin`.

Handshake values:

- protocol version: `1`
- magic cookie key: `GOLAPRESS_PLUGIN_MAGIC_COOKIE`
- magic cookie value: `nature-is-awesome`

The main RPC service contract includes:

- `Register`
- `HandleHook`
- `HandleFilter`
- `HandleRequest`
- `HandleSlot`
- `HandleShortcode`

Registered structures include:

- hook registrations
- admin menus
- admin pages
- routes
- slots
- shortcodes

## Render Slots

Current public plugin slot names:

- `site_header_after`
- `site_footer_before`
- `archive_item_after_title`
- `archive_item_after_excerpt`
- `post_before_title`
- `post_after_title`
- `post_after_body`
- `page_before_title`
- `page_after_title`
- `page_after_body`
- `content_actions`
- `notice_area`

Themes and plugins should match these names exactly.

## Hook And Filter Contract

The current stable filter name is:

- `render.context.filter`

Current lifecycle hook names and payload shapes are documented in `hook_reference.md`.

## AI Runtime Contract

The built-in assistant depends on:

- `CODEX_AI_ENABLED=true`
- a supported runtime
- `codex` being available on `PATH` for the goLaPress process user when using `local`
- either a saved API key or a valid Codex CLI login

For CLI login on current Codex releases, use:

```bash
codex login
```

On root-run VPS installs:

```bash
sudo codex login
```

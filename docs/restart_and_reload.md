# Restart And Reload

This page explains when goLaPress needs only a browser refresh, when a source-checkout development run needs a dev reload, and when the app process itself must restart.

## Rule Of Thumb

- Content changes usually do **not** need an app restart.
- Source code changes in a development checkout usually need a **development reload**.
- Runtime or binary changes usually need an **app restart**.

## No Restart

These changes should apply on the next request or after a normal browser refresh:

- posts and pages
- featured images and media metadata
- categories, tags, menus, and revisions
- General settings
- Reading settings
- Appearance settings
- theme content overrides
- theme activation
- installed theme import and activation
- admin shell background appearance

Examples:

- remove a featured image from a post, save, then refresh the front end
- change site title or tagline, save, then refresh the affected page
- change theme appearance or theme-content settings, save, then refresh

## Development Reload

Use a development reload when you are running goLaPress from a source checkout and the running process needs a rebuilt binary.

Typical cases:

- Go code changes in `cmd/` or `internal/`
- local plugin source changes that affect the running app process
- bundled theme or bundled asset changes that are compiled into the binary

Use:

- `./scripts/dev.sh`
- `make run`
- `make run-mysql`
- `make run-sqlite`

Do not run the compiled dev binary directly when `APP_DEV_RELOAD_ENABLED=true`. The documented wrapper is what rebuilds and restarts after `/admin/dev/reload`.

In development runtime mode:

- `/admin/dev/reload` requests a development reload
- `/admin/runtime/restart` also routes to development reload when supported

## App Restart

Restart the app process when the running runtime configuration or executable must change.

Current cases:

- binary update or rollback
- released-binary upgrade via installer
- runtime env changes that are read from admin env or startup config
- switching assistant provider settings that differ from the running config
- changing Codex runtime, key, enablement, or model when the running process still has different values
- changing Gemini runtime, key, enablement, or model when the running process still has different values
- changing SMTP relay URL or token when the running process still has different values

The System settings screen already marks these with:

- `System settings saved. Restart the app to apply the saved system settings.`

## CSS, JS, And Templates

The correct action depends on where the file lives.

No restart:

- CSS or JS served from a filesystem theme under `themes/<theme-id>/...`
- template edits in a filesystem theme used by the running install

Refresh or hard-refresh the browser first. If a cache is in the way, invalidate that cache.

Development reload or restart:

- CSS, JS, or templates that are bundled into the compiled binary
- source-checkout code paths that are not served from the live site filesystem

## Installed And VPS Deployments

For released-binary installs:

- rerun `install-vps.sh` for upgrades or repair flows
- use `systemctl restart golapress` when the installer created a systemd service
- use the managed loop launcher when the install is using fallback loop mode

## Docker And Containers

For container installs:

- content and database-backed settings do not need a container restart
- binary replacement or image/runtime changes do
- `Tools > Updates` may restart the current process after update or rollback

## Current Mapping Summary

- post/page/media/taxonomy/navigation changes: no restart
- General settings: no restart
- Reading settings: no restart
- Appearance and theme-content settings: no restart
- System settings affecting assistant or SMTP runtime: app restart
- source-checkout Go code changes: development reload
- released binary update or rollback: app restart

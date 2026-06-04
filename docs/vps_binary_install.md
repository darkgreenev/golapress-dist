# VPS Binary Install Without Docker

This guide is for public installs that use the released `golapress` binary from `golapress-dist`. It is not the contributor workflow for the private source repository.

You do not need to clone `golapress-dist` for this path. Use the versioned installer asset from the latest public release.

Use this path when you have a VPS or bare Linux server and do not want Docker.

## What The Installer Does

Run the interactive installer:

```bash
bash <(curl -fsSL https://github.com/darkgreenev/golapress-dist/releases/latest/download/install-vps.sh)
```

The script:

- is shipped as a versioned release asset in `golapress-dist`
- downloads the latest Linux release binary from `golapress-dist` metadata
- can ask interactive setup questions when you run it without flags in a terminal
- remembers the last non-sensitive values it used in `~/.local/state/golapress/install.state` when available
- asks password-style prompts twice in interactive mode so typos are caught before write-out
- derives `APP_PORT` from the port in the interactive `App URL` when one is present
- installs the binary, defaulting to `/usr/local/bin/golapress` for root installs and `$HOME/.local/bin/golapress` for non-root installs
- defaults the site directory to `./golapress-site` under the current working directory unless you override `--site-dir`
- creates the site directory with `data/`, `themes/`, and `plugins/`
- writes a safe site `.env.example` template with placeholder secret values
- writes a site `.env` file for non-secret launcher settings
- writes real secrets such as `DB_DSN` and `ADMIN_PASSWORD` to `data/runtime.env`
- writes Codex admin defaults to `data/admin.env`
- writes a site-level `README.md` with operator help and a link to the public docs site
- writes site-level `AGENTS.md` and `gemini.md` instruction files when they do not already exist
- seeds or updates the site `.gitignore` so `.env`, `data/runtime.env`, `data/admin.env`, logs, sessions, backups, and other runtime artifacts stay out of Git
- can inspect and restore a site package before the first app start when you pass `--restore-site-package`
- plugin repos can ship their own setup scripts for plugin-specific vendor credentials while internal Commerce trust uses the shared `GOLAP_CORE_TRUST_SECRET` in `data/runtime.env`
- starts goLaPress with MySQL by default
- can provision a MySQL database and application user when explicitly requested
- can install Node.js, npm, and `@openai/codex` when explicitly requested
- installs and starts a `systemd` service when `systemd` is available and the script is run as root
- falls back to a background process with `data/golapress.pid` and `data/golapress.log` when `systemd` is unavailable
- can use `--fallback-mode loop` so a non-`systemd` install restarts the app automatically after normal process exits or crashes

Supported Linux release architectures are `linux_amd64` and `linux_arm64`.

If you prefer to save a copy locally first and still avoid `chmod`:

```bash
curl -fsSL -o install-vps.sh https://github.com/darkgreenev/golapress-dist/releases/latest/download/install-vps.sh
bash install-vps.sh
```

For non-interactive installs with explicit flags:

```bash
bash install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

For fresh-server restore from a portable site package:

```bash
bash install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --db-driver mysql \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --restore-site-package /root/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz
```

For encrypted packages, add:

```bash
  --site-package-passphrase 'package-secret'
```

## Required Inputs

Set these values for a real VPS:

- `--site-dir`: where site-owned files live, for example `/var/www/golapress`
- `--app-url`: the public URL, for example `https://example.com`
- `--admin-password`: the initial admin password
- `--db-dsn`: the MySQL DSN when using the default MySQL path

The default admin email is `admin@example.com`. Override it with:

```bash
bash install-vps.sh \
  --admin-email owner@example.com \
  --admin-password 'use-a-long-random-password'
```

## Using .env With install-vps.sh

`install-vps.sh` auto-loads a `.env` file from the current working directory when one is present.

That is useful when you do not want to repeat a long install command every time.

Example operator `.env`:

```bash
APP_SITE_DIR=/var/www/golapress
APP_URL=http://www.everlive.net:8076
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=adminpass
DB_DRIVER=mysql
DB_DSN='golapress:mypass@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
CODEX_AI_ENABLED=true
CODEX_RUNTIME=local
```

Then run:

```bash
bash install-vps.sh
```

Configuration precedence is:

1. explicit command-line flags
2. exported shell environment variables
3. `.env` in the current working directory
4. built-in script defaults

The installer also keeps a local convenience cache of the last non-sensitive interactive values, such as site directory, app URL, admin email, admin display name, database driver, and Codex/runtime choices. It does not store passwords or other secrets in that cache.
That cache is only used to prefill prompts in the interactive wizard. It does not override explicit flags or environment variables.

On fresh installs and upgrades, the installer seeds `AGENTS.md` and `gemini.md` at the site root if they are missing. It does not overwrite existing copies, so local site-specific edits are preserved.
The same rule applies to the site `.gitignore`: the installer adds the required ignore entries when they are missing, but it does not replace the file wholesale, so any local custom ignore rules stay intact.

So if you keep most values in `.env`, you can still override one-off values with flags:

```bash
bash install-vps.sh --app-url https://example.com
```

## MySQL Default

MySQL is the default database for this installer.

If you omit `--db-driver`, the installer uses:

```text
DB_DRIVER=mysql
```

If you omit `--db-dsn`, the installer uses the local development-style default:

```text
golapress:golapress@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8
```

For production or shared VPS use, pass your actual DSN explicitly:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver mysql \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

By default, the installer does not create the MySQL database or user. Create them first:

```sql
CREATE DATABASE golapress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'golapress'@'localhost' IDENTIFIED BY 'strong-db-password';
GRANT ALL PRIVILEGES ON golapress.* TO 'golapress'@'localhost';
FLUSH PRIVILEGES;
```

### Optional MySQL Provisioning

If you want the installer to create the application database and user on an existing MySQL server, add:

```bash
--mysql-create-db
```

Required flags for that mode:

- `--mysql-db-name`
- `--mysql-db-user`
- `--mysql-db-password`

Optional flags for the MySQL admin connection:

- `--mysql-root-user`
- `--mysql-root-password`
- `--mysql-root-host`
- `--mysql-root-port`
- `--mysql-app-host`
- `--mysql-dsn-host`
- `--mysql-dsn-port`

Example:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver mysql \
  --mysql-create-db \
  --mysql-root-user root \
  --mysql-root-password 'root-password' \
  --mysql-db-name golapress \
  --mysql-db-user golapress \
  --mysql-db-password 'strong-db-password'
```

In that mode, the installer runs `CREATE DATABASE`, `CREATE USER`, `ALTER USER`, `GRANT`, and `FLUSH PRIVILEGES`.

The MySQL admin connection now uses TCP when `--mysql-root-host` is set. The default root host is `127.0.0.1`, not `localhost`, to avoid Unix socket permission failures during non-root installer runs.

If you do not pass `--db-dsn`, the installer also builds the goLaPress DSN automatically from the created app user, password, and database name.

## SQLite Opt-In

Use SQLite only when the operator explicitly asks for the no-MySQL path:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver sqlite
```

When `--db-driver sqlite` is used and no DSN is supplied, the installer generates:

```text
file:/var/www/golapress/data/golapress.db?_foreign_keys=on
```

SQLite is useful for small single-node installs, trials, and simple internal sites. MySQL remains the default VPS path.

## systemd Installs

When `systemd` is available and the script runs as root, it writes:

```text
/etc/systemd/system/golapress.service
```

Useful commands:

```bash
systemctl status golapress
systemctl restart golapress
systemctl stop golapress
journalctl -u golapress -f
```

## Backup Verification And Restore

Create a database snapshot:

```bash
golapress snapshot-site
```

Create a portable full-site package for migration or fresh-server restore:

```bash
golapress package-site
```

Create an encrypted package:

```bash
golapress package-site --encrypt-passphrase 'package-secret'
```

Verify a backup artifact before restoring it:

```bash
golapress restore-check --file backups/mysql/golapress_YYYY-MM-DD_HHMMSS.sql.gz
golapress restore-check --file backups/sqlite/golapress_YYYY-MM-DD_HHMMSS.db.gz
```

The restore check is non-destructive. It confirms the artifact is a readable gzip archive with a supported goLaPress database payload.

Inspect a site package before restoring it elsewhere:

```bash
golapress inspect-site-package --file backups/site-packages/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz
```

For encrypted packages:

```bash
golapress inspect-site-package \
  --file backups/site-packages/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz.enc \
  --passphrase 'package-secret'
```

For fresh-server restore, site packages are now the preferred path because they include the database backup plus selected site files:

- `.env`
- `.env.example`
- `data/runtime.env`
- `data/admin.env`
- `data/site.json`
- `data/media/`
- `themes/`
- `plugins/`

Restore a full site package on the target server:

```bash
golapress restore-site-package \
  --site-dir /var/www/golapress \
  --file backups/site-packages/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz \
  --mode full \
  --db-driver mysql \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

For encrypted packages:

```bash
golapress restore-site-package \
  --site-dir /var/www/golapress \
  --file backups/site-packages/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz.enc \
  --mode full \
  --db-driver mysql \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --passphrase 'package-secret'
```

For SQLite targets:

```bash
golapress restore-site-package \
  --site-dir /var/www/golapress \
  --file backups/site-packages/golapress_site_YYYY-MM-DD_HHMMSS.tar.gz \
  --mode full \
  --db-driver sqlite \
  --db-dsn 'file:/var/www/golapress/data/golapress.db?_foreign_keys=on'
```

For MySQL restores, you can either use the guided restore wizard in `Tools > Backups` or import the verified SQL dump into the intended database:

```bash
gzip -dc /var/www/golapress/backups/mysql/golapress_YYYY-MM-DD_HHMMSS.sql.gz \
  | mysql --host=127.0.0.1 --port=3306 --user=golapress --password golapress
```

For SQLite restores, stop the app first, replace `data/golapress.db`, then start the app again:

```bash
systemctl stop golapress
gzip -dc /var/www/golapress/backups/sqlite/golapress_YYYY-MM-DD_HHMMSS.db.gz > /var/www/golapress/data/golapress.db
systemctl start golapress
```

Database restore and filesystem restore are separate steps. Themes, plugins, uploads, and runtime env files should come from the site repo, storage snapshot, or external file backup.
The browser restore wizard only handles the MySQL database import; filesystem restore still comes from the site repo, storage snapshot, or external file backup.
Site packages also write a `.sha256` sidecar next to the archive; keep that file with the package and verify it before moving the archive to another server.
If the source site is already running goLaPress, the admin UI under `Tools > Backups` can now drive this site-package flow over SSH with `Clone To Server`, including target validation and optional MySQL install/database provisioning for apt-based Linux hosts. It can also optionally install and configure Caddy on the target so the site is served on the public domain directly after deployment.

The service runs the release binary and sets the runtime environment directly. The site-owned files remain under `--site-dir`.

The service reads its runtime environment from:

```text
/var/www/golapress/.env
/var/www/golapress/data/runtime.env
```

For VPS installs, `install-vps.sh` writes `APP_RUNTIME_MODE=installed` into the managed environment so the admin runtime page reports an installed app process instead of guessing from host container markers.

Rerunning the installer rewrites `.env` and `data/runtime.env` atomically from the supplied flags. It does not create timestamped `.env.bak.*` copies, and it removes legacy `.env.bak.*` files left by older installer runs.

The installer also generates and preserves `GOLAP_CORE_TRUST_SECRET` in `data/runtime.env`, so Commerce and trusted plugins can derive their internal signing keys without per-plugin secret copy/paste.

## No systemd Fallback

When `systemd` is unavailable, or when the script is not run as root, the installer creates:

```text
/var/www/golapress/run-golapress.sh
/var/www/golapress/data/golapress.pid
/var/www/golapress/data/golapress.log
```

If you want the fallback process to restart the app automatically after crashes or normal exits, install with:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --fallback-mode loop
```

That mode also writes:

```text
/var/www/golapress/run-golapress-loop.sh
```

The loop wrapper starts `run-golapress.sh`, waits 5 seconds if the app exits, and starts it again. The PID file points to the wrapper process.

Useful commands:

```bash
tail -f /var/www/golapress/data/golapress.log
kill $(cat /var/www/golapress/data/golapress.pid)
/var/www/golapress/run-golapress.sh
```

Rerunning the installer in this fallback mode now reads `data/golapress.pid`, sends `SIGTERM` to the existing process, waits up to 15 seconds for a clean exit, and only uses `SIGKILL` as a last resort before starting the new copy. This avoids stacking multiple app instances across reinstall or upgrade runs.

Loop mode helps with crashes, but it is still not a full service manager. It does not restart the app after a machine reboot unless something else launches the wrapper again.

For long-term production, prefer a real process supervisor such as `systemd`, `supervisord`, or the VPS provider's service manager.

If the app sits behind a reverse proxy, enable `APP_TRUSTED_PROXY_HEADERS=true` only when the proxy is trusted and controlled by you, and set `APP_TRUSTED_PROXY_CIDRS` to the proxy IPs/CIDRs that are allowed to send `X-Forwarded-For` or `X-Real-IP`. For a same-host proxy, `127.0.0.1/32,::1/128` is the usual starting point.

## Site Directory Layout

The site directory is intentionally separate from the binary:

```text
/var/www/golapress/
  .env.example
  .env
  data/
    admin.env
    runtime.env
    site.json
    media/
    golapress.db
    golapress.log
    golapress.pid
  themes/
  plugins/
```

The binary can be upgraded without replacing site content, themes, uploads, or plugins.

For Git-managed site directories, commit `.env.example` if you want a safe operator template, but keep `.env`, `data/runtime.env`, and `data/admin.env` ignored.

## Upgrades

Run the installer again with the same `--site-dir` and database settings. It downloads the latest binary and restarts the app using the available service mode.

If the site directory already has an existing goLaPress install, the installer now detects it and asks whether to repair or upgrade that install. That repair path rewrites the managed launcher and runtime env files, refreshes the binary, and leaves site-owned content alone.

For MySQL installs:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver mysql \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

For SQLite installs:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver sqlite
```

## Backups

Use the built-in snapshot command after installation.

For MySQL:

```bash
APP_SITE_DIR=/var/www/golapress \
DB_DRIVER=mysql \
DB_DSN='golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
golapress snapshot-site
```

For SQLite:

```bash
APP_SITE_DIR=/var/www/golapress \
DB_DRIVER=sqlite \
DB_DSN='file:/var/www/golapress/data/golapress.db?_foreign_keys=on' \
golapress snapshot-site
```

MySQL backups require `mysqldump` to be installed.

## Enabling The AI Assistant

The AI Assistant in goLaPress supports Codex and Gemini. On a no-Docker VPS, use the `local` runtime.

Codex can use a saved OpenAI API key or a Codex CLI login. Gemini is API-key-first in the current admin product.

References:

- https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
- https://help.openai.com/en/articles/11381614
- https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.md
- https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md

### 1. Install Node.js And The Provider CLI

Install Node.js using your VPS operating system package manager or NodeSource. Then install the CLI you plan to use:

```bash
npm install -g @openai/codex
npm install -g @google/gemini-cli
```

The installer can install Codex for you when requested:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --enable-codex \
  --runtime local \
  --install-codex
```

Installer behavior for `--install-codex`:

- if `codex` is already on `PATH`, it leaves it alone
- if `npm` is missing and the script runs as root on an apt-based system, it installs `nodejs` and `npm`
- then it runs `npm install -g @openai/codex`
- for non-root installs, it uses a user-local npm prefix under `$HOME/.local` and records the resulting `PATH` in the launcher `.env`

For non-root installs, automatic Codex setup requires `npm` to already be available.

OpenAI's Codex CLI setup documentation also supports updating with:

```bash
codex --upgrade
```

Confirm the provider command is visible to the same OS user that runs goLaPress:

```bash
which codex
codex --help
which gemini
gemini --help
```

This matters because goLaPress checks for the selected provider executable on the process `PATH`.

### 2. Install Or Restart goLaPress With Local Runtime Enabled

At install time:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --enable-codex \
  --runtime local \
  --install-codex
```

For an existing install, an admin can also enable it from the UI.

### 3. Configure In Admin

Log in to:

```text
https://example.com/admin
```

Open `Settings > System`, then:

- choose the `Default Provider`
- in the `Codex` section:
  - check `Enable Codex assistant` if you want Codex available
  - choose runtime `Local`
  - choose a model or leave the default
  - enter an OpenAI API key if you are not using `codex login`
- in the `Gemini` section:
  - check `Enable Gemini assistant` if you want Gemini available
  - choose runtime `Local`
  - choose a model or leave the default
  - enter a Gemini API key
- in the `Admin Shell Background` section:
  - choose a media-library image for the admin shell and login screen
  - pick an overlay strength to keep forms and notices readable
- save the settings

The app stores assistant settings in:

```text
/var/www/golapress/data/admin.env
```

The assistant passes the saved Codex key to Codex as `OPENAI_API_KEY` when it runs.

The assistant passes the saved Gemini key to Gemini as `GEMINI_API_KEY` when it runs.

Because `data/admin.env` is the admin-managed settings file, the VPS service does not export assistant provider/runtime keys from `.env`. That keeps the admin UI able to change assistant settings later.

### 4. Confirm The Assistant Is Ready

The assistant is ready when all of these are true:

- `AI_ASSISTANT_PROVIDER` points at the provider you want for new chats
- the selected provider is enabled in `data/admin.env`
- the selected provider runtime is `local` or `auto`
- the selected provider CLI is on `PATH` for the goLaPress process user
- for Codex:
  - the OpenAI API key is saved in admin settings or available in the environment
  - or Codex CLI is already logged in for the goLaPress OS user
- for Gemini:
  - the Gemini API key is saved in admin settings

If the admin screen reports that the assistant is not ready,

check:

```bash
which codex
codex --help
which gemini
gemini --help
systemctl status golapress
journalctl -u golapress -f
```

For no-`systemd` installs, check:

```bash
tail -f /var/www/golapress/data/golapress.log
```

## Runtime Scenarios

### VPS With MySQL

Use the default MySQL path:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

### VPS Without MySQL

Opt in to SQLite:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver sqlite
```

### VPS With AI Assistant

Install the provider CLI first, or let the installer do it for Codex with `--install-codex`, then install with:

```bash
./install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --enable-codex \
  --runtime local \
  --install-codex
```

Then open `Settings > System`, choose the default provider, and save the provider-specific API key if required.

### VPS Behind Nginx

Run goLaPress on the default internal port `8076`, then proxy from Nginx to:

```text
http://127.0.0.1:8076
```

Set:

```bash
--app-url https://example.com
```

Keep `APP_HOST=0.0.0.0` unless you intentionally want the app to bind only to localhost.

## Troubleshooting

### The Site Does Not Start

Check logs:

```bash
journalctl -u golapress -f
```

or:

```bash
tail -f /var/www/golapress/data/golapress.log
```

### MySQL Connection Fails

Verify:

- the database exists
- the user can connect from the goLaPress host
- the DSN contains the correct user, password, host, port, and database name
- the DSN includes `parseTime=true`

Test with:

```bash
mysql -u golapress -p -h 127.0.0.1 golapress
```

### Admin Password Is Wrong

Set a real password at install time:

```bash
--admin-password 'use-a-long-random-password'
```

If the app has already initialized users, changing the environment may not change an existing admin account. Use the admin UI or the database recovery process for existing accounts.

### AI Assistant Is Not Ready

For no-Docker VPS installs, use `Local`, not `Docker`.

Check:

```bash
which codex
codex --help
which gemini
gemini --help
```

If the provider CLI works in your shell but not in goLaPress, the service user likely has a different `PATH`. Install the CLI globally or adjust the service environment so the selected provider binary is visible to the goLaPress process.

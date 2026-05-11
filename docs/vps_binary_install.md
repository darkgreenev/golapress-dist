# VPS Binary Install Without Docker

This guide is for public installs that use the released `golapress` binary from `golapress-dist`. It is not the contributor workflow for the private source repository.

Use this path when you have a VPS or bare Linux server and do not want Docker.

## What The Installer Does

Run:

```bash
./scripts/install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:change-me@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

The script:

- downloads the latest Linux release binary from `golapress-dist`
- installs the binary, defaulting to `/usr/local/bin/golapress` for root installs and `$HOME/.local/bin/golapress` for non-root installs
- creates the site directory with `data/`, `themes/`, and `plugins/`
- writes a site `.env` file used by the service launcher
- writes Codex admin defaults to `data/admin.env`
- starts goLaPress with MySQL by default
- can provision a MySQL database and application user when explicitly requested
- can install Node.js, npm, and `@openai/codex` when explicitly requested
- installs and starts a `systemd` service when `systemd` is available and the script is run as root
- falls back to a background process with `data/golapress.pid` and `data/golapress.log` when `systemd` is unavailable

Supported Linux release architectures are `linux_amd64` and `linux_arm64`.

## Required Inputs

Set these values for a real VPS:

- `--site-dir`: where site-owned files live, for example `/var/www/golapress`
- `--app-url`: the public URL, for example `https://example.com`
- `--admin-password`: the initial admin password
- `--db-dsn`: the MySQL DSN when using the default MySQL path

The default admin email is `admin@example.com`. Override it with:

```bash
./scripts/install-vps.sh \
  --admin-email owner@example.com \
  --admin-password 'use-a-long-random-password'
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
./scripts/install-vps.sh \
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
./scripts/install-vps.sh \
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

If you do not pass `--db-dsn`, the installer also builds the goLaPress DSN automatically from the created app user, password, and database name.

## SQLite Opt-In

Use SQLite only when the operator explicitly asks for the no-MySQL path:

```bash
./scripts/install-vps.sh \
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

The service runs the release binary and sets the runtime environment directly. The site-owned files remain under `--site-dir`.

The service reads its runtime environment from:

```text
/var/www/golapress/.env
```

Rerunning the installer rewrites `.env` from the supplied flags and keeps a timestamped backup beside it.

## No systemd Fallback

When `systemd` is unavailable, or when the script is not run as root, the installer creates:

```text
/var/www/golapress/run-golapress.sh
/var/www/golapress/data/golapress.pid
/var/www/golapress/data/golapress.log
```

Useful commands:

```bash
tail -f /var/www/golapress/data/golapress.log
kill $(cat /var/www/golapress/data/golapress.pid)
/var/www/golapress/run-golapress.sh
```

For long-term production, prefer a real process supervisor such as `systemd`, `supervisord`, or the VPS provider's service manager.

## Site Directory Layout

The site directory is intentionally separate from the binary:

```text
/var/www/golapress/
  .env
  data/
    admin.env
    media/
    golapress.db
    golapress.log
    golapress.pid
  themes/
  plugins/
```

The binary can be upgraded without replacing site content, themes, uploads, or plugins.

## Upgrades

Run the installer again with the same `--site-dir` and database settings. It downloads the latest binary and restarts the app using the available service mode.

For MySQL installs:

```bash
./scripts/install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver mysql \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

For SQLite installs:

```bash
./scripts/install-vps.sh \
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

The AI Assistant in goLaPress wraps the Codex CLI. On a no-Docker VPS, use the `local` runtime.

OpenAI's Codex CLI documentation says the CLI can be installed with `npm install -g @openai/codex`, and current releases use `codex login` for the ChatGPT sign-in flow. goLaPress can also pass a saved OpenAI API key to Codex as `OPENAI_API_KEY` when it launches a session.

References:

- https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
- https://help.openai.com/en/articles/11381614

### 1. Install Node.js And Codex CLI

Install Node.js using your VPS operating system package manager or NodeSource. Then install Codex CLI:

```bash
npm install -g @openai/codex
```

The installer can do this for you when requested:

```bash
./scripts/install-vps.sh \
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

Confirm the `codex` command is visible to the same OS user that runs goLaPress:

```bash
which codex
codex --help
```

This matters because goLaPress checks for a `codex` executable on the process `PATH`.

### 2. Install Or Restart goLaPress With Local Runtime Enabled

At install time:

```bash
./scripts/install-vps.sh \
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

Open `Settings > General`, then in the `Codex AI` section:

- check `Enable Codex assistant`
- choose runtime `Local`
- choose a model or leave `Codex default`
- enter an OpenAI API key
- save the Codex settings

The app stores Codex settings in:

```text
/var/www/golapress/data/admin.env
```

The assistant passes the saved API key to Codex as `OPENAI_API_KEY` when it runs.

Because `data/admin.env` is the admin-managed settings file, the VPS service does not export `CODEX_AI_ENABLED` or `CODEX_RUNTIME` from `.env`. That keeps the admin UI able to change Codex settings later.

### 4. Confirm The Assistant Is Ready

The assistant is ready when all of these are true:

- `CODEX_AI_ENABLED=true`
- `CODEX_RUNTIME=local` or `auto`
- `codex` is on `PATH` for the goLaPress process user
- the OpenAI API key is saved in admin settings or available in the environment, or Codex CLI is already logged in for the goLaPress OS user

If the admin screen says:

```text
AI Assistant is not ready. Enable Codex AI and choose a supported runtime in General settings.
```

check:

```bash
which codex
codex --help
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
./scripts/install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'
```

### VPS Without MySQL

Opt in to SQLite:

```bash
./scripts/install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-driver sqlite
```

### VPS With AI Assistant

Install Codex CLI first, or let the installer do it with `--install-codex`, then install with:

```bash
./scripts/install-vps.sh \
  --site-dir /var/www/golapress \
  --app-url https://example.com \
  --admin-password 'use-a-long-random-password' \
  --db-dsn 'golapress:strong-db-password@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8' \
  --enable-codex \
  --runtime local \
  --install-codex
```

Then save the OpenAI API key from `Settings > General`.

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
```

If `codex` works in your shell but not in goLaPress, the service user likely has a different `PATH`. Install Codex globally or adjust the service environment so the `codex` binary is visible to the goLaPress process.

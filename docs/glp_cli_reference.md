# glp-cli Reference

`glp-cli` is the bounded goLaPress maintenance CLI.

It is designed for operators, automation, and AI-assisted workflows that need one canonical mutation path for site data.

## How To Run

From a distribution install:

```bash
golapress glp-cli <command> <subcommand> [flags]
```

Or with the standalone CLI binary:

```bash
glp-cli <command> <subcommand> [flags]
```

The CLI reads the normal goLaPress environment for database and site settings. Use the standard `DB_DRIVER`, `DB_DSN`, and related site variables for the install you are targeting.

## Output Contract

Use `--json` for machine-readable output.

Successful commands return:

- `ok: true`
- a `result` object with the command kind, action, type, and changed item data

Failed commands return:

- `ok: false`
- an `error` object with a stable code
- a human-readable message
- field-level validation details when available

## Command Groups

### Content

Manage posts and pages:

- `content list`
- `content get`
- `content create`
- `content update`
- `content delete`
- `content publish`
- `content unpublish`
- `content duplicate`

Typical uses:

```bash
glp-cli content list --type post --json
glp-cli content create --type page --slug about --title "About Us" --body-file about.html --json
```

### Taxonomy

Manage categories and tags:

- `taxonomy list`
- `taxonomy create`
- `taxonomy update`
- `taxonomy delete`
- `taxonomy assign`

Typical uses:

```bash
glp-cli taxonomy list --kind category --json
glp-cli taxonomy assign --kind tag --content-id post_123 --terms news,launch --json
```

### Media

Manage uploaded files and media metadata:

- `media list`
- `media import`
- `media replace`
- `media update`
- `media delete`

Typical uses:

```bash
glp-cli media import --file ./hero.jpg --json
glp-cli media update --id media_123 --alt "Hero image" --json
```

### Theme Content

Edit safe theme-content overrides without editing theme files directly:

- `theme-content list`
- `theme-content get`
- `theme-content set`
- `theme-content reset`
- `theme-content export`
- `theme-content import`

Typical uses:

```bash
glp-cli theme-content list --json
glp-cli theme-content set --key homepage.hero.title --value "Welcome" --json
```

### Navigation

Manage menus and menu items:

- `navigation list`
- `navigation get`
- `navigation create`
- `navigation update`
- `navigation delete`
- `navigation duplicate`

Navigation create and update can accept menu items from a JSON file:

```bash
glp-cli navigation create \
  --name "Header" \
  --slug header \
  --location primary \
  --items-file ./menu-items.json \
  --json
```

### Revisions

Inspect and restore page or post revisions:

- `revisions list`
- `revisions get`
- `revisions restore`

Typical uses:

```bash
glp-cli revisions list --type page --slug about --json
glp-cli revisions restore --type post --slug launch-notes --revision-id rev_123 --json
```

## Safety Boundaries

`glp-cli` is intentionally narrower than a general shell tool.

It does not try to be:

- raw SQL administration
- unrestricted theme file editing
- plugin runtime tooling
- arbitrary shell passthrough

Use the admin UI or a dedicated migration tool for tasks outside this surface.

## Best Practice

Use `--json` for automation and AI agents.

Prefer slug-based commands when you want readable scripts, and ID-based commands when you need stable references from another tool.


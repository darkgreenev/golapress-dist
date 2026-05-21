# Plugin Development

This guide covers the public plugin contract for goLaPress installs distributed through `golapress-dist`.

Use this document together with:

- `hook_reference.md`
- `api_and_contracts.md`

## Plugin Types

goLaPress currently recognizes these plugin types:

- `builtin`
- `binary`

Public third-party plugins should usually be `binary` plugins.

## Plugin Folder Layout

Plugins are discovered from immediate child directories under `plugins/` that contain a `plugin.json`.

Typical layout:

```text
plugins/
└── my-plugin/
    ├── plugin.json
    ├── my-plugin
    └── other runtime files
```

## Manifest

Every plugin needs a `plugin.json`.

Minimal example:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "Example binary plugin.",
  "executable": "my-plugin",
  "type": "binary"
}
```

Current manifest fields:

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

Rules:

- `id` must be unique
- `id` must be lowercase and slug-like
- `name` is required
- `version` is required

## Binary Plugin Runtime

Binary plugins run as separate processes and communicate with the host through Hashicorp `go-plugin`.

Handshake values:

- protocol version: `1`
- magic cookie key: `GOLAPRESS_PLUGIN_MAGIC_COOKIE`
- magic cookie value: `nature-is-awesome`

## RPC Service Surface

The plugin service contract includes:

- `Register`
- `HandleHook`
- `HandleFilter`
- `HandleRequest`
- `HandleSlot`
- `HandleShortcode`

The plugin SDK defines the current request and response structs for:

- hook registrations
- admin menu registrations
- admin page registrations
- route registrations
- slot registrations
- shortcode registrations
- proxied HTTP requests
- slot rendering requests
- shortcode rendering requests

## Registering Hooks

Hooks should be registered explicitly by name.

Example:

```go
hooks := []plugins.HookRegistration{
	{Name: "content.post.published", Priority: 10},
}
```

See `hook_reference.md` for the current stable names and payload shapes.

## Registering Routes

Plugins can register host-mounted HTTP route prefixes.

Current route registration fields:

- `Prefix`
- `Area`
- `RenderMode`
- `Methods`
- `RequiresAuth`
- `RequiredRole`
- `CSRFRequired`
- `TimeoutMillis`
- `MenuLinks`

Practical guidance:

- use a unique prefix below `/plugins/`
- use `RenderMode: "theme"` for HTML fragments that should render inside the active theme
- use raw responses for APIs, downloads, redirects, and webhooks

## Registering Admin UI

Plugins can contribute:

- admin menu items
- admin pages

Current admin menu fields:

- `ID`
- `ParentID`
- `Label`
- `Icon`
- `Path`
- `RequiredRole`
- `SortOrder`
- `BadgeText`

Current admin page fields:

- `PluginID`
- `ID`
- `MenuID`
- `Title`
- `Path`
- `RequiredRole`
- `RenderMode`

## Registering Content Fields

Plugins can declare simple custom fields for host-managed content editors.

Current field registration fields:

- `ContentTypes`
- `Key`
- `Label`
- `Type`
- `Required`
- `Options`
- `DefaultValue`
- `AdminPlacement`
- `Metadata`

Use these for light metadata on posts and pages. Use plugin-owned migrations for larger domain models.

## Registering Slots

Plugins can inject trusted HTML fragments into public theme slot points.

Current slot registration fields:

- `PluginID`
- `Slot`
- `Priority`
- `ContentTypes`
- `RouteKinds`

Current public slot names:

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

## Registering Shortcodes

Plugins can register shortcode renderers.

Current shortcode registration fields:

- `PluginID`
- `Name`
- `Description`

The runtime request carries:

- shortcode name
- attributes
- body
- current content metadata
- actor context
- render context

## Plugin-Owned Migrations

Plugins can ship schema migrations in the manifest.

Current migration fields:

- `ID`
- `Driver`
- `UpSQL`
- `DownSQL`

Use plugin migrations for plugin-owned tables such as commerce or workflow data. Avoid writing ad hoc SQL outside migrations for normal lifecycle work.

## What AI Agents Should Prefer

When an AI agent is extending goLaPress through plugins, prefer:

1. a new plugin instead of core edits
2. manifest-declared routes, slots, and fields
3. hook handlers over patching unrelated core files
4. theme slot output over direct theme template rewrites when the goal is extension rather than replacement

## Testing And Verification

At minimum:

- confirm the plugin appears in admin
- enable it from the Plugins screen
- verify routes, hooks, slots, and shortcodes with the active theme
- verify the plugin still starts after a goLaPress restart

If you need deeper implementation examples, inspect the public plugin catalog plugins that match this release line or the corresponding source repository code for the same contract version.

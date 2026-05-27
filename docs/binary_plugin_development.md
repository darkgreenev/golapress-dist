# GolaPress Binary Plugin Development Guide

This guide explains how to build standalone binary plugins for GolaPress. Binary plugins run as separate processes and communicate with the GolaPress host through Hashicorp `go-plugin` using the current RPC-style service contract. This allows you to build plugins in **any language** (Go, Python, Rust, Node.js, etc.) and maintain them in separate repositories.

---

## 1. Architecture Overview

GolaPress uses the [Hashicorp go-plugin](https://github.com/hashicorp/go-plugin) architecture.

1.  **Discovery**: GolaPress scans the `plugins/` directory for subdirectories containing a `plugin.json`.
2.  **Launch**: If enabled, GolaPress executes the `executable` specified in the manifest.
3.  **Handshake**: The host and plugin perform a "magic cookie" handshake to verify they are compatible.
4.  **Communication**: Communication happens over a local Unix Socket (or Named Pipe on Windows) using the `go-plugin` transport and RPC service methods.

---

## 2. The Plugin Manifest (`plugin.json`)

Every plugin must have a `plugin.json` in its root folder.

```json
{
    "id": "my-cool-plugin",
    "name": "My Cool Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "Does amazing things.",
    "executable": "my-plugin-binary",
    "type": "binary"
}
```

*   `id`: Must be unique and slug-friendly (lowercase, dashes).
*   `executable`: The name of the binary file to run (relative to the plugin folder).
*   `type`: Must be `"binary"`.

---

## 3. The Handshake (Security)

To prevent accidental execution of non-plugin binaries, both the Host and Plugin must agree on these values:

*   **ProtocolVersion**: `1`
*   **MagicCookieKey**: `GOLAPRESS_PLUGIN_MAGIC_COOKIE`
*   **MagicCookieValue**: `nature-is-awesome`

---

## 4. Developing in Go (Recommended)

If you are using Go, you can use the internal GolaPress SDK to simplify development.

### Step 1: Define your Plugin
Create a struct that implements the `RPCService` interface.

```go
type MyPlugin struct{}

// Register tells GolaPress which hooks, filters, menus, admin pages, routes, slots, and shortcodes you provide.
func (p *MyPlugin) Register(id string) ([]plugins.HookRegistration, []plugins.HookRegistration, []plugins.AdminMenuRegistration, []plugins.AdminPageRegistration, []plugins.RouteRegistration, []plugins.PluginSlotRegistration, []plugins.ShortcodeRegistration, error) {
    hooks := []plugins.HookRegistration{
        {Name: "content.post.published", Priority: 10},
    }
    routes := []plugins.RouteRegistration{
        {
            Prefix:     "/plugins/my-plugin",
            Area:       "public",
            RenderMode: "theme",
            Methods:    []string{"GET", "POST"},
            MenuLinks: []plugins.RouteMenuLinkRegistration{
                {ID: "shop", Label: "Shop", Path: "/plugins/my-plugin"},
            },
        },
    }
    slots := []plugins.PluginSlotRegistration{
        {Slot: "post_after_title", Priority: 10, ContentTypes: []string{"post"}, RouteKinds: []string{"post"}},
    }
    shortcodes := []plugins.ShortcodeRegistration{
        {Name: "gallery", Description: "Render a plugin gallery."},
    }
    return hooks, nil, nil, nil, routes, slots, shortcodes, nil
}

// HandleHook is called when a registered event occurs.
func (p *MyPlugin) HandleHook(name string, payload []byte) error {
    // Unmarshal the JSON payload into the appropriate struct
    return nil
}

// HandleFilter is called to transform data.
func (p *MyPlugin) HandleFilter(name string, payload []byte) ([]byte, error) {
    return payload, nil
}

// HandleRequest is called for registered plugin-owned HTTP routes.
func (p *MyPlugin) HandleRequest(req plugins.HTTPRequest) (plugins.HTTPResponse, error) {
    return plugins.HTTPResponse{StatusCode: 404}, nil
}

// HandleSlot is called when a theme renders a registered slot.
func (p *MyPlugin) HandleSlot(req plugins.SlotRequest) (plugins.SlotResponse, error) {
    if req.Slot != "post_after_title" {
        return plugins.SlotResponse{}, nil
    }
    return plugins.SlotResponse{HTML: `<div class="plugin-fragment">Commerce fragment</div>`}, nil
}

// HandleShortcode is called when post or page content includes a registered shortcode.
func (p *MyPlugin) HandleShortcode(req plugins.ShortcodeRequest) (plugins.ShortcodeResponse, error) {
    if req.Name != "gallery" {
        return plugins.ShortcodeResponse{}, nil
    }
    return plugins.ShortcodeResponse{HTML: `<div class="plugin-fragment">Gallery fragment</div>`}, nil
}
```

Public route `RenderMode` controls how the host renders plugin responses:

- `raw` or empty: the plugin response is proxied as-is. Use this for APIs, files, webhooks, redirects, and standalone screens.
- `theme`: successful public `GET` HTML responses are treated as trusted fragments and rendered inside the active theme page template. Set `X-GolaPress-Page-Title` and optionally `X-GolaPress-Page-Description` response headers for page metadata. Non-`GET` responses, redirects, errors, and non-HTML responses remain raw.

### Step 2: Main Entrypoint
```go
func main() {
    plugins.ServePlugin(&MyPlugin{})
}
```

---

## 5. Developing in Python (Example)

To build a plugin in Python, you must implement a client/server pair that matches the active `go-plugin` RPC contract.

1.  **Match the RPC contract**: Mirror the methods exposed by the host service definition.
2.  **Output Handshake**: Your script must print the handshake string to `stdout` so the host can connect. The string looks like: `1|1|unix|/tmp/socket_path|net/rpc`. The `go-plugin` Python libraries handle the transport framing.
3.  **Implement Service**: Create a class that responds to the same request/response shape used by the host RPC service.

---

## 6. Available Hooks & Payloads

All payloads are sent as **JSON-encoded bytes**. Common hooks include:

| Hook Name | Payload Type | Description |
| :--- | :--- | :--- |
| `auth.login` | `AuthEventPayload` | User logged in. |
| `content.post.published` | `ContentEventPayload` | A post was published. |
| `content.page.created` | `ContentEventPayload` | A new page was created. |
| `media.created` | `MediaEventPayload` | File uploaded. |

Refer to `internal/hooks/events.go` in the GolaPress core for full payload structures.

---

## 7. Best Practices

1.  **Logging**: Write logs to a file or `stderr`. Do **not** write to `stdout` unless it is part of the plugin protocol, as `stdout` is used for the `go-plugin` handshake.
2.  **Statelessness**: Assume your plugin might be restarted. Persist important data to the GolaPress database or an external DB.
3.  **Performance**: Binary plugins are fast, but avoid heavy processing inside `HandleFilter` as it blocks the main request thread.
4.  **Graceful Shutdown**: Listen for `SIGTERM` to clean up resources before the process is killed.

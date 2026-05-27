# GolaPress Plugin Development Workflow

This guide provides a step-by-step walkthrough for creating a new GolaPress plugin in its own repository, leveraging the `golapress-dist` distribution for development and testing.

Use this together with [Private Plugin Distribution](private_plugin_distribution.html) when you want to package and share the finished plugin outside the official goLaPress catalog.

## Development Mode Contract

For the goLaPress source checkout, "development mode" has a strict meaning:

- the host app runs from the repo source tree
- plugins are discovered from the repo `plugins/` workspace
- workspace plugins run from source with `go run .`
- installed site plugin binaries under `my-site/plugins/` are not the runtime of record for local source development

Do not rely on a packaged plugin binary while iterating on a plugin inside the repo workspace. If the workspace plugin source checkout is incomplete, goLaPress should fail that plugin in development mode instead of silently falling back to an older binary.

## 1. Environment Setup

To develop plugins, you need a running GolaPress instance. You can either use Docker or run the pre-built binary directly on your host machine.

### Option A: Docker Setup (Recommended)
This is the easiest path if you have Docker installed.

1.  **Clone the Distribution Repo**:
    ```bash
    git clone https://github.com/darkgreenev/golapress-dist.git golapress-dev
    cd golapress-dev
    ```
2.  **Start GolaPress**:
    ```bash
    make docker-standard
    ```

### Option B: Binary Setup (Simple)
Use this if you prefer running GolaPress directly on your OS with default settings (SQLite).

1.  **Download the Binary**:
    Go to the [GolaPress Dist Releases](https://github.com/darkgreenev/golapress-dist/releases) and download the archive for your platform (e.g., `golapress-linux-amd64.tar.gz`).

2.  **Extract and Initialize**:
    ```bash
    mkdir golapress-dev
    tar -xzf golapress-linux-amd64.tar.gz -C golapress-dev
    cd golapress-dev
    ```

3.  **Configure**:
    Copy the example environment file and set a password.
    ```bash
    cp .env.example .env
    # Edit .env to set your ADMIN_PASSWORD
    ```

4.  **Run**:
    ```bash
    ./golapress
    ```
    *Access the admin at: `http://localhost:8076/admin`*

### Option C: Manual Clone with Custom MySQL & Port
Use this for advanced local setups where you want to use an external MySQL database and a specific port.

1.  **Clone the Distribution Repo**:
    ```bash
    git clone https://github.com/darkgreenev/golapress-dist.git golapress-dev
    cd golapress-dev
    ```

2.  **Download the Binary**:
    Since the repo doesn't include the binary, download it from [Releases](https://github.com/darkgreenev/golapress-dist/releases) and place it in the `golapress-dev` folder.

3.  **Configure `.env`**:
    Set your custom port and MySQL credentials.
    ```bash
    cp .env.example .env
    ```
    Edit `.env`:
    ```env
    APP_PORT=9000
    APP_URL=http://localhost:9000
    
    DB_DRIVER=mysql
    DB_DSN=myuser:mypassword@tcp(127.0.0.1:3306)/mydbname?parseTime=true&charset=utf8mb4,utf8
    
    ADMIN_PASSWORD=your-secure-password
    ```

4.  **Run**:
    ```bash
    ./golapress
    ```
    *Access the admin at: `http://localhost:9000/admin`*

## 2. Creating Your Plugin Repository

Maintain your plugin in a separate repository to manage its own lifecycle and versions.

1.  **Create a New Repo**: Create a new repository on GitHub (e.g., `my-golapress-plugin`).
2.  **Clone into `plugins/`**: Clone your new repo directly into the `plugins/` directory of your development environment.
    ```bash
    cd plugins
    git clone https://github.com/yourusername/my-golapress-plugin.git
    cd my-golapress-plugin
    ```
    The plugin repository remains independent from the goLaPress core repository. If you clone a plugin into the root repo's `plugins/` directory for local development, keep that path ignored in the parent repo so plugin commits are managed from the plugin repo, not from goLaPress.

## 3. Initializing the Project

GolaPress plugins are Go binaries that communicate through the Hashicorp `go-plugin` RPC contract. Use the GolaPress SDK to simplify implementation.

1.  **Initialize Go Module**:
    ```bash
    go mod init github.com/yourusername/my-golapress-plugin
    ```

2.  **Add the GolaPress SDK**:
    ```bash
    go get github.com/golapress/golapress-dist/sdk
    ```

## 4. Implementation

Create a `main.go` file. Your plugin must implement the `RPCService` interface provided by the SDK.
For richer plugins, the manifest may also declare:

- `migrations`: ordered plugin-owned schema migrations applied by the host on activation
- `field_registrations`: simple custom fields the host can render on page and post edit screens

### Example `main.go`
```go
package main

import (
	"encoding/json"
	"log"
	"github.com/golapress/golapress-dist/sdk/hooks"
	"github.com/golapress/golapress-dist/sdk/plugins"
)

type MyPlugin struct{}

func (p *MyPlugin) Register(id string) ([]plugins.HookRegistration, []plugins.HookRegistration, []plugins.AdminMenuRegistration, []plugins.RouteRegistration, []plugins.PluginSlotRegistration, error) {
	// Register for the "content.post.published" hook
	hooks := []plugins.HookRegistration{
		{Name: "content.post.published", Priority: 100},
	}
	routes := []plugins.RouteRegistration{
		{Prefix: "/plugins/my-plugin", Area: "public", RenderMode: "theme", Methods: []string{"GET", "POST"}},
	}
	slots := []plugins.PluginSlotRegistration{
		{Slot: "post_after_title", Priority: 100, ContentTypes: []string{"post"}, RouteKinds: []string{"post"}},
	}
	return hooks, nil, nil, routes, slots, nil
}

func (p *MyPlugin) HandleHook(name string, payload []byte) error {
	if name == "content.post.published" {
		var data hooks.ContentEventPayload
		if err := json.Unmarshal(payload, &data); err != nil {
			return err
		}
		log.Printf("Post published: %s", data.Title)
	}
	return nil
}

func (p *MyPlugin) HandleFilter(name string, payload []byte) ([]byte, error) {
    // Return the payload unchanged if no filtering is needed
    return payload, nil
}

func (p *MyPlugin) HandleRequest(req plugins.HTTPRequest) (plugins.HTTPResponse, error) {
	return plugins.HTTPResponse{StatusCode: 404}, nil
}

func (p *MyPlugin) HandleSlot(req plugins.SlotRequest) (plugins.SlotResponse, error) {
	if req.Slot != "post_after_title" {
		return plugins.SlotResponse{}, nil
	}
	return plugins.SlotResponse{HTML: `<p>Plugin-rendered fragment.</p>`}, nil
}

// Optional: expose plugin-owned migrations and custom fields through the manifest.
// The host will run migrations it recognizes and render simple fields for matching content types.

func main() {
	plugins.ServePlugin(&MyPlugin{})
}
```

For public routes, `RenderMode: "theme"` makes successful `GET` HTML responses render inside the active theme page template. Return only the plugin page fragment in `Body`, and set `X-GolaPress-Page-Title` for the page title. Leave `RenderMode` empty or use `raw` for APIs, downloads, webhooks, redirects, and standalone responses.

## 5. Plugin Manifest

Create a `plugin.json` in your plugin's root directory. This tells GolaPress how to run your plugin.

```json
{
    "id": "my-cool-plugin",
    "name": "My Cool Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "Does amazing things.",
    "executable": "my-plugin",
    "type": "binary"
}
```

## 6. Building and Testing

1.  **Build the Binary**:
    Compile your plugin into the same folder as the manifest.
    ```bash
    go build -o my-plugin
    ```

2.  **Restart GolaPress**:
    Restart your Docker container or binary. GolaPress will scan the `plugins/` folder, find your manifest, and attempt to launch the executable.

3.  **Verify**:
    Go to **Plugins** in the GolaPress Admin. Your plugin should appear in the list. Click **Enable** to activate it.

Bundled plugins that ship with GolaPress also appear in the admin catalog. Those entries can be installed into the site-owned `plugins/<plugin-id>/` directory before activation, so installed copies live under the site directory instead of the application binary.

## 7. Committing and Publishing

Since your plugin is in its own repository, you can commit and push independently of the GolaPress core.

```bash
git add .
git commit -m "Initial plugin implementation"
git push origin main
```

## 8. Packaging For Private Distribution

If you want another goLaPress site to install your plugin without adding it to the official catalog, package it as a native plugin archive.

1. Build the executable for the target platform.
2. Keep `plugin.json` and the executable in the same plugin directory.
3. Package exactly one plugin directory as `.zip` or `.tar.gz`.
4. Test that package on a released binary or `golapress-dist` install.
5. Share that archive directly with the operator.

Example:

```text
my-cool-plugin/
├── plugin.json
├── my-plugin-binary
└── assets/
```

The receiving operator can install that archive from the admin Add Plugin screen through the native package upload path. This is separate from the official goLaPress catalog.

If the plugin is already installed on a site as an installed private `binary` plugin, the Plugins screen can also export it directly through the `Download Package` action. That produces a shareable `.zip` package from the installed plugin directory.

## Next Steps
- Explore `github.com/golapress/golapress-dist/sdk/hooks` for more event types.
- Read the [Binary Plugin Development Guide](binary_plugin_development.html) for more architectural details.

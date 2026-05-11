# GolaPress Theme Development Guide

Themes in GolaPress control the layout, presentation, and asset bundles of the site. They are primarily HTML templates with a JSON manifest.

---

## 1. Theme Structure

A standard theme follows this directory structure:

```text
my-theme/
├── theme.json           # Theme manifest (REQUIRED)
├── templates/           # HTML templates (REQUIRED)
│   ├── index.html       # Homepage/Blog index
│   ├── page.html        # Single page template
│   └── post.html        # Single post template
└── assets/              # CSS, JS, and Images
    ├── styles.css
    └── screenshot.svg   # Theme preview image
```

---

## 2. The Theme Manifest (`theme.json`)

The `theme.json` defines the identity and capabilities of your theme.

```json
{
  "id": "my-theme",
  "name": "My Custom Theme",
  "version": "1.0.0",
  "author": "Your Name",
  "summary": "A clean, modern theme for GolaPress.",
  "templates": {
    "index": "templates/index.html",
    "page": "templates/page.html",
    "post": "templates/post.html"
  },
  "assets": {
    "stylesheet": "assets/styles.css",
    "screenshot": "assets/screenshot.svg"
  },
  "supports": {
    "navigation": true,
    "menu_locations": ["primary", "footer"]
  }
}
```

---

## 3. Template Syntax

GolaPress uses standard Go `html/template` syntax. Every template receives a `Context` object.

### Common Variables:
*   `{{.Site.Title}}`: The site name.
*   `{{.Page.Title}}`: The title of the current post or page.
*   `{{.Page.Content}}`: The HTML content (already rendered from Markdown/HTML).
*   `{{.Navigation.Primary}}`: The list of links for the primary menu.

### Example `page.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>{{.Page.Title}} - {{.Site.Title}}</title>
    <link rel="stylesheet" href="{{.Theme.Assets.Stylesheet}}">
</head>
<body>
    <header>
        <h1>{{.Site.Title}}</h1>
        <nav>
            {{range .Navigation.Primary}}
                <a href="{{.URL}}">{{.Label}}</a>
            {{end}}
        </nav>
    </header>

    <article>
        <h2>{{.Page.Title}}</h2>
        <div class="content">
            {{.Page.Content}}
        </div>
    </article>
</body>
</html>
```

---

## 4. Customizing Appearance

Themes can define custom fields for the GolaPress Admin "Appearance" settings.

```json
"supports": {
  "appearance": {
    "fields": [
      {
        "key": "theme_accent_color",
        "label": "Accent Color",
        "type": "color",
        "default_value": "#21759b"
      }
    ]
  }
}
```

These values are accessible in templates via `{{.Theme.Settings.theme_accent_color}}`.

---

## 5. Deployment

1.  Zip your theme folder.
2.  Go to **Appearance > Themes** in GolaPress Admin.
3.  Click **Upload Theme** and select your ZIP file.
4.  Activate the theme.

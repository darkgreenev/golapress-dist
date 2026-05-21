# goLaPress Theme Development Guide

Themes in goLaPress are directory-based installs with a `theme.json` manifest plus Go `html/template` HTML templates.

This guide focuses on the current public runtime contract that theme authors and AI agents can safely rely on.

## Theme Structure

A standard theme looks like this:

```text
my-theme/
├── theme.json
├── templates/
│   ├── index.html
│   ├── page.html
│   └── post.html
└── assets/
    ├── styles.css
    └── screenshot.svg
```

## Theme Manifest

Current manifest shape:

```json
{
  "id": "my-theme",
  "name": "My Custom Theme",
  "version": "1.0.0",
  "author": "Your Name",
  "summary": "A clean, modern theme for goLaPress.",
  "templates": {
    "home": "templates/index.html",
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
    "menu_locations": ["primary", "footer"],
    "widget_areas": [
      {
        "id": "footer_widgets",
        "label": "Footer Widgets"
      }
    ],
    "appearance": {
      "logo": true,
      "accent_color": true,
      "header_styles": ["classic", "centered"],
      "footer_styles": ["minimal", "split"],
      "button_styles": ["solid", "outline"],
      "typography_styles": ["serif", "sans"]
    }
  }
}
```

Notes:

- `templates.home` is optional.
- `templates.index`, `templates.page`, and `templates.post` are the main public template entrypoints.
- runtime stylesheet loading should use `.Site.StylesheetURL`, not a raw manifest asset path in templates.

## Template Runtime Contract

goLaPress uses standard Go `html/template` syntax.

Do not invent template fields. Use only the documented runtime roots and fields.

### Common Root Objects

Current root objects vary by template, but the stable public set includes:

- `.Site`
- `.Theme`
- `.Slots`
- `.SEO`
- `.Pages`
- `.Posts`
- `.FeaturedPosts`
- `.NotePosts`
- `.Categories`
- `.Pagination`
- `.ArchiveTitle`
- `.ArchiveDescription`
- `.Preview`
- `.Page`
- `.Post`
- `.FeaturedMedia`
- `.BodyHTML`

### `.Site` Fields

Current public `.Site` fields include:

- `Title`
- `URL`
- `Tagline`
- `StylesheetURL`
- `CustomCSS`
- `CustomHeadHTML`
- `CustomFooterHTML`
- `HomeURL`
- `PostsURL`
- `AccentColor`
- `AccentColorStrong`
- `HeaderVariant`
- `FooterVariant`
- `ButtonVariant`
- `TypographyVariant`
- `ThemeSettings`
- `AppearanceClasses`
- `Logo`
- `PrimaryNavigation`
- `FooterNavigation`
- `NavigationByLocation`
- `WidgetAreas`

### Common Mistakes To Avoid

Do not use these outdated or incorrect patterns:

- `{{ .Page.Content }}`
- `{{ .Navigation.Primary }}`
- `{{ .Theme.Assets.Stylesheet }}`
- `{{ .Theme.Settings.some_key }}`

Use these instead:

- `{{ .BodyHTML }}`
- `{{ range .Site.PrimaryNavigation }}...{{ end }}`
- `{{ .Site.StylesheetURL }}`
- `{{ index .Site.ThemeSettings "some_key" }}`

## Example `page.html`

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ .SEO.Title }}</title>
  {{ .Site.CustomHeadHTML }}
  {{ if .Site.StylesheetURL }}<link rel="stylesheet" href="{{ .Site.StylesheetURL }}">{{ end }}
  <style>{{ .Site.CustomCSS }}</style>
</head>
<body class="{{ .Site.AppearanceClasses }}">
  <header>
    <a href="{{ .Site.HomeURL }}">{{ .Site.Title }}</a>
    <nav>
      {{ range .Site.PrimaryNavigation }}
        <a href="{{ .URL }}">{{ .Label }}</a>
      {{ end }}
    </nav>
  </header>

  <main class="detail detail--page">
    {{ index .Slots "page_before_title" }}
    <article>
      <h1>{{ .Page.Title }}</h1>
      {{ index .Slots "page_after_title" }}
      <div class="content">
        {{ .BodyHTML }}
      </div>
      {{ index .Slots "page_after_body" }}
    </article>
  </main>

  <footer>
    {{ index .Slots "site_footer_before" }}
    {{ .Site.CustomFooterHTML }}
  </footer>
</body>
</html>
```

## Post And Archive Guidance

- Use `.Posts`, `.FeaturedPosts`, `.NotePosts`, `.Pages`, and `.Categories` for repeatable listing sections.
- Use `.Post.Title`, `.Post.Excerpt`, `.Post.Categories`, and `.BodyHTML` in `post.html`.
- Use `.Page.Title` and `.BodyHTML` in `page.html`.
- For post summary links, use the provided `.URL` or `.Slug` contract, not hardcoded guesses.
- Keep page and post layouts visually aligned with the homepage design rather than treating them as generic fallback templates.

## Appearance And Theme Settings

Themes can declare bounded appearance controls in `supports.appearance`.

Theme-owned runtime values are exposed through:

- `.Site.ThemeSettings`
- `.Site.AccentColor`
- `.Site.HeaderVariant`
- `.Site.FooterVariant`
- `.Site.ButtonVariant`
- `.Site.TypographyVariant`
- `.Site.AppearanceClasses`

Example:

```html
{{ with index .Site.ThemeSettings "theme_accent_note" }}
  <p class="theme-note">{{ . }}</p>
{{ end }}
```

Use `index` only for map-backed data like:

- `.Site.ThemeSettings`
- `.Site.NavigationByLocation`
- `.Site.WidgetAreas`
- `.Slots`

## Slots And Plugin Output

Themes can render plugin-owned slot output with:

```html
{{ index .Slots "site_footer_before" }}
```

Current public slot names are documented in `api_and_contracts.md`.

## Deployment

1. Zip the theme folder.
2. Open `Appearance > Themes` in goLaPress admin.
3. Upload the ZIP.
4. Activate the theme.

After activation, verify homepage, page, post, and any plugin public routes that should render inside the active theme.

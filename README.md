# jekyll-og-image

Jekyll plugin that automatically generates Open Graph images for your posts and pages using headless Chrome.

## Requirements

- Ruby >= 3.0
- Jekyll >= 4.0
- Chrome or Chromium installed on the machine

## Installation

Add to your site's Gemfile. To run in development only:

```ruby
group :development, :jekyll_plugins do
  gem "jekyll-og-image"
end
```

Then run `bundle install`. Do not add it to the `plugins:` list in `_config.yml` — Bundler loads it automatically via the `:jekyll_plugins` group.

## Usage

This plugin is intended to run in development only. Generate images locally and commit them to your repository — they will be served in production without the plugin running.

Generated images are saved to `assets/og/{slug}.png` and copied back to your source directory so they persist across builds and can be committed. On subsequent builds, existing images are skipped.

Since the plugin does not run in production, do not rely on `page.og_image` being set. Instead, derive the image path from the page URL directly — it is always predictable:

```html
{% assign og_slug = page.url | remove_first: "/" | replace: "/", "-" | remove: ".html" %}
{% if og_slug == "" %}{% assign og_slug = "index" %}{% endif %}
<meta property="og:image" content="{{ site.url }}/assets/og/{{ og_slug }}.png">
```

## Configuration

All configuration is optional. Add an `og_image` key to `_config.yml`:

```yaml
og_image:
  output_dir: assets/og    # where to write generated images
  layouts_dir: _og/layouts # where layout files live
  force: false             # set true to regenerate existing images
  quiet: false             # set true to suppress log output
  templates:
    - collection: posts
      template: _og/post.html
    - collection: page
      template: _og/page.html
    - collection: recipes
      template: _og/recipe.html
    - path: /recipes/my-special-recipe
      template: _og/special.html
```

### Template rules

Only documents covered by at least one rule are processed. Each rule matches by either:

- `collection` — the collection name: `posts`, `page`, or any custom collection (e.g. `recipes`)
- `path` — a glob matched against the document's URL (e.g. `/blog/**`)

`path` rules always take priority over `collection` rules, regardless of their order in the config. This lets you override the template for a specific page even if it belongs to a collection that has its own rule.

If a matching rule has no `template` key, the gem's built-in default template is used.

Set `template: false` to skip OG image generation for matched documents:

```yaml
og_image:
  templates:
    - collection: page
      template: false
```

### Custom templates

Templates are Liquid files. The following variables are available:

Templates have access to the same variables as any Jekyll layout:

| Variable | Description |
|---|---|
| `page` | All front matter and computed fields for the document (e.g. `page.title`, `page.url`, `page.date`, `page.tags`) |
| `site` | Site-wide data from `_config.yml` and Jekyll (e.g. `site.title`, `site.posts`, `site.data`) |

Templates support layouts via front matter, similar to Jekyll:

```
_og/
  layouts/
    base.html      ← shared structure, renders {{ content }}
  post.html        ← post-specific, declares layout: base
  page.html        ← page-specific, declares layout: base
```

**`_og/post.html`:**
```html
---
layout: base
---
<div class="post-card">{{ title }}</div>
```

**`_og/layouts/base.html`:**
```html
<html>
  <body style="width:1200px;height:630px">
    {{ content }}
  </body>
</html>
```

Images are captured at 1200×630px, the standard OG image size.

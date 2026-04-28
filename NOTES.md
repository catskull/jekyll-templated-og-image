# jekyll-og-image

Jekyll plugin gem that generates Open Graph images for pages and posts using a headless browser (Ferrum/Chrome).

## How it works

1. Jekyll Generator iterates all posts and pages
2. Renders a Liquid HTML template with the page's title, date, and tags
3. Opens the HTML in headless Chrome via Ferrum
4. JS in the template handles the stipple texture (canvas) and auto-sizing the title text
5. Screenshots the viewport at 1200x630 and saves to `assets/og/{slug}.png`
6. Copies the PNG back to source so it gets committed and skipped on future builds

## Design

- Stippled texture background (canvas, randomized each generation)
- White card with black border and drop shadow
- Title: bold italic, auto-sizes from 160px down to 32px to fit
- Date: formatted like "April 21, 2026"
- Tags: displayed as hashtags, bottom-left of card, wraps without breaking individual tags
- CATSKULL.net ASCII art stamp: bottom-right of card
- Pages without a title use the URL path (with zero-width spaces after slashes for wrapping)
- Pages without tags just omit them

## Project structure

```
jekyll-og-image.gemspec
Gemfile
lib/
  jekyll-og-image.rb              # entry point
  jekyll-og-image/
    generator.rb                  # Jekyll::Generator subclass
    template/
      og-image.html               # Liquid + CSS + JS template
og-preview.html                   # browser mockup (for design iteration)
test.rb                           # standalone test script
test-output/                      # generated test images
```

## Dependencies

- `ferrum` gem (~> 0.15) - talks to Chrome via DevTools Protocol
- Chrome/Chromium installed on the machine
- Jekyll >= 4.0

## Key implementation details

- Use `browser.resize(width: 1200, height: 630)` NOT `window_size` in constructor - `window_size` includes Chrome UI chrome and gives a smaller viewport
- Use `browser.screenshot(path:)` for full viewport capture (not `selector:` which clips)
- Template body is set to exactly 1200x630 with `overflow: hidden` and the `.og-image` div is absolutely positioned at top-left
- Title auto-sizing is done via JS: starts at 160px, steps down by 2px until `scrollHeight <= clientHeight`
- URL-style titles get zero-width spaces after slashes: `.gsub("/", "/\u200B")`
- `sleep 0.5` after page load to let canvas and JS execute before screenshot

## Next steps

- [ ] Sync `og-preview.html` with the template (body/positioning changes)
- [ ] Wire into catskull.net blog for real testing
  - Add `gem "jekyll-og-image", path: "../ogimage"` to blog's Gemfile
  - Add `jekyll-og-image` to `_config.yml` plugins list
  - Add `<meta property="og:image">` tag to the blog's `<head>` layout
- [ ] Test with the full blog build (all posts + pages + collections)
- [ ] Decide on skip behavior: currently skips if `assets/og/{slug}.png` exists in source
  - May want a `force: true` config option or a way to regenerate specific images
- [ ] Handle collections (playlists, newsletters, recipes, etc.) - generator currently does `site.posts.docs + site.pages`, may need to include collection documents
- [ ] Consider adding config options to `_config.yml` (output path, skip behavior, etc.)
- [ ] Seed the stipple texture random number generator per-page for deterministic output
- [ ] Publish gem to RubyGems when ready

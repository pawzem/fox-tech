# Fox Tech

A personal blog about software craft — Domain-Driven Design, Event Storming, and
pragmatic engineering — by [Paweł Zemła](https://www.linkedin.com/in/pawel-zemla/).

Built with [Jekyll](https://jekyllrb.com/) and hosted on GitHub Pages.
**Live site:** https://pawzem.github.io/fox-tech/

## Design

The look & feel follows the **Vulpario** design language (terracotta on warm
bone-white, the Inter typeface, the "no-line" rule — sectioning via surface
tiers and soft ambient shadows instead of borders). All design tokens live at
the top of [`assets/css/style.css`](assets/css/style.css) as CSS custom
properties, so re-theming is a one-place change.

## Structure

```
.
├── _config.yml              # site config (title, author, plugins, URLs)
├── _layouts/                # default, home, post, page
├── _includes/               # head, header, footer
├── _posts/                  # articles (one Markdown file per post)
├── assets/
│   ├── css/style.css        # all styling + design tokens
│   └── img/                 # post images + site assets (favicon, photo)
├── about.md                 # About page
└── index.html               # home (post list)
```

## Writing a new post

Add a Markdown file to `_posts/` named `YYYY-MM-DD-title-slug.md`:

```markdown
---
layout: post
title: "Your Title Here"
date: 2025-01-15
tags: [DDD, Java]
excerpt: "One or two sentences shown on the home page and in previews."
---

Your content in Markdown. Code blocks get syntax highlighting:

​```java
record Money(BigDecimal amount, Currency currency) {}
​```
```

### Adding images to a post

Drop files under `assets/img/<something>/` and reference them with `relative_url`
so they resolve correctly under the `/fox-tech` base path:

```html
<figure class="wide">
  <img src="{{ '/assets/img/my-post/diagram.jpg' | relative_url }}" alt="..." loading="lazy">
  <figcaption>A short caption.</figcaption>
</figure>
```

Add `class="wide"` to let a figure break out wider than the text column on
desktop (useful for wide diagrams).

## Local development

GitHub Pages builds the site for you on every push, so this is optional. To
preview locally you need Ruby ≥ 3.0:

```bash
bundle install
bundle exec jekyll serve --livereload
# → http://localhost:4000/fox-tech/
```

## Deployment

Push to `main` and GitHub Pages rebuilds automatically (Settings → Pages →
"Deploy from a branch": `main` / `/`). No GitHub Actions workflow required —
the plugins used (`jekyll-feed`, `jekyll-seo-tag`, `jekyll-sitemap`) are all on
the GitHub Pages allow-list.

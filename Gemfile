# Gemfile for local development only.
# GitHub Pages builds the site server-side using the github-pages gem set,
# so you do NOT need this to deploy. It's here so you can run `bundle exec
# jekyll serve` locally if you install a modern Ruby (>= 3.0).
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-feed"
  gem "jekyll-seo-tag"
  gem "jekyll-sitemap"
end

# Windows / JRuby timezone data
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

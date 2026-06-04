# Local Jekyll build/preview via Docker — matches the github-pages gem used by
# GitHub Pages, so no local Ruby/Jekyll install is needed (works on any Ruby).
# Gems are cached in ./vendor/bundle (gitignored).

IMAGE  := ruby:3.3
RUN    := docker run --rm -v "$(CURDIR)":/srv -w /srv
BUNDLE := bundle config set --local path vendor/bundle && bundle install

.PHONY: build serve clean

build: ## Build the site into ./_site (run this before every push)
	$(RUN) $(IMAGE) bash -lc "$(BUNDLE) && bundle exec jekyll build --trace"

serve: ## Live preview at http://localhost:4000/fox-tech/
	$(RUN) -p 4000:4000 -p 35729:35729 $(IMAGE) \
		bash -lc "$(BUNDLE) && bundle exec jekyll serve --host 0.0.0.0 --livereload --force_polling"

clean: ## Remove build output and caches
	rm -rf _site .jekyll-cache

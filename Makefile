HUGO ?= hugo
PORT ?= 1313
CACHE_DIR ?= $(CURDIR)/.hugo_cache

.PHONY: dev build clean

dev:
	$(HUGO) server -D --disableFastRender --bind 127.0.0.1 --port $(PORT) --cacheDir $(CACHE_DIR)

build:
	$(HUGO) --gc --minify --cacheDir $(CACHE_DIR)

clean:
	rm -rf public resources $(CACHE_DIR)

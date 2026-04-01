# Pranav Pandey Personal Site

This site is built with Hugo and uses the `hugo-PaperMod` theme with a custom homepage.

## Local development

Start the local preview server:

```bash
make dev
```

Then open `http://127.0.0.1:1313`.

The preview includes drafts, so you can iterate on unpublished posts too.
Hugo caches build artifacts in `./.hugo_cache` so everything stays local to the repo.

## Production build

Generate the static site into `public/`:

```bash
make build
```

## GitHub Pages deployment

The repository is configured to deploy with GitHub Actions from `.github/workflows/hugo.yml`.

After pushing, set the repository Pages source to `GitHub Actions` in:

`Settings -> Pages -> Build and deployment -> Source`

## Clean generated files

```bash
make clean
```

# pranavpandey2511.github.io

Personal website of **Pranav Pandey** — blog, project showcase, and resume. Built with [Hugo](https://gohugo.io/) + [PaperMod](https://github.com/adityatelange/hugo-PaperMod), deployed to GitHub Pages via GitHub Actions.

**Live at: <https://pranavpandey2511.github.io/>**

## Features

- 📝 Blog with tags, categories, archive, RSS, and reading time
- 🚀 Projects showcase (professional work + open source)
- 💬 Comments & discussions on every post/project via [giscus](https://giscus.app) (GitHub Discussions — no ads, no trackers)
- 🔗 Share buttons (X, LinkedIn, Reddit, WhatsApp, Telegram)
- 🔍 Full-site fuzzy search (Fuse.js)
- 🌗 Light/dark theme with synced comment theming
- 📄 Resume page with embedded PDF viewer + download
- 🔎 SEO: Open Graph / Twitter cards, sitemap, robots.txt

## Local development

```bash
# Install hugo (macOS)
brew install hugo

# Serve with drafts at http://localhost:1313
hugo server -D
```

## Writing a new post

```bash
hugo new posts/my-post-title.md
```

Edit the file in `content/posts/`, set `draft: false` when ready, and push to `master` — the GitHub Action builds and deploys automatically.

## Adding a project

Add a markdown file in `content/projects/` (use an existing one as a template). Use `weight` to control ordering (lower = first).

## Deployment

Pushing to `master` triggers `.github/workflows/gh-pages.yml`, which builds the site with Hugo and deploys via GitHub Pages (source: **GitHub Actions**).

## Comments (giscus)

Comments map each page to a GitHub Discussion in this repo (category: Announcements). Configuration lives under `params.giscus` in `hugo.yaml`; the embed is in `layouts/partials/comments.html`.

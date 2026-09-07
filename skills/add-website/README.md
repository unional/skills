# Add a Website

Adds an Astro + Starlight documentation site to a TypeScript repo and deploys it to GitHub Pages, matching the layout every cyberuni package already uses.

## When to use

- "Add a docs site" / "add an astro website" / "follow cyber-mux"
- "Set up documentation for this package"
- "Publish docs to GitHub Pages"

## What it does

Copies the site out of the reference repo rather than scaffolding a new one, so the theme, the icon system and the known-good dependency set come along with it. Then it wires the app into the pnpm workspace, turbo, and Biome, adds the Pages workflow, and enables Pages on the repo — which is not on by default and is what makes the first deploy fail.

The larger half is content. It insists every documented example come from a test assertion rather than from a README or a Storybook page, because those drift — in `tersify` two of five headline examples were wrong.

It also covers the two traps that build cleanly and fail in production: internal links that omit the `base` prefix, and a single self-theming logo on a site that switches themes on `data-theme`.

## Install

```bash
npx skills add unional/skills --skill add-website
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

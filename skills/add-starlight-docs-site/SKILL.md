---
name: add-starlight-docs-site
description: "Add an Astro + Starlight documentation site to one of unional's TypeScript packages or monorepos, deployed to GitHub Pages, matching the cyberuni house layout (apps/website, base path, cyber-* icon system, Linear theme). Use when asked to 'add a docs site', 'add an astro website', 'set up documentation for this package', 'follow cyber-mux', 'give this repo a docs site', or 'publish docs to GitHub Pages'."
---

# Add a Starlight Docs Site

Adds `apps/website` — an Astro + Starlight site deployed to GitHub Pages — to a repository that has none. The reference implementation is [`cyberuni/cyber-mux`](https://github.com/cyberuni/cyber-mux); copy from it rather than from Starlight's own starter, which produces a different layout and no theme.

Two halves, and the second is where the work is: **wiring** the app into the monorepo, and **writing content that is true of the package**.

## Copy from the reference, do not scaffold

Read these files out of the newest cyberuni repo that already has a site (`cyber-mux` unless the user names another) and adapt them. Do not run `npm create astro`.

| File | Adapt |
|---|---|
| `apps/website/package.json` | nothing but `name` — keep the dependency versions, they are a known-good set |
| `apps/website/astro.config.mjs` | `title`, `description`, `base`, `social.href`, `sidebar` |
| `apps/website/tsconfig.json` | nothing |
| `apps/website/src/content.config.ts` | nothing |
| `apps/website/src/styles/global.css` | nothing — it is the shared Linear theme |
| `apps/website/public/img/logo.svg` | the glyph only (§ Icon) |
| `apps/website/src/assets/logo-{light,dark}.svg` | the glyph only |
| `.github/workflows/deploy-pages.yml` | the artifact `path` if the app is not at `apps/website` |

Pin the toolchain to whatever the reference repo has. Astro, Starlight, Tailwind and `@astrojs/check` are a coupled set; bumping one to match the host repo's TypeScript or Vite version is how you get an install that resolves and a build that does not. The site is `private: true`, so its dependency versions are invisible to consumers and there is nothing to gain by advancing them here.

## Wire it into the monorepo

Four files, and skipping any one leaves a site that builds locally and is invisible to CI.

1. **`pnpm-workspace.yaml`** — add `- "apps/*"` above `- "packages/*"`.
2. **Root `package.json`** — add `"web": "pnpm --filter=website"`, matching the repo's existing per-package filter script (`"tersify": "pnpm --filter=tersify"`). Every later command is then `pnpm web build`, `pnpm web dev`.
3. **`turbo.json`** — add the two tasks the site needs and a library-only repo lacks:
   ```json
   "dev": { "cache": false, "persistent": true },
   "typecheck": { "dependsOn": ["^build"] }
   ```
4. **`biome.jsonc`** — add `"!**/.astro"` to `files.includes`. Astro's generated types are not source. Also confirm `css.parser.tailwindDirectives` is `true`, or the theme stylesheet fails to parse.

Add `apps/website/.gitignore` with `.astro/` and `dist/`.

The site takes **no changeset**. It is private and unpublished.

## Base path

GitHub Pages serves a project site under `https://<owner>.github.io/<repo>/`, so `astro.config.mjs` needs `site: 'https://<owner>.github.io'` and `base: '/<repo>/'`.

**Starlight does not rewrite links inside content.** Every internal link in Markdown must carry the prefix: `/tersify/guides/options/`, not `/guides/options/`. A missing prefix builds cleanly and 404s in production, so grep the content for `](/` and check each hit before you finish.

`sidebar` entries are the exception — those take bare slugs (`{ label: 'Options', slug: 'guides/options' }`).

The sidebar is declared explicitly in `astro.config.mjs`. A new page without an entry there ships unreachable. Record that in the repo's `AGENTS.md`.

## Icon

Follow the cyber-* icon system — the authority is `docs/design/icon-system.md` in `cyberuni/cyber-mux`. The short version:

- One `viewBox="0 0 128 128"` grid. Copy the two frame paths **verbatim**; they are what makes the family a family.
  ```svg
  <path class="s" d="M17 63V17h46"/>
  <path class="s" d="M111 65v46H65"/>
  ```
- Draw a glyph in the 32..96 slot that names what the package does, literally. No metaphors. Keep 5 units of clearance from any frame stroke or it dies at 16×16.
- Three files, one drawing: `public/img/logo.svg` carries an inline `<style>` that flips fill under `prefers-color-scheme`, and `src/assets/logo-light.svg` / `logo-dark.svg` hardcode `#10111a` / `#f7f8f8`.

The pair is not redundancy. Starlight switches on `data-theme` and this theme defaults to dark regardless of the OS, so a single self-theming file renders near-black on the near-black header for any visitor whose OS is set to light. `prefers-color-scheme` never learns what `data-theme` decided.

Verify by grepping the built HTML for both images and their hiding classes:

```bash
grep -o '<img[^>]*logo[^>]*>' apps/website/dist/index.html
# expect light:sl-hidden on logo-dark, dark:sl-hidden on logo-light
```

## Write content the package can back up

This is the half that takes the time, and the half where a plausible-looking site is worse than none.

**Derive every example from test assertions.** Read the `*.spec.ts` files and take input→output pairs verbatim from what is asserted. Do not take them from the README, from Storybook `.mdx` pages, or from the source's doc comments — in `tersify` those disagreed with the specs on two of five examples, and the specs were right.

This is bulk reading whose answer is much smaller than the reading. Delegate it: brief a subagent with the exact file list and ask for a dense input→output report grouped by value type, with anything it could not find in an assertion marked UNVERIFIED rather than guessed. Then write prose from the report.

When a package has a browser build (a `browser` field in `package.json`), find out what actually differs and say so on the installation page. Do not claim parity you have not checked.

State an `engines` requirement only if the package declares one.

### Shape

Getting Started (Introduction, Installation) · Guides (one per cross-cutting concern — options, extension points, edge-case behavior) · Reference (an overview card grid, then one page per export).

The introduction earns its place by answering *why not the built-in*. For `tersify` that was a table against `JSON.stringify` and `util.inspect`. Find the equivalent comparison for the package at hand; a page that only restates what the package does is filler.

Prefer the repo's `technical-writer` skill for the prose standard.

## Deploy

`deploy-pages.yml` builds on every push to `main` and uploads `apps/website/dist`. It needs `pages: write` and `id-token: write`, and the `github-pages` environment.

**The workflow alone is not enough.** The repository must have Pages enabled with the build source set to GitHub Actions, and it is not on by default:

```bash
gh api repos/<owner>/<repo>/pages           # 404 means not enabled
gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow
```

Enabling Pages publishes the site to a public URL. Confirm with the user before running the POST — do not enable it as a side effect of adding the app.

## Verify before you claim it works

```bash
pnpm install
pnpm web build         # must be clean
pnpm web typecheck     # astro check — 0 errors
pnpm check             # biome across the repo
pnpm knip              # the new package must not add findings
```

Two Starlight warnings during the build are expected and harmless: the missing `i18n` collection, and `Entry docs → 404 was not found`.

Then **look at the site**. Run `pnpm web preview` and open it. The build passing tells you nothing about whether the header lockup reads, whether the glyph survives at 24px, or whether the theme applied. Check the home page and one content page, and check the header in the non-default theme — that is the failure the icon system warns about and it is invisible from the terminal.

Biome flags the theme's one `!important` (`lint/complexity/noImportantStyles`). It is deliberate — expressive-code sets the code-block background in a rule you cannot outrank by specificity. Suppress it with a reason rather than deleting it:

```css
/* biome-ignore lint/complexity/noImportantStyles: expressive-code sets the code block background
   from its own theme in a rule we cannot outrank by specificity. */
background: var(--sl-color-black) !important;
```

## Finish

Update the repo's `readme.md` (a Documentation link, an Apps section, the `pnpm web dev` script row) and `AGENTS.md` (the site's commands, the base-path rule, the explicit sidebar, where documented behavior must come from). A docs site nobody knows to run is a docs site that rots.

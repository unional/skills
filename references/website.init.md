---
description: The cyberuni house style for adding a docs site — Astro and Starlight in apps/website, copied from cyber-mux, with the Linear theme, the cyber-* icon system, and content taken from test assertions.
tags: [website, init, astro, starlight, house-style]
extends: [default]
---

## Purpose

Adds `apps/website`, an Astro and Starlight site deployed to GitHub Pages, to one of unional's repositories that has none. The site matches the cyberuni house layout: the base path, the shared Linear theme, and the `cyber-*` icon system.

Reference layout: [`cyberuni/cyber-mux`](https://github.com/cyberuni/cyber-mux). Copy from it, not from Starlight's own starter or from the `website` skill's `assets/site/` template. Those give a different layout and no theme.

The work has two halves: wiring the app into the monorepo, and writing content that is true of the package. The second half takes longer.

## Step 2: Choose the location and name

Use `apps/website`, unless the user names another directory. Name the package `website` and mark it `"private": true`. The site is never published to npm.

Confirm the directory with the user before writing files.

## Step 3: Resolve versions

Do not look up the newest versions. Take every dependency version from `apps/website/package.json` in the reference repo: `cyber-mux`, or the newest cyberuni repo that has a site if the user names one.

Astro, Starlight, Tailwind, and `@astrojs/check` are a coupled set. Do not bump one of them to match the host repo's TypeScript or Vite version: the install resolves and the build fails. The site is private, so its versions are invisible to consumers and nothing is gained by advancing them here.

If the repo has a release-age gate and a reference version is inside its window, report it and ask the user. Do not pick a different version on your own.

## Step 4: Scaffold the package

Read these files from the reference repo and adapt them. Do not run `npm create astro`.

| File | Adapt |
|---|---|
| `apps/website/package.json` | `name` only |
| `apps/website/astro.config.mjs` | `title`, `description`, `site`, `base`, `social.href`, `sidebar` |
| `apps/website/turbo.json`, `apps/website/tsconfig.json`, `apps/website/src/content.config.ts` | Nothing |
| `apps/website/src/styles/global.css` | Nothing. It is the shared Linear theme |
| `apps/website/public/img/logo.svg` | The glyph only |
| `apps/website/src/assets/logo-light.svg`, `apps/website/src/assets/logo-dark.svg` | The glyph only |

Add `apps/website/.gitignore` with `.astro/` and `dist/`.

GitHub Pages serves a project site under `https://<OWNER>.github.io/<REPO_NAME>/`, so set `site: 'https://<OWNER>.github.io'` and `base: '/<REPO_NAME>/'`.

The sidebar is an explicit list in `astro.config.mjs`. A new page without an entry ships unreachable. Sidebar entries take bare slugs (`{ label: 'Options', slug: 'guides/options' }`).

**Icon.** Follow the `cyber-*` icon system. Its authority is `docs/design/icon-system.md` in `cyberuni/cyber-mux`.

- Use one `viewBox="0 0 128 128"` grid. Copy the two frame paths verbatim:
  ```svg
  <path class="s" d="M17 63V17h46"/>
  <path class="s" d="M111 65v46H65"/>
  ```
- Draw a glyph in the 32..96 slot that names what the package does, literally. Use no metaphors. Keep 5 units of clearance from each frame stroke, or the glyph is lost at 16×16.
- Draw it once, in three files. `public/img/logo.svg` carries an inline `<style>` that changes the fill under `prefers-color-scheme`. `src/assets/logo-light.svg` and `logo-dark.svg` hardcode `#10111a` and `#f7f8f8`.

Keep both header files. Starlight switches themes on `data-theme`, and this theme defaults to dark whatever the OS says. A single self-theming file follows `prefers-color-scheme`, so it renders near-black on the near-black header for a visitor whose OS is set to light.

**Content.** Derive every example from test assertions. Read the `*.spec.ts` files and take input and output pairs verbatim from what they assert. Do not take examples from the readme, from Storybook `.mdx` pages, or from doc comments: in `tersify`, those disagreed with the specs on two of five examples, and the specs were right.

This is bulk reading with a small answer. Delegate it: give a subagent the exact file list and ask for an input-to-output report grouped by value type, with anything not found in an assertion marked UNVERIFIED. Write the pages from that report.

- When the package has a browser build (a `browser` field in `package.json`), find out what differs and say so on the installation page. Do not claim parity you have not checked.
- State an `engines` requirement only if the package declares one.
- Shape the site as Getting Started (Introduction, Installation), Guides (one per cross-cutting concern, such as options, extension points, and edge-case behavior), and Reference (an overview card grid, then one page per export).
- Make the introduction answer why not the built-in. For `tersify`, that was a table against `JSON.stringify` and `util.inspect`. A page that only restates what the package does is filler.
- Follow the `technical-writer` skill for the prose.

### Internal links and `base`

Starlight does not add `base` to links inside content. Write every internal link in Markdown with the prefix: `/<REPO_NAME>/guides/options/`, not `/guides/options/`. A link without the prefix builds and returns 404 in production. Before you finish, search the content for `](/` and check each match.

## Step 5: Wire the site into the monorepo

Change each file below that exists. Skipping one leaves a site that builds locally and that CI does not see.

| File | Change |
|---|---|
| `pnpm-workspace.yaml` | Add `- "apps/*"` above `- "packages/*"`. On pnpm 11, add `esbuild: true` and `sharp: true` under `allowBuilds`. On pnpm 10, add both to `onlyBuiltDependencies` |
| Root `package.json` | Add `"web": "pnpm run --filter=website"`, matching the repo's other per-package filter scripts. Every later command is then `pnpm web build` or `pnpm web dev` |
| `turbo.json` | Add `"dev": { "cache": false, "persistent": true }` and `"typecheck": { "dependsOn": ["^build"] }` if they are missing |
| `biome.json` or `biome.jsonc` | Add `"!**/.astro"` to `files.includes`. Set `css.parser.tailwindDirectives` to `true`, or the theme stylesheet fails to parse |
| `knip.json` | Add a workspace entry for `apps/website` with `entry` and `project` set to `["src/**/*.{astro,ts,mdx}"]` |
| `.changeset/config.json` | Add `website` to `ignore` when `privatePackages.version` is `true`. The site takes no changeset |

## Step 6: Deploy

Follow the `website.deploy` reference with `SITE_DIR` set to `apps/website`, `DIST_DIR` set to `apps/website/dist`, and `BUILD_CMD` set to `pnpm web build`. If the base path it works out differs from what Step 4 set, update `site` and `base`.

The deploy job runs only for changes under `apps/website`. If the site renders content from other workspaces, such as a package readme, add those paths to the job's filter too.

## Step 7: Record the site in AGENTS.md

Update the repo's `AGENTS.md`: the site's commands (`pnpm web dev`, `pnpm web build`), the base-path rule for internal links, the explicit sidebar, and the rule that documented behavior comes from test assertions.

Update the repo's `readme.md` too: a Documentation link to the site, an Apps section, and the `pnpm web dev` script row.

## Step 8: Verify

Run each command from the repo root. Each one must pass:

```bash
pnpm install
pnpm web build
pnpm web typecheck
pnpm check
pnpm knip
```

Two Starlight warnings during the build are expected: the missing `i18n` collection, and `Entry docs → 404 was not found`.

Biome flags the theme's one `!important` (`lint/complexity/noImportantStyles`). Keep it and suppress the rule with a reason:

```css
/* biome-ignore lint/complexity/noImportantStyles: expressive-code sets the code block background
   from its own theme in a rule we cannot outrank by specificity. */
background: var(--sl-color-black) !important;
```

Check that the header shows the right logo in each theme:

```bash
grep -o '<img[^>]*logo[^>]*>' apps/website/dist/index.html
# expect light:sl-hidden on logo-dark, dark:sl-hidden on logo-light
```

Then look at the site. Run `pnpm web preview` and open the home page and one content page. Check the header in the theme that is not the default. A passing build does not show whether the header reads, whether the glyph survives at 24px, or whether the theme applied.

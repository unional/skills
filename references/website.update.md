---
description: The cyberuni house style for changing a docs site — explicit sidebar, base-prefixed links, versions from the reference repo, and examples from test assertions.
tags: [website, update, astro, starlight, house-style]
extends: [default]
---

## Step 2: Make the change

| Change | What to do |
|---|---|
| Add a page | Write it under the content directory, in the section its topic belongs to. Add its entry to the explicit `sidebar` in `astro.config.mjs`, or the page ships unreachable |
| Move or rename a page | Move the file, update the sidebar, and update every internal link to it. Search the content directory for the old path |
| Remove a page | Delete it, remove its sidebar entry, and fix every internal link to it |
| Docs for a changed package | Take every example from the package's test assertions (its `*.spec.ts` files), not from its readme, Storybook pages, or doc comments |
| Upgrade framework packages | Take the versions from `apps/website/package.json` in the reference repo (`cyberuni/cyber-mux`). Astro, Starlight, Tailwind, and `@astrojs/check` move together |
| Change `site`, `base`, or the host | Use the `website.deploy` reference |

Write every internal link with the base included: `/<REPO_NAME>/guides/options/`, not `/guides/options/`. Starlight does not add `base` to links inside content. Sidebar entries take bare slugs.

---
"unional-skills": patch
---

A Version Packages PR opened with the plain `GITHUB_TOKEN` gets `pull_request` runs. GitHub holds them as `action_required` until someone approves them. Skills that said those runs never fire now say they are held, and say who approves them.

- `ship-it`: a stuck Version PR usually has held runs, on both release workflows. The secretless workflow approves them itself when the caller grants `actions: write`. Otherwise, approve the runs on the branch's current head, newest first, and skip runs on older heads. Push an empty commit only when no run exists. The quote from `cyberuni/.github`'s header is replaced with what its `v2` header says now.
- `transfer-repo-to-org`: restoring the ruleset bypass actor after a transfer still matters. The release deadlocks whenever the Version PR's held runs go unapproved, or no run is created, so the PAT variant is not exempt. The first release after a transfer approves the held runs on either workflow.
- `setup-secretless-release` and `apply-repo-baseline`: `unional/.github`'s release workflow now has the approval step, as repobuddy's and cyberuni's already do. unional callers grant `actions: write` too.
- `sweep-dependency`: approve a release PR's held runs before pushing an empty commit.

`setup-secretless-release`: correct the npm 12 guidance. npm 12 breaks only `@changesets/cli` 2.x. CLI 3.0.3 and later handles npm 12, so `npm@latest` is safe on any v2 line, and repobuddy's `@v2` has published on npm 12.2.1. CLI 3.0.0 to 3.0.2 in a pnpm 10 workspace still hits the `getUnpublishedPackages` `TypeError`, which 3.0.3 fixed. `@v1` remains broken, because it pairs with CLI 2 and installs `npm@latest`. A repo that has to stay on CLI 2 pins npm 11 (11.5.1 or later) itself.

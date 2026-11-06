# unional-skills

## 1.3.0

### Minor Changes

- 6b9ffb6: Add the `setup-org` skill: set up a new GitHub organization in the house style, with a `.github` repo copied from `cyber-civitas/.github`, Discussions, an org Project, org metadata, and logo candidates in the cyber-* icon frame for the owner to pick.

### Patch Changes

- c513d3f: `apply-repo-baseline`: correct what applying it to `repobuddy/buddy-agent-harness` showed was stale.
  
  - The publish gate becomes a `needs:` of the release job in `release.yml`. The old `pull-request.yml` placement never fired.
  - The release caller grants `actions: write`, so the v2 release workflow can approve the Version PR's parked runs. The plain `GITHUB_TOKEN` does create those runs.
  - Reusable workflows are pinned to the owner's release tag (`@v2` for `@changesets/cli` v3), not `@main`.
  - The skill gives the order for renaming the required check from `all-checks` to `code / all-checks`, and for folding a `merge-backstop` ruleset into `main`.
  - A repo's own Renovate auto-merge rules are stripped only once the published preset carries them. The soak text now matches the asset's `3 days`.
  - The org's `*_enabled_for_new_repositories` fields are dropped from `assets/org-settings.json`. GitHub removed them in favour of code security configurations.
  - Tip added: run the publish gate locally before switching a release onto it.
- 88c0f10: apply-repo-baseline: set the merge queue's `min_entries_to_merge_wait_minutes` to 0, so a lone pull request merges as soon as its checks pass instead of waiting 5 minutes.
- fa47167: `setup-secretless-release`: align with what `apply-repo-baseline` learned on `repobuddy/buddy-agent-harness`.
  
  - The publish gate is a `needs:` of the release job in `release.yml`, not a job on the Version Packages PR.
  - The release caller pins the owner's tag rather than `@main`, and grants `actions: write` where the release workflow approves the Version PR's parked runs.
  - A Version PR opened with the plain `GITHUB_TOKEN` does get `pull_request` runs. They are parked as `action_required`, and the skill now says who approves them for each workflow.
  - `@v2` does not always pin npm: repobuddy's v2 and unional's copy install `npm@latest`.
  - repobuddy's v2 publish gate accepts a per-dependency acknowledgement in `.github/publish-gate.json`.
  
  `apply-repo-baseline`: find the default-branch ruleset by what it protects, not by the name `main`. The skill PUTs the one active branch ruleset that targets the default branch, keeping its name, creates `main` only when none exists, and stops when more than one matches. A `merge-backstop` ruleset is still folded in, and the separate Copilot review ruleset is set aside.
- 7799862: A Version Packages PR opened with the plain `GITHUB_TOKEN` gets `pull_request` runs. GitHub holds them as `action_required` until someone approves them. Skills that said those runs never fire now say they are held, and say who approves them.
  
  - `ship-it`: a stuck Version PR usually has held runs, on both release workflows. The secretless workflow approves them itself when the caller grants `actions: write`. Otherwise, approve the runs on the branch's current head, newest first, and skip runs on older heads. Push an empty commit only when no run exists. The quote from `cyberuni/.github`'s header is replaced with what its `v2` header says now.
  - `transfer-repo-to-org`: restoring the ruleset bypass actor after a transfer still matters. The release deadlocks whenever the Version PR's held runs go unapproved, or no run is created, so the PAT variant is not exempt. The first release after a transfer approves the held runs on either workflow.
  - `setup-secretless-release` and `apply-repo-baseline`: `unional/.github`'s release workflow now has the approval step, as repobuddy's and cyberuni's already do. unional callers grant `actions: write` too.
  - `sweep-dependency`: approve a release PR's held runs before pushing an empty commit.
  
  `setup-secretless-release`: correct the npm 12 guidance. npm 12 breaks only `@changesets/cli` 2.x. CLI 3.0.3 and later handles npm 12, so `npm@latest` is safe on any v2 line, and repobuddy's `@v2` has published on npm 12.2.1. CLI 3.0.0 to 3.0.2 in a pnpm 10 workspace still hits the `getUnpublishedPackages` `TypeError`, which 3.0.3 fixed. `@v1` remains broken, because it pairs with CLI 2 and installs `npm@latest`. A repo that has to stay on CLI 2 pins npm 11 (11.5.1 or later) itself.

## 1.2.0

### Minor Changes

- 1abfb0e: Add the `post-on-x` skill: draft, review, and plan X posts against the ranking weights X publishes, with a release rollout plan, a freshness check, and a way to test disputed claims.
- 5715b8e: `replicate-wsl-machine`: carry the editor setup over. Capture now records Neovim's Mason tools and lists the `~/.config` that chezmoi does not manage, a new `editors` apply phase restores the pinned plugins and installs the Mason tools, and verify reports missing plugins and tools.
- 16da16c: `replicate-wsl-machine` now has a commit-signing step: the user copies the signing key to the target, since the gitconfig signs every commit and each one fails until the key is there. `verify.sh` reports the key missing.
- 21b0ba2: Add the `replicate-wsl-machine` skill: capture a WSL machine's packages, tools, services, and repos into a manifest, then rebuild it on a fresh distro and verify what is still missing.
- 8696292: Add the `sweep-dependency` skill: bump one package across every owned repo leaf-first, merging and releasing each and verifying the publish on npm before moving up.

### Patch Changes

- eb4a0ce: Adopt the Agent Plugins Specification v1.0.0. The canonical manifest moves from `.plugin/plugin.json` to the repo root, `vendorExtensions` becomes `extensions["org.cyberuni.universal-plugin"].harnesses`, and `.plugin/plugin.json` is removed — Copilot CLI searches that path before the root, so leaving it would shadow the canonical manifest with a copy nothing regenerates.
  
  `plugin build` regenerates the derived manifests again; under the old layout it silently built nothing.
- 5715b8e: `replicate-wsl-machine`: stop leaving Claude Code's scripts behind. Capture now lists unmanaged `~/.claude` entries with runtime state left out, and verify reports any status line or hook script that `~/.claude/settings.json` runs but the machine lacks.
- 5715b8e: Reconcile contradictions across the release and repo-baseline skills: one account of the Version Packages PR approval (token variant held for approval, secretless variant needs an empty commit), post-publish checks read the registry directly instead of `npm view`, and `modernize-repo` runs the legacy-CI decision before the baseline. Drop dated counts and "earlier guidance was wrong" asides that rot.

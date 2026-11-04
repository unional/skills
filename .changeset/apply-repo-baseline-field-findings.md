---
"unional-skills": patch
---

`apply-repo-baseline`: correct what applying it to `repobuddy/buddy-agent-harness` showed was stale.

- The publish gate becomes a `needs:` of the release job in `release.yml`. The old `pull-request.yml` placement never fired.
- The release caller grants `actions: write`, so the v2 release workflow can approve the Version PR's parked runs. The plain `GITHUB_TOKEN` does create those runs.
- Reusable workflows are pinned to the owner's release tag (`@v2` for `@changesets/cli` v3), not `@main`.
- The skill gives the order for renaming the required check from `all-checks` to `code / all-checks`, and for folding a `merge-backstop` ruleset into `main`.
- It no longer strips a repo's Renovate auto-merge rules while the published preset lacks them. The drift goes to the owner as a decision.
- The org's `*_enabled_for_new_repositories` fields are dropped from `assets/org-settings.json`. GitHub removed them in favour of code security configurations.
- Tip added: run the publish gate locally before switching a release onto it.

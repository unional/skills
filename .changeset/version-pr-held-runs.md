---
"unional-skills": patch
---

A Version Packages PR opened with the plain `GITHUB_TOKEN` gets `pull_request` runs. GitHub holds them as `action_required` until someone approves them. Skills that said those runs never fire now say they are held, and say who approves them.

- `ship-it`: a stuck Version PR usually has held runs, on both release workflows. The secretless workflow approves them itself when the caller grants `actions: write`. Otherwise, approve the runs on the branch's current head, newest first, and skip runs on older heads. Push an empty commit only when no run exists. The quote from `cyberuni/.github`'s header is replaced with what its `v2` header says now.
- `transfer-repo-to-org`: restoring the ruleset bypass actor after a transfer still matters. The release deadlocks whenever the Version PR's held runs go unapproved, or no run is created, so the PAT variant is not exempt. The first release after a transfer approves the held runs on either workflow.
- `setup-secretless-release` and `apply-repo-baseline`: `unional/.github`'s release workflow now has the approval step, as repobuddy's and cyberuni's already do. unional callers grant `actions: write` too.
- `sweep-dependency`: approve a release PR's held runs before pushing an empty commit.

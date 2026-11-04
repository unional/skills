---
"unional-skills": patch
---

`setup-secretless-release`: align with what `apply-repo-baseline` learned on `repobuddy/buddy-agent-harness`.

- The publish gate is a `needs:` of the release job in `release.yml`, not a job on the Version Packages PR.
- The release caller pins the owner's tag rather than `@main`, and grants `actions: write` where the release workflow approves the Version PR's parked runs.
- A Version PR opened with the plain `GITHUB_TOKEN` does get `pull_request` runs. They are parked as `action_required`, and the skill now says who approves them for each workflow.
- `@v2` does not always pin npm: repobuddy's v2 and unional's copy install `npm@latest`.
- repobuddy's v2 publish gate accepts a per-dependency acknowledgement in `.github/publish-gate.json`.

`apply-repo-baseline`: find the default-branch ruleset by what it protects, not by the name `main`. The skill PUTs the one active branch ruleset that targets the default branch, keeping its name, creates `main` only when none exists, and stops when more than one matches. A `merge-backstop` ruleset is still folded in, and the separate Copilot review ruleset is set aside.

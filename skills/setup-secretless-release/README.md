# Setup Secretless Release

Moves a package's release off long-lived `NPM_TOKEN` and PAT secrets onto OIDC trusted publishing, migrating it to pnpm + changesets on the way, and keeps dependency PRs merging without manual rebases.

## When to use

- A release workflow authenticates with `NPM_TOKEN` or a `CI_GITHUB_TOKEN` PAT
- A release has silently stopped publishing
- Publishing fails with a 401 on `/-/whoami`, or with `ENONPMTOKEN`
- "Fix releases", "remove NPM_TOKEN", "set up trusted publishing"

## What it does

Converts one repo's release pipeline from long-lived secrets to OIDC trusted publishing, then makes its dependency PRs merge on their own. It diagnoses first and changes nothing until the diagnosis is in hand.

The target is pnpm + changesets, and the skill migrates to it whenever the repo allows. Registering the trusted publisher pins `owner/repo`, so run **transfer-repo-to-org** first if the repo is also moving.

`references/failure-catalogue.md` maps the observed error to its cause; read it when a step fails rather than up front.

## Install

```bash
npx skills add unional/skills --skill setup-secretless-release
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

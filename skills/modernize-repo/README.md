# Modernize Repo

Brings one repository fully current in a single pass: settings baseline, a release that publishes without long-lived tokens, dependency PRs that merge themselves, and proof that all of it works.

## When to use

- "Modernize this repo", "bring it up to standard", "fix everything about this repo"
- After **audit-release-health** flags a repo as broken

## What it does

Orchestrates the other skills in the order their dependencies require, and diagnoses before changing anything. Each phase gates the next, so a repo that fails an early check does not accumulate half-applied settings.

It calls **migrate-legacy-ci**, **transfer-repo-to-org**, **setup-secretless-release**, **apply-repo-baseline**, and **modernize-toolchain**. Use those directly when you already know which one piece needs fixing.

## Install

```bash
npx skills add unional/skills --skill modernize-repo
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

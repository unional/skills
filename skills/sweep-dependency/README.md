# Sweep Dependency

Moves one package to a new version in every repo I own, leaf-first. It merges each repo's pull request and releases its packages, so the repos above get the aligned versions.

## When to use

- "Update type-plus to 8.0.0-beta.12 in every project I own, merge and release"
- A breaking beta of a shared package needs to reach the whole dependency graph in order

## What it does

It inventories the repos that depend on the package and layers them by runtime dependencies only. Then it dispatches cyberfleet pods, four at a time by default. Each pod bumps the package, aligns my other packages to their latest versions, fixes breaks, and opens a pull request. The Operator gates and merges each pull request and gets the changesets release PR through CI. It checks the publish on npm before releasing the repos that depend on it. Breaks found by early pods go into later briefs.

Requires the `cyberfleet` and `cyberlegion` plugins and herdr.

## Install

```bash
npx skills add unional/skills --skill sweep-dependency
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

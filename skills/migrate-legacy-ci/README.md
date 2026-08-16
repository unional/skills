# Migrate Legacy CI

Decides what to do with a repo still on a legacy CI shape: a single `nodejs.yml` calling `typescript-build.yml`, `typescript-test.yml`, and `npm-release.yml`, or inlined yarn steps. The outcomes are archive it, drop its CI, or migrate it to the `pull-request.yml` + `release.yml` split.

## When to use

- Before **apply-repo-baseline** touches a repo
- When a ruleset would require `code / all-checks` on a pipeline that cannot produce it
- "Migrate the old workflows", "fix nodejs.yml", "why is this PR unmergeable"
- Auditing which repos are still on the old pipeline

## What it does

A legacy pipeline produces no `code / all-checks` context. Applying the baseline ruleset to one makes the repo unmergeable forever, because the required check can never report and there is nothing to wait for.

This is mostly a decision, not a file shuffle. Most legacy repos are dormant, and migrating one costs more than archiving it. The skill classifies by the check context the pipeline actually emits rather than by filename, then forces the archive/drop/migrate call before anything is written. Replacement workflows live in `assets/`.

## Install

```bash
npx skills add unional/skills --skill migrate-legacy-ci
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

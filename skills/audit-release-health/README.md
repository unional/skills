# Audit Release Health

Sweeps an owner's repositories to find the ones that stopped publishing, classifies each failure by root cause, and reports the evidence needed to fix them.

## When to use

- "Which of my repos are broken?" or "is anything not publishing?"
- "Audit my releases" or "find repos that need modernizing"
- Before running **modernize-repo**, to decide which repos to run it on

## What it does

Produces the worklist that **modernize-repo** then works through. This skill finds *which* repos are broken; that skill fixes one of them.

Read-only from start to finish. It inspects, classifies, and reports, and changes nothing.

The failure modes it separates are the ones that look alike from outside: a pipeline that never ran, one that ran and silently skipped the publish, an expired token, and a package whose last version predates its last commit.

## Install

```bash
npx skills add unional/skills --skill audit-release-health
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

# Modernize Toolchain

Replaces a TypeScript library's build, lint, test, and dependency stack in one pass instead of upgrading tools that the swap then deletes.

## When to use

- A repo is on webpack, eslint 8, jest, or raw `tsc` and should match the current stack
- "Modernize the toolchain", "bring the deps current", "replace webpack/eslint/jest"
- "Upgrade to TypeScript 7"
- A repo's dependency list is long and mostly obsolete

## What it does

This is phase 7 of **modernize-repo**, usable on its own. Everything it touches is internal to the repo, which keeps it separate from the release pipeline, settings, and automation that the other skills own.

The target stack is tsdown for the build, biome for lint, turbo for tasks, and vitest for tests. The ordering rule saves the most work: delete before you upgrade, because most of the dependency list disappears with the tools that required it.

## Install

```bash
npx skills add unional/skills --skill modernize-toolchain
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

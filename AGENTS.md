# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

## What This Repo Is

A collection of reusable skills for AI coding agents (Claude Code, Cursor, Codex, and others). Each skill is a single markdown file that encodes a workflow, decision process, or convention — not documentation.

## No Build or Test System

This repo is pure markdown. There are no build, lint, or test commands. The only tooling is the `npx skills` CLI used by *consumers* to install skills, not by contributors.

## Adding a New Skill

Create `skills/<skill-name>/SKILL.md` with this structure:

```markdown
---
name: skill-name
description: "One sentence trigger description. Should include: WHAT the skill does, WHEN to invoke it, and key situations it handles."
---

# Skill Title

...content...
```

The `description` frontmatter field is used by agents to decide when to invoke the skill. Write it as a rich trigger: include concrete situations, not just a summary.

## Skill Design Principles

- **Decisions over documentation** — encode what to decide and how, not reference material the model already knows
- **Narrow and invokable** — one workflow per skill; the agent picks it up only when the situation matches
- **No baked-in opinions** — detect the user's setup (package manager, monorepo shape, tooling) at runtime rather than assuming a specific stack

## CI

Dependabot PRs are automatically approved and merged via `.github/workflows/automerge-dependabot.yml` (rebase strategy).

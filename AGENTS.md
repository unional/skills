# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

## What This Repo Is

unional's personal universal agent plugin (`unional-skills`) — skills for managing his own repos and organizations and automating the chores specific to how he works, installable on Claude Code, Cursor, Codex, and GitHub Copilot CLI. Each skill is a single markdown file that encodes a workflow, decision process, or convention — not documentation.

Scope check before adding a skill: personal conventions and repo-specific chores belong here; generally useful workflows belong in [repobuddy/repobuddy](https://github.com/repobuddy/repobuddy) or [cyberuni/cyberplace](https://github.com/cyberuni/cyberplace).

Skills can still be installed individually with `npx skills add`; the plugin is the packaged distribution of the same `skills/` directory.

## Plugin Layout

| Path | Role |
| ---- | ---- |
| `.plugin/plugin.json` | Canonical manifest — the only file to hand-edit |
| `.claude-plugin/plugin.json` | Generated — Claude Code |
| `.cursor-plugin/plugin.json` | Generated — Cursor |
| `.codex-plugin/plugin.json` | Generated — Codex |
| `plugin.json` (repo root) | Generated — GitHub Copilot CLI |
| `skills/` | Skills shipped by the plugin |
| `.agents/skills/` | Third-party skills installed for local use — **not** shipped |

Never hand-edit a generated manifest. Change `.plugin/plugin.json`, then regenerate:

```bash
npx universal-plugin plugin build
```

Vendor targets are the keys of `vendorExtensions` in `.plugin/plugin.json` — adding or removing a key adds or removes that vendor's output.

## No Build or Test System

This repo is pure markdown apart from manifest generation. There are no lint or test commands; the only build step is `npx universal-plugin plugin build`, which regenerates the four vendor manifests from `.plugin/plugin.json`.

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

## CI

Dependabot is configured in `.github/dependabot.yml` for `github-actions` only — `package.json` declares no dependencies. Its PRs are auto-approved via `.github/workflows/automerge-dependabot.yml`, which auto-merges patch and minor updates (rebase strategy) and leaves majors for a human.

Renovate is deliberately not enabled; its onboarding PR (#1) was closed. With no dependency manifest, the only thing it had to update was the Dependabot machinery itself.

# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

## What This Repo Is

unional's personal universal agent plugin (`unional-skills`) — skills for managing his own repos and organizations and automating the chores specific to how he works, installable on Claude Code, Cursor, Codex, and GitHub Copilot CLI. Each skill is a single markdown file that encodes a workflow, decision process, or convention — not documentation.

Scope check before adding a skill: personal conventions and repo-specific chores belong here; generally useful workflows belong in [repobuddy/repobuddy](https://github.com/repobuddy/repobuddy) or [cyberuni/cyberplace](https://github.com/cyberuni/cyberplace).

Skills can still be installed individually with `npx skills add`; the plugin is the packaged distribution of the same `skills/` directory.

## Plugin Layout

| Path | Role |
| ---- | ---- |
| `plugin.json` (repo root) | Canonical manifest — the only file to hand-edit. Copilot CLI reads it directly |
| `.claude-plugin/plugin.json` | Generated — Claude Code |
| `.cursor-plugin/plugin.json` | Generated — Cursor |
| `.codex-plugin/plugin.json` | Generated — Codex |
| `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json` | Generated — local marketplace catalogs |
| `.agents/universal-plugin.json` | `packagePath`, which `publish sync-version` reads |
| `skills/` | Skills shipped by the plugin |
| `.agents/skills/` | Third-party skills installed for local use — **not** shipped |

The plugin is on the [Agent Plugins Specification](https://agent-plugins.org/schemas/1.0.0/plugin.schema.json) v1.0.0. The spec's top level is a closed set of ten fields; everything universal-plugin needs sits under `extensions["org.cyberuni.universal-plugin"]` — `vendors` (build targets), `skills` (component path), and `harnesses` (per-vendor overrides).

Never hand-edit a generated manifest. Change the root `plugin.json`, then regenerate:

```bash
npx universal-plugin plugin build
```

Vendor targets are the `vendors` array — adding or removing an entry adds or removes that vendor's output. Copilot CLI is a target but gets no derived file: it reads the canonical manifest, reported as status `canonical`. That also means a Copilot-only manifest field has nowhere to live; `category` and `tags` belong in `keywords` or in the marketplace catalog.

Do not recreate `.plugin/plugin.json`. Copilot CLI searches `.plugin/plugin.json` before the root, so it would silently shadow the canonical manifest with a copy nothing regenerates.

## No Build or Test System

This repo is pure markdown apart from manifest generation. There are no lint or test commands; the only build step is `npx universal-plugin plugin build`, which regenerates the derived manifests and catalogs from the root `plugin.json`.

The dependencies are `@changesets/cli` and `universal-plugin`, installed with pnpm for the release workflow.

## Releases

Releases run on changesets. `package.json` is `private: true` and nothing publishes to npm — `privatePackages: { version: true, tag: true }` in `.changeset/config.json` makes a release a version bump plus a git tag, which is what the plugin's consumers install from.

Every user-facing skill change needs a changeset (`pnpm cs`). On push to `main`, `.github/workflows/release.yml` opens a **Version Packages** PR; merging it bumps `package.json`, writes `CHANGELOG.md`, and tags. Versions and `CHANGELOG.md` on that PR are generated — never hand-edit them.

The `version` script carries the number the whole way: `changeset version` decides it in `package.json`, `publish sync-version` copies it into the canonical `plugin.json`, and `plugin build` regenerates the derived manifests and catalogs. Never hand-edit a `version` field anywhere — `/universal-plugin:version` owns that move.

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

Dependabot is configured in `.github/dependabot.yml` for `github-actions` only; the `npm` ecosystem is not enabled yet, so `@changesets/cli` and `universal-plugin` are not updated automatically. Its PRs are auto-approved via `.github/workflows/automerge-dependabot.yml`, which auto-merges patch and minor updates (rebase strategy) and leaves majors for a human.

Renovate is deliberately not enabled; its onboarding PR (#1) was closed.

# Agent Skills

My personal agent plugin — **`unional-skills`** — for managing the repos and organizations I own and automating the tasks that are specific to how I work. Packaged as a universal plugin, so it installs on Claude Code, Cursor, Codex, and GitHub Copilot CLI.

Skills encode **decisions and workflows**, not documentation. Each skill covers one situation and tells the agent what to do, what to skip, and how to adapt to the setup at hand.

## Scope

This plugin is personal. It carries my conventions, my repo layout, and the chores I repeat across my projects. It is public so my agents can install it anywhere, not because it is meant to fit anyone else's setup.

General, shareable plugins live in their own repos:

| Plugin | Purpose |
| ------ | ------- |
| [repobuddy/repobuddy](https://github.com/repobuddy/repobuddy) | General repository workflows |
| [cyberuni/cyberplace](https://github.com/cyberuni/cyberplace) | General agent tooling and workflows |

When a skill here turns out to be useful beyond my own repos, it graduates to one of those.

## Principles

- **Decisions over documentation.** A skill should encode what to decide and how, not repeat reference material the model already knows.
- **Narrow and composable.** Each skill covers one workflow. Skills can be invoked by situation or called by other skills — never loaded as ambient context. Sub-skills with no direct trigger are valid building blocks for larger workflows.

## Skills

| Skill | Description |
| ----- | ----------- |
| **apply-repo-baseline** | Bring a repo or org up to my standard baseline — branch ruleset, merge/Actions settings, security toggles, CI layout. Also audits drift across many repos. |
| **migrate-legacy-ci** | Decide what to do with a repo still on the old `nodejs.yml` pipeline — archive it, drop its CI, or migrate to the `pull-request.yml` + `release.yml` split. Run before the baseline. |
| **community-proposal** | Contribute a design proposal to an open-source community — research, draft with evidence, file. |
| **workflow-planning** | Plan-first for non-trivial tasks. Write to `tasks/todo.md`, track progress, re-plan when things go sideways. |
| **verification-before-done** | Never claim a task complete without evidence. Run tests, linter, build. |
| **autonomous-bug-fixing** | Fix bugs without hand-holding. Bug report → investigate → fix → verify. No clarification loops. |
| **subagent-strategy** | Use subagents for research, exploration, and parallel work. Keep main context clean. |
| **self-improvement-loop** | Capture corrections in `tasks/lessons.md`. Review at session start. Prevent repeat mistakes. |
| **demand-elegance** | Pause on non-trivial changes to ask for a more elegant solution. Pragmatism for trivial work. |
| **add-changeset** | Add the right changeset to a change. Detects affected packages in monorepos, chooses bump type, writes changelog-ready summaries. |
| **setup-changesets** | Initialize changesets in a repo. Handles single packages and monorepos. Optionally creates a shared reusable workflow in a `<user/org>/.github` repo. |
| **setup-secretless-release** | Move a changesets or semantic-release pipeline off `NPM_TOKEN`/PAT secrets onto OIDC trusted publishing, and make dependency PRs merge without manual rebases. Diagnoses pipelines that stopped publishing. |
| **transfer-repo-to-org** | Move a repo from a personal namespace into an org without breaking its next release. Re-registers the npm trusted publisher that pins `owner/repo`, fixes metadata, unlocks the merge queue. |
| **audit-release-health** | Sweep an owner's repos for the ones that stopped publishing, grouped by root cause with the evidence to act. Produces the worklist `modernize-repo` works. |

## Installation

### As a plugin

The whole set ships as one universal plugin. Manifests are generated for each runtime:

| Runtime | Manifest |
| ------- | -------- |
| Claude Code | `.claude-plugin/plugin.json` |
| Cursor | `.cursor-plugin/plugin.json` |
| Codex | `.codex-plugin/plugin.json` |
| GitHub Copilot CLI | `plugin.json` (repo root) |

Try it locally by linking the repo into a runtime's local plugin directory:

```bash
ln -sf "$(pwd)" ~/.claude/plugins/local/unional-skills   # Claude Code
ln -sf "$(pwd)" ~/.cursor/plugins/local/unional-skills   # Cursor → Developer: Reload Window
```

The canonical source is `.plugin/plugin.json`; regenerate every vendor manifest with `npx universal-plugin plugin build`. Never edit a generated manifest by hand.

### As individual skills

```bash
# Install a specific skill
npx skills add unional/skills --skill add-changeset

# Install globally (available across all projects)
npx skills add unional/skills --skill add-changeset -g

# Install for a specific agent
npx skills add unional/skills --skill workflow-planning -a claude-code

# Install all skills
npx skills add unional/skills --all

# Local development
npx skills add /path/to/skills --skill <skill-name> -g -y
```

## Bundles

A bundle is a separate skill repo scoped to a specific tool or workflow. Install a bundle the same way:

```bash
npx skills add unional/claude-sharp --all
```

Bundles can override a tool's built-in skills or add behaviors not covered by this repo.

## Discovery

Browse and search skills at [skills.sh](https://skills.sh).

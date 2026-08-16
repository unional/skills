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

Each skill has its own README with the full description and install command.

| Skill | Description |
| ----- | ----------- |
| **[modernize-repo](skills/modernize-repo)** | Bring one repo fully current in a single pass. Orchestrates the skills below in the order their dependencies require; each phase gates the next. |
| **[audit-release-health](skills/audit-release-health)** | Sweep an owner's repos for the ones that stopped publishing, grouped by root cause with the evidence to act. Produces the worklist `modernize-repo` works. |
| **[migrate-legacy-ci](skills/migrate-legacy-ci)** | Decide what to do with a repo still on the old `nodejs.yml` pipeline: archive it, drop its CI, or migrate to the `pull-request.yml` + `release.yml` split. Run before the baseline. |
| **[apply-repo-baseline](skills/apply-repo-baseline)** | Bring a repo or org up to my standard baseline: branch ruleset, merge/Actions settings, security toggles, CI layout. Also audits drift across many repos. |
| **[setup-secretless-release](skills/setup-secretless-release)** | Move a release off `NPM_TOKEN`/PAT secrets onto OIDC trusted publishing, migrating to pnpm + changesets on the way, and make dependency PRs merge without manual rebases. |
| **[transfer-repo-to-org](skills/transfer-repo-to-org)** | Move a repo from a personal namespace into an org without breaking its next release. Re-registers the npm trusted publisher that pins `owner/repo`, fixes metadata, unlocks the merge queue. |
| **[modernize-toolchain](skills/modernize-toolchain)** | Replace a TypeScript library's build, lint, test and dependency stack in one pass: tsdown, biome, turbo, vitest. Deletes before it upgrades. |
| **[technical-writer](skills/technical-writer)** | One documentation standard: controlled plain prose, one home per fact, every external claim backed by a source. Also audits an existing corpus. |

## Installation

### From the marketplace (Claude Code)

The repo is its own single-plugin marketplace, declared in `.claude-plugin/marketplace.json`:

```
/plugin marketplace add unional/skills
/plugin install unional-skills@unional
```

The marketplace is named `unional` and the plugin `unional-skills`, which is where the `@` form comes from.

### As a plugin

The whole set ships as one universal plugin. Manifests are generated for each runtime:

| Runtime | Manifest |
| ------- | -------- |
| Claude Code | `.claude-plugin/plugin.json` |
| Cursor | `.cursor-plugin/plugin.json` |
| Codex | `.codex-plugin/plugin.json` |
| GitHub Copilot CLI | `plugin.json` (repo root) |

The canonical source is `.plugin/plugin.json`; regenerate every vendor manifest with `npx universal-plugin plugin build`. Never edit a generated manifest by hand.

### As individual skills

```bash
# Install a specific skill
npx skills add unional/skills --skill technical-writer

# Install globally (available across all projects)
npx skills add unional/skills --skill technical-writer -g

# Install for a specific agent
npx skills add unional/skills --skill modernize-repo -a claude-code

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

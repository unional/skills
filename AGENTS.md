# Agent Skills

This repository contains reusable skills for AI coding agents (Claude Code, Cursor, Codex, and others).

Skills are designed to be **general-purpose and widely shareable** — they encode workflows, conventions, and decisions that any developer or team can benefit from, not opinions specific to one codebase or organization.

## Principles

- **Decisions over documentation.** A skill should encode what to decide and how, not repeat reference material the model already knows.
- **Narrow and invokable.** Each skill covers one workflow. The agent picks it up when the situation matches, not as ambient context.
- **No baked-in opinions.** Skills detect the user's setup (package manager, monorepo shape, tooling) and adapt rather than assuming a specific stack.

## Skills

| Skill | Description |
| ----- | ----------- |
| **workflow-planning** | Plan-first for non-trivial tasks. Write to `tasks/todo.md`, track progress, re-plan when things go sideways. |
| **verification-before-done** | Never claim a task complete without evidence. Run tests, linter, build. |
| **autonomous-bug-fixing** | Fix bugs without hand-holding. Bug report → investigate → fix → verify. No clarification loops. |
| **subagent-strategy** | Use subagents for research, exploration, and parallel work. Keep main context clean. |
| **self-improvement-loop** | Capture corrections in `tasks/lessons.md`. Review at session start. Prevent repeat mistakes. |
| **demand-elegance** | Pause on non-trivial changes to ask for a more elegant solution. Pragmatism for trivial work. |
| **add-changeset** | Add the right changeset to a change. Detects affected packages in monorepos, chooses bump type, writes changelog-ready summaries. |
| **setup-changesets** | Initialize changesets in a repo. Handles single packages and monorepos. Optionally creates a shared reusable workflow in a `<user/org>/.github` repo. |

## Installation

```bash
# Install a specific skill (Claude Code, global)
npx skills add unional/skills --skill add-changeset -g

# Install all skills
npx skills add unional/skills --all -g

# Install for a specific agent
npx skills add unional/skills --skill workflow-planning -a claude-code -g
```

Browse and discover skills at [skills.sh](https://skills.sh).

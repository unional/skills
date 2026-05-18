# Agent Skills

Reusable skills for AI coding agents — Claude Code, Cursor, Codex, and others.

Skills encode **decisions and workflows**, not documentation. Each skill covers one situation and tells the agent what to do, what to skip, and how to adapt to the user's setup.

## Principles

- **Decisions over documentation.** A skill should encode what to decide and how, not repeat reference material the model already knows.
- **Narrow and composable.** Each skill covers one workflow. Skills can be invoked by situation or called by other skills — never loaded as ambient context. Sub-skills with no direct trigger are valid building blocks for larger workflows.
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

## Discovery

Browse and search skills at [skills.sh](https://skills.sh).

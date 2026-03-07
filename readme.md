# Workflow Orchestration Agent Skills

Workflow orchestration, task management, and core principles for AI coding agents. Install individual skills as needed or combine them for full discipline.

## Skills

| Skill | Description |
| ----- | ----------- |
| **verification-before-done** | Never claim complete without evidence. Run tests, linter, build. Staff-engineer verification discipline. |
| **subagent-strategy** | Use subagents liberally for research, exploration, parallel analysis. Keep main context clean. |
| **self-improvement-loop** | Update `tasks/lessons.md` after corrections. Review at session start. Capture patterns that prevent mistakes. |
| **autonomous-bug-fixing** | Fix bugs without hand-holding. Bug report → investigate → fix → verify. No clarification loops. |
| **workflow-planning** | Plan-first for non-trivial tasks. Write to `tasks/todo.md`, track progress, stop and re-plan when sideways. |
| **demand-elegance** | Pause on non-trivial changes to ask for elegant solutions. Pragmatism for trivial work. |

## Installation

### Individual skill (from GitHub)

```bash
npx skills add unional/skills --skill verification-before-done
npx skills add unional/skills --skill subagent-strategy
npx skills add unional/skills --skill self-improvement-loop
npx skills add unional/skills --skill autonomous-bug-fixing
npx skills add unional/skills --skill workflow-planning
npx skills add unional/skills --skill demand-elegance
```

### Install all skills

```bash
npx skills add unional/skills --skill verification-before-done --skill subagent-strategy --skill self-improvement-loop --skill autonomous-bug-fixing --skill workflow-planning --skill demand-elegance
```

### Local development

```bash
npx skills add /path/to/skills --skill <skill-name> -g -y
```

### Global installation (all agents)

```bash
npx skills add unional/skills --skill <skill-name> -g
```

## Discovery

Browse skills at [skills.sh](https://skills.sh).

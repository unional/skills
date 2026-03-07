---
name: workflow-planning
description: "Plan-first for non-trivial tasks. Enter plan mode, write to tasks/todo.md, stop and re-plan when things go sideways. Use when starting complex work (3+ steps), making architectural decisions, or before implementation."
---

# Workflow Planning

Plan-first for non-trivial tasks. Write plans to `tasks/todo.md`, stop and re-plan when things go sideways.

## When to Use This Skill

- Starting complex work (3+ steps or architectural decisions)
- Before implementation
- When something goes sideways (stop and re-plan)
- For verification steps, not just building

---

## Plan Node Default

- **Enter plan mode** for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, **STOP and re-plan immediately** — don't keep pushing
- Use plan mode for **verification steps**, not just building
- Write detailed specs upfront to reduce ambiguity

**Rule:** No implementation without a plan when the task is non-trivial.

---

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`

**Location:** Create `tasks/todo.md` in the **project** being worked on.

**Template:** See [references/todo-template.md](references/todo-template.md) for structure.

---

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

---
name: self-improvement-loop
description: "Capture corrections in tasks/lessons.md. Update after ANY user correction, write rules to prevent repeat mistakes, review at session start. Use when receiving corrections, starting a session, or building a lessons-learned practice."
---

# Self-Improvement Loop

Capture every correction as a lesson. Build a persistent knowledge base that reduces repeat mistakes.

## When to Use This Skill

- After ANY correction from the user
- At session start (review relevant lessons)
- When establishing a lessons-learned practice
- When the same type of mistake recurs

---

## Rule

**Every correction becomes a lesson. No exceptions.**

---

## What Counts as a Correction

**Create a lesson when:**

- User points out a mistake, wrong approach, or bug
- User reverts or rejects your change
- User says "actually do X" after you did Y
- CI fails due to your change

**Skip (don't create a lesson):**

- Pure preference ("use blue instead of red")
- New requirements, not corrections to prior work

---

## Workflow

1. **After any correction**: Update `tasks/lessons.md` with Pattern, Rule, and Context
2. **Session start**: Review relevant lessons for the project
3. **Iterate**: Ruthlessly refine until mistake rate drops

---

## Session Start Review

- Scan `tasks/lessons.md` for lessons whose Context matches the current task (tech stack, area, or keywords)
- If starting work in a new area, skim the full file
- Before touching code in a previously corrected area, re-read that lesson
- Note 1–3 rules that apply to today's work; before each non-trivial change, ask: "Does any lesson apply here?"

---

## Duplicate Lessons

- **Same mistake**: Merge into the existing entry or strengthen the Rule (it wasn't strong enough)
- **Different mistake or context**: Add a new entry

---

## Location

Create and maintain `tasks/lessons.md` in the **project** being worked on (not in the skill package).

---

## Integration

When completing a workflow-planning task, check "Lessons Captured" in `tasks/todo.md` only after updating `tasks/lessons.md` for any corrections made during that task.

---

## Template

See [references/lessons-template.md](references/lessons-template.md) for structure.

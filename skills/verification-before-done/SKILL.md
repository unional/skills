---
name: verification-before-done
description: "Never claim a task complete without proving it works. Run tests, check linter, verify build. Use when finishing tasks, before marking done, or when the user asks for verification. Requires evidence for every completion claim."
---

# Verification Before Done

Never mark a task complete without proving it works. Apply this discipline before claiming any work is finished.

## When to Use This Skill

- Before claiming any task complete
- When finishing implementation
- When the user asks "is it done?" or "did it work?"
- Before creating PRs or committing

---

## Rule

**No completion claims without fresh verification evidence.**

---

## Requirements

- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

---

## Evidence Table

| Claim | Requires |
|-------|----------|
| Tests pass | Test command output: 0 failures |
| Linter clean | Linter output: 0 errors |
| Build succeeds | Build command: exit 0 |
| Bug fixed | Test original symptom: passes |

---

## Quick Reference

Before saying "done":

1. Run the relevant verification command
2. Capture the output (exit code, stdout)
3. Only then claim completion

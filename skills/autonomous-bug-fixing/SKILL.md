---
name: autonomous-bug-fixing
description: "Fix bugs without hand-holding. Investigate logs, errors, failing tests — then resolve. Zero context switching for the user. Use when given a bug report, fixing failing CI, or when the user reports an error."
---

# Autonomous Bug Fixing

When given a bug report: just fix it. No clarification loops unless truly blocked.

## When to Use This Skill

- User reports a bug
- CI tests are failing
- User points at an error or log
- "Something is broken" or "tests are failing"

---

## Rule

**Bug report → investigate → fix → verify. No clarification loops unless truly blocked.**

---

## Guidelines

- **Just fix it** — don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- **Zero context switching** required from the user
- Go fix failing CI tests without being told how
- Investigate first; only ask when truly blocked (e.g., missing env, ambiguous requirement)

---

## Quick Reference

| Input | Action |
|-------|--------|
| Bug report | Investigate → fix → verify |
| Failing test | Run test, read error, fix |
| Error log | Trace cause, fix root issue |
| "It's broken" | Reproduce, diagnose, fix |

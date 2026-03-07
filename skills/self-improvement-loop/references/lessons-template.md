# Lessons Learned

> Copy this template to `tasks/lessons.md` in your project. Update after ANY user correction.

## Pattern

<What went wrong or what was corrected>

## Rule

<Write a rule for yourself that prevents the same mistake>

## Context

<When does this apply? What triggered the correction?>

## Category (optional)

`testing` | `git` | `architecture` | `security` | `other`

---

## Example Entry

**Pattern:** Used `git push` without verifying tests first; CI failed on main.

**Rule:** Before pushing, run the test suite locally. Never push on red.

**Context:** Any change that touches test-covered code. Applies to this repo's `npm test`.

**Category:** `testing`

---

## How to Use

1. **After any correction**: Add a new entry with Pattern, Rule, and Context
2. **Session start**: Review relevant lessons for the project
3. **Iterate**: Ruthlessly refine until mistake rate drops

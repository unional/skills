# Technical Writer

Applies one documentation standard: controlled plain prose, one home per fact, and every external claim backed by a source.

## When to use

- Writing or revising documentation, READMEs, or skill bodies
- Deciding where a document belongs, or moving, renaming, or splitting a page
- A draft reads as generated and needs its rhythm, filler words, or em dashes fixed
- "Improve the docs", "audit the docs", "this page is too long"
- "This sounds like AI", "humanize this", "remove the em dashes"
- "Where should this be documented"

## What it does

Settles three questions in order: whether the content earns its place, where it belongs, and how it reads. Placement errors survive editing, which is why they come first.

For placement it looks for a `LOOKUP.DOC.md`, checking the repository root and then `.agents/`. That file holds pointers only: where the authority for each kind of claim lives, and which source files generated tables must match. Most repositories will not have one, and a flat repository does not need one, so the skill infers the homes from the layout and states which it assumed before moving anything.

The prose rules are specific and checkable. One instruction per sentence, instructions under 20 words, active voice, one term per concept, no em dashes in prose you write. A list of tell words gets deleted on sight, and a rhythm pass breaks the flat sentence-length band that marks a generated draft.

For an existing corpus it runs the cheapest probes first: size outliers, duplicated facts, tables that have drifted from the code that defines them, and a grep for the machine signature. Every probe is a prompt for judgment, not a verdict.

## Install

```bash
npx skills add unional/skills --skill technical-writer
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

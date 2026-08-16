# Apply Repo Baseline

Converges one repository, or a whole organization, onto a standard settings baseline: branch protection ruleset, merge and Actions settings, security toggles, and the CI/release file layout.

## When to use

- Setting up a new repo and wanting it to match the others
- "Update branch protection", "require all-checks", "apply my repo settings"
- Auditing which repos have drifted from the baseline

Run **migrate-legacy-ci** first on any repo still on the old pipeline. A ruleset that requires `code / all-checks` makes a legacy repo unmergeable forever.

## What it does

Two modes. **Check** reports drift and changes nothing, and is the default unless you clearly ask to apply. **Apply** writes the settings after showing the diff.

The opinions live in `assets/*.json` rather than in the instructions, so changing a default means editing one JSON file. The skill also documents what the GitHub API cannot reach: part of the repository About panel, org-level code scanning attachment, and the hardening items no ruleset covers.

## Install

```bash
npx skills add unional/skills --skill apply-repo-baseline
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

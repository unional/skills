# Transfer Repo To Org

Moves a repo from a personal namespace into an organization without breaking its next release, and repairs everything the transfer silently invalidates.

## When to use

- "Transfer this repo", "move it to the org", "give it org-level secrets"
- **modernize-repo** phase 2 decides the repo's home

## What it does

Most of a repo's configuration survives a transfer. The parts that do not fail on the *next release* rather than on the transfer itself, which is why this is a procedure and not a single API call.

The skill re-registers the npm trusted publisher that pins `owner/repo`, fixes package metadata and badges still pointing at the old location, and turns on the merge queue that only org-owned repos can have. It captures the before state so the after state can be diffed against it; `references/state-diff.md` records what actually changes.

Proven end to end on `unional/search-packages` moving to `cyberuni/search-packages`, which then published `2.2.1` over OIDC and merged through a native queue, then rerun as a batch of five in August 2026. The batch is what turned up the ruleset bypass actors a transfer empties, which deadlock the next release.

## Install

```bash
npx skills add unional/skills --skill transfer-repo-to-org
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

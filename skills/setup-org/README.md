# Set Up an Org

Turns a newly created GitHub organization into one that matches the cyberuni house: a public `.github` repo with the org profile, default community health files, and reusable pnpm workflows; Discussions; an org Project; the org description and homepage; and logo candidates in the cyber-* icon frame.

## When to use

- "Set up the org" / "set up the new org" right after the owner creates it
- "Add a `.github` repo" / "add an org profile"
- "Make an org logo"

## What it does

Copies `cyber-civitas/.github` rather than writing the files fresh, renames the org, rewrites the profile from the org's decision record, and adds the org's packages to the publish gate's first-party list. Then it creates the repo, turns on Discussions, sets the org metadata, and creates a Project.

For the logo it draws three or four glyph candidates in the shared frame and renders them as 512px light and dark PNGs plus a 16px contact sheet. The owner picks one and uploads it: GitHub has no API for org avatars, or for the org's discussion source, so the skill hands those back as a list.

## Install

```bash
npx skills add unional/skills --skill setup-org
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

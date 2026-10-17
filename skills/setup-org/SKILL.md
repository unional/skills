---
name: setup-org
description: "Set up a new GitHub organization in the cyberuni house style — a public .github repo with the org profile, community health files, and reusable pnpm workflows; Discussions; an org Project; org description and homepage; and a logo drawn in the cyber-* icon frame, rendered as light and dark PNG avatars for the owner to pick. Use when asked to 'set up the org', 'set up the new org', 'add a .github repo', 'add an org profile', 'make an org logo', or right after the owner creates an org through the web UI."
---

# Set Up an Org

Turns an empty GitHub organization into one that matches the house: a profile page, default community health files every repo inherits, reusable workflows the repos call, a place for questions, a place to track work, and a mark in the cyber-* icon family.

The reference is [`cyber-civitas/.github`](https://github.com/cyber-civitas/.github). Copy from it, do not write these files fresh. Proven on `cyberuni-agent` (cyber-civitas decision 0006).

## When to use

- The owner created an org in the web UI and it has no repos, profile, or avatar
- An existing house org has no `.github` repo

Not for: moving a repo into the org (**transfer-repo-to-org**), or repo-level settings such as rulesets, merge queue, and security toggles (**apply-repo-baseline**).

## What the owner does, and what you do

GitHub has no API for three of the steps. Plan for them from the start and list them in the report, so the owner gets one list instead of discovering them.

| Step | Who | Why |
| --- | --- | --- |
| Create the org (GitHub and npm) | owner | web UI only; npm needs an interactive login |
| Pick the logo | owner | taste; you draw candidates, never choose |
| Upload the avatar | owner | no API |
| Set the org discussion source | owner | **Settings → Discussions**; no API |
| Members, billing, security settings | owner | not part of this skill |
| Everything else below | you | `gh` |

Get explicit authorization for the public steps: creating a public repo and pushing to it are visible at once. A harness permission check may refuse `gh repo create --public` even when the owner authorized it; stop and report it rather than routing around it.

## Step 1 — Read the org's purpose

Find what the org is for before you write a word of its profile. For a house org there is a decision record (for `cyberuni-agent`, cyber-civitas decision 0006). The profile, description, project, and glyph all come from it. If there is none, ask the owner for one sentence of purpose.

## Step 2 — Build the `.github` repo from the reference

Export the reference's tree, not its history:

```bash
mkdir <scratch>/<org>-github
git -C <reference-clone> archive HEAD | tar -x -C <scratch>/<org>-github
```

Then change only what names the old org:

| Path | Change |
| --- | --- |
| every `cyber-civitas/.github` ref | the new `<org>/.github`. These are the `@v1` self-references the workflows and starter templates call |
| `README.md`, `AGENTS.md`, `.github/CONTRIBUTING.md` | the org name in prose |
| `profile/README.md` | rewrite from Step 1: what the org ships, one table, one **Read more** link |
| `.github/actions/publish-gate/publish-gate.mjs` | add the org's npm scope and its unscoped package names to `FIRST_PARTY`, with a test in `publish-gate.test.mjs`. Wildcards must be a whole scope, so list unscoped names one by one |
| `README.md` § Organization setup | mark each setting *Done* or *Not yet*. The reference lists CodeQL, private vulnerability reporting, Codecov, and Renovate as in place; in a new org none of them are |
| `.github/SUPPORT.md`, `ISSUE_TEMPLATE/config.yml` | the docs site and chat links, if the org has its own |

Keep everything else verbatim: the code of conduct, the issue forms, the pull request template, the pinned action SHAs, the comments that record why a line exists. `FUNDING.yml` stays `ko_fi: unional`.

Check before committing:

```bash
grep -rn -i '<old-org>' .            # expect only deliberate links, such as the docs site
node --test '.github/**/*.test.mjs' 'test/*.test.mjs'
```

Check every link in `profile/README.md` with `curl -o /dev/null -w '%{http_code}'`. A decision record may be merged but not yet deployed.

## Step 3 — Create the repo and push

The repo is new and empty, so the initial commits go straight to `main`:

```bash
git init -b main && git add -A && git commit -s -m "feat: org profile, community health files, and reusable pnpm workflows"
gh repo create <org>/.github --public \
  --description "<org> organization profile, community health files, and reusable workflows" \
  --source . --remote origin --push
gh repo edit <org>/.github --enable-discussions
```

The repo must be **public**: GitHub reads the profile and the default health files only from a public `.github`.

**Do not cut `v1` yet.** The reusable workflows resolve `<org>/.github/...@v1`, and nothing calls them until the first repo moves in. Cutting the tag is a release; leave it as a *Not yet* line in the README and in the report.

## Step 4 — Org metadata and Project

```bash
gh api -X PATCH orgs/<org> -f description="<one sentence from Step 1>" -f blog="<homepage>"
gh project create --owner <org> --title "<org>"
gh project edit <n> --owner <org> --description "<what the project tracks>"
```

The homepage is the site that documents the org's work today, even if it lives under another org. A homepage that 404s is worse than none. Projects start private; leave them so.

`PATCH orgs/<org>` needs an org owner's token. `gh project` needs the `project` scope (`gh auth refresh -s project`).

## Step 5 — Draw logo candidates

Follow the cyber-* icon system, `docs/design/icon-system.md` in `cyberuni/cyber-mux`: the two frame paths copied verbatim, a glyph in the 32..96 slot, at least 5 units of clearance from the frame, monochrome. **add-website** § Icon has the short version.

How to choose a glyph (precedent: the civitas glyph study, § The glyph in `cyber-civitas.github.io/AGENTS.md`):

- Draw 3 or 4 candidates. Each names what the org is, literally. No metaphor that needs a caption.
- Include the carried-over mark, if the decision record names one, as candidate A.
- Reject on sight anything that reads as something else at 16px: a ring reads as a spinner, a hub with spokes reads as a drone, thin detail fills in.

Render each candidate as a 512px PNG on both grounds, plus one contact sheet at 128, 32 and 16px so the owner can judge the favicon sizes. Headless Chrome is enough; no SVG library is needed:

```bash
# light: ink #10111a on #ffffff; dark: ink #f7f8f8 on #10111a
printf '<html><body style="margin:0;background:%s"><img src="%s" width="512" height="512" style="display:block"></body></html>' "$bg" "$svg" > page.html
google-chrome --headless=new --hide-scrollbars --window-size=512,512 --screenshot="$out" "file://$PWD/page.html"
```

Look at the contact sheet yourself before reporting it, and redraw any candidate that fails the 16px test.

Do not commit candidates to the `.github` repo: once public, removing them is a deletion. Save them somewhere durable outside it and give the paths in the report. After the owner picks, commit the chosen SVG pair and both PNGs under `brand/` in the `.github` repo, and the owner uploads `brand/org-avatar-light.png` (or dark) as the avatar.

## Step 6 — Report

One report, with:

1. The `.github` repo URL and its commit
2. The Project URL
3. The org description and homepage as set
4. The logo candidates: label, what each glyph draws, and the path of each render and the contact sheet
5. The owner's list: pick the logo and upload it, set the discussion source, cut `v1` when the first repo moves in, and each *Not yet* line from the README

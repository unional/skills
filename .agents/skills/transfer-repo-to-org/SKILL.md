---
name: transfer-repo-to-org
description: "Move a repo from a personal namespace into an organization without breaking its release — re-registers the npm trusted publisher that pins owner/repo, fixes package metadata and badges, and turns on the merge queue that only org-owned repos can have. Use when asked to 'transfer this repo', 'move it to the org', 'give it org-level secrets', or when modernize-repo phase 2 decides the repo's home."
metadata:
  internal: true
---

# Transfer Repo To Org

Moves one repo from a user namespace to an organization and repairs everything the transfer silently invalidates. Most of the repo's configuration survives; the parts that do not fail on the *next release*, not on the transfer, which is why this is a procedure and not a single API call.

Proven end to end on `unional/search-packages` → `cyberuni/search-packages`, which then published `2.2.1` via OIDC and merged through a native queue.

## When to use

- A publishing repo under a personal namespace needs org-level secrets or a merge queue — neither exists for user-owned repos
- **modernize-repo** phase 2 decided the repo's home is an org
- **setup-secretless-release** step 2 chose to transfer rather than route around the missing capabilities
- A repo was already transferred and its next release failed at publish

Not for: creating the org, converging settings onto the baseline (**apply-repo-baseline**), or the OIDC migration itself (**setup-secretless-release**).

## Sequencing decision, before anything else

**Transfer before registering trusted publishing.** The trust config pins `owner/repo`; registering first means revoking and re-adding it afterwards, which costs a 2FA code and an interactive login. If trust is not yet registered, transfer now and let **setup-secretless-release** step 4 register against the new owner — Step 4 below then does not apply.

If trust is already registered, it must be redone in the same sitting. See the trap.

## The trap

npm trusted publishing pins `owner/repo`. After a transfer the registration no longer matches, and the **next release fails at publish** — with no fallback if `NPM_TOKEN` was already deleted as part of going secretless. Nothing warns at transfer time; the repo looks healthy until a version PR merges days later.

Re-register in the same sitting as the transfer. Never leave the repo overnight in the transferred-but-unregistered state.

## Prerequisites

| Requirement | Check |
| --- | --- |
| Admin on the repo, and org permission to create repos | `gh api repos/<o>/<r> --jq .permissions.admin` |
| Target org confirmed **by the owner** | never pick one — see Step 1 |
| npm >= 11.15.0 | `npm --version` — `npm trust` does not exist below this |
| Interactive npm session | `npm login`; a legacy 2FA-bypass token is rejected for account changes with `E401 ... "You must be logged in to publish packages"`, even with `--otp` |

## Step 1 — Confirm the target org

Choosing the org is the owner's call. Present the candidates and what each already provides; do not pick.

```bash
gh api user/orgs --jq '.[].login'
gh api orgs/<org>/actions/secrets --jq '[.secrets[].name]'
```

An org that already carries the secrets the repo needs turns per-repo copies into one shared copy — that is usually the deciding fact. An org with none offers only the merge queue, which may still be enough.

Transfer is effectively a one-way door for the humans involved: old URLs redirect, but coordinating a move back costs more than getting it right once.

## Step 2 — Capture the before state

The point is to be able to prove what survived rather than assume it. Capture the four things that are expensive to reconstruct:

```bash
gh api repos/<o>/<r>/rulesets --jq '.[].id' | \
  xargs -I{} gh api repos/<o>/<r>/rulesets/{} > /tmp/rulesets-before.json
gh api repos/<o>/<r> --jq '{allow_auto_merge, allow_update_branch, delete_branch_on_merge}' > /tmp/settings-before.json
gh api repos/<o>/<r>/actions/permissions/workflow > /tmp/actions-before.json
gh secret list --repo <o>/<r>
npm trust list <package>
```

`references/state-diff.md` has the capture-and-diff pass as one script, plus what a clean diff looks like.

## Step 3 — Transfer

```bash
gh api -X POST repos/<o>/<r>/transfer -f new_owner=<org>
gh repo view <org>/<r> --json nameWithOwner,owner
```

The repo moves immediately. Old URLs redirect — including git remotes, so an unaware clone keeps pushing successfully.

## Step 4 — Re-register the trusted publisher, now

One config per package, so revoke before re-adding. Per **package name**, not per repo: a monorepo publishing four packages needs four rounds.

```bash
npm trust list <package>
npm trust revoke <package> --id=<id>
npm trust github <package> --file release.yml --repo <neworg>/<repo> --allow-publish -y
npm trust list <package>
```

`--file` names the **caller** workflow (`release.yml`), not the reusable workflow it delegates to. `-y` skips the confirmation prompt but not the 2FA challenge; pass a code as `--otp=<code>` in the equals form, since `npm trust github` otherwise consumes it as the positional package name.

The closing `npm trust list` showing the new `owner/repo` is the only evidence this step produces — a release proves it days later, which is too late.

## Step 5 — Verify what the transfer changed

Diff against Step 2. One field is known to change:

| | outcome |
| --- | --- |
| Ruleset, including bypass actors | survives |
| `allow_auto_merge`, `allow_update_branch`, `delete_branch_on_merge` | survive |
| Repo secrets | survive |
| Old URLs, including git remotes | redirect |
| `default_workflow_permissions` | **resets to the org default** |

OIDC needs `write`, so check it every time even when the org default is supposedly right:

```bash
gh api repos/<org>/<r>/actions/permissions/workflow --jq .default_workflow_permissions
gh api -X PUT repos/<org>/<r>/actions/permissions/workflow -f default_workflow_permissions=write
```

A `read` default produces `startup_failure` with zero jobs and no logs on the next release — see **setup-secretless-release**'s `references/failure-catalogue.md`.

## Step 6 — Redo the references to the old location

Redirects cover URLs; text embedded in published artifacts does not follow them.

1. `repository`, `homepage`, and `bugs` in `package.json` — `repository` is read when **generating provenance**, so a stale value ships in the attestation.
2. Codecov and badge URLs in `readme.md` — and fix any `branch/master` left in them while there.
3. Local remotes on every machine and worktree: `git remote set-url origin git@github.com:<org>/<r>.git`.
4. Any workflow or doc that hardcodes `<olduser>/<repo>`: `grep -rn '<olduser>/<repo>' .`

Add a changeset. `repository` metadata is user-visible in the published package, so the move earns a patch entry rather than riding along silently — use **add-changeset**.

## Step 7 — Merge queue, now that it is available

The ruleset API accepts a `merge_queue` rule **only for org-owned repos** — under a user it fails with `Invalid rule 'merge_queue':` and no detail. The transfer is what unlocks it.

Order matters and reversing it strands every PR: land the `merge_group` trigger on the default branch first, then add the rule. Full procedure in **setup-secretless-release** step 6.

## Step 8 — First release after the transfer

Expect the version PR's runs to sit in `action_required`. In the new location `github-actions[bot]` has no merged commit, so the `first_time_contributors` policy holds its runs — the same one-time approval a fresh repo needs, re-armed by the move.

```bash
gh run list --repo <org>/<r> --status action_required
gh api -X POST repos/<org>/<r>/actions/runs/<id>/approve
```

Approve once; later releases run unattended. Then confirm the publish actually happened — a green run is not proof:

```bash
npm view <package> version
npm view <package>@<version> dist.attestations
```

## What NOT to do

- Do not transfer a repo and leave trusted publishing for later. The failure surfaces at the next release, when the token fallback is already gone.
- Do not register trusted publishing before a transfer you already know is coming.
- Do not choose the target org for the user, or infer it from where their other repos live.
- Do not assume `default_workflow_permissions` survived; it takes the org default.
- Do not rely on the URL redirect for `package.json` metadata — provenance records what the file says.
- Do not add a `merge_queue` rule before the `merge_group` trigger is on the default branch.
- Do not treat the transfer as done until a release has published from the new owner.

## References

- `references/state-diff.md` — capture-before / diff-after script, and what a clean diff looks like
- **setup-secretless-release** — OIDC migration, trusted publisher registration, merge queue, and the release-failure catalogue
- **modernize-repo** — phase 2 is where this skill is invoked from
- **apply-repo-baseline** — re-converge settings if the diff shows drift
- **add-changeset** — the changeset for the metadata change
- https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository — what a transfer moves and what it redirects
- https://docs.npmjs.com/cli/v11/commands/npm-trust/ — `npm trust` subcommands and flags

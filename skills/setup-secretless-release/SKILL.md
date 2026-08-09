---
name: setup-secretless-release
description: "Move a package's release off long-lived NPM_TOKEN/PAT secrets onto OIDC trusted publishing, whether it releases with changesets or semantic-release, and keep dependency PRs merging themselves. Use this skill when a release publishes with a token, has silently stopped publishing, fails with 401 on /-/whoami or ENONPMTOKEN, or when asked to 'fix releases', 'remove NPM_TOKEN', or 'set up trusted publishing'."
---

# Setup Secretless Release

Converts a release pipeline from long-lived secrets to OIDC trusted publishing, then makes dependency PRs merge without manual rebasing. Apply per repo; diagnose before changing anything.

## When to use

- A release workflow authenticates with `NPM_TOKEN` or a `CI_GITHUB_TOKEN` PAT
- A release is failing, or "succeeding" without publishing
- Dependency PRs pile up because each needs a manual rebase after the previous merges
- Auditing an owner's repos for pipelines that stopped publishing

Not for: converging repo settings onto a baseline (**apply-repo-baseline**), or authoring the reusable workflow content itself (that lives in the owner's `.github` repo).

## Prefer changesets over semantic-release — it is a security boundary

This skill supports both, but they are not equivalent, and the difference decides whether a
publish can be inspected at all.

- **semantic-release publishes straight off a push to the default branch.** Nothing sits between
  "merged" and "on npm". There is no artifact to review and nowhere to attach a check.
- **changesets splits the release in two.** A push only opens or updates the Version Packages PR;
  nothing publishes until that PR merges. That PR is the only reviewable view of the next release,
  and it is where **pnpm-publish-gate** diffs the tarball contents and runtime dependencies against
  the published version.

So when a repo could go either way, choose changesets. When a semantic-release repo comes through
this skill, offer the migration (worked example: cyberuni/color-map#212):

- set `version` to the **currently published** version, replacing `0.0.0-development`
- add a `# <package>` H1 to `CHANGELOG.md` — changesets inserts right after it, and without one the
  entries land in the wrong place
- drop `issues: write` from the release caller; only semantic-release needs it
- the trusted publisher names `release.yml`, which does not change — no npm-side reconfiguration

There is a second, non-security reason under the current merge baseline: semantic-release derives
the release type from **commit messages**, so with merge commits every branch commit is analyzed and
a stray `feat:` in a WIP commit cuts an unintended release. changesets ignores commit messages.

Accepted cost either way: a changesets release requires remembering to write a changeset.

## Prerequisites

| Requirement | Check |
| --- | --- |
| Admin on the repo | `gh api repos/<o>/<r> --jq .permissions.admin` |
| npm >= 11.15.0 | `npm --version` — `npm trust` does not exist below this |
| npm session with account-level 2FA | `npm whoami`; legacy 2FA-bypass tokens are rejected for account changes |
| Package already on the registry | trust cannot be pre-registered |

## Step 1 — Diagnose before changing anything

A pipeline can fail in ways that look identical from the PR list. Establish which before touching config.

```bash
gh run list --repo <o>/<r> --workflow=release.yml --limit 3
id=$(gh run list --repo <o>/<r> --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view "$id" --repo <o>/<r> --json jobs --jq '.jobs[] | "\(.name): \(.conclusion)"'
gh run view "$id" --repo <o>/<r> --log-failed | grep -iE 'error|E[0-9]{3}' | head -20
gh secret list --repo <o>/<r>
```

Read the failing job's **name and duration** first — they identify the class faster than the log:

| Signal | Cause |
| --- | --- |
| Run fails in ~0s, no jobs | The workflow file names a reusable workflow that does not exist |
| `startup_failure`, no jobs, no logs | Callee requests more permission than the caller holds — check `default_workflow_permissions` |
| `Input required and not supplied: token` | Workflow checks out with a PAT the repo does not have |
| `401 Unauthorized - GET .../-/whoami` | `NPM_TOKEN` expired or revoked |
| `ENONPMTOKEN: No npm token specified` **after** migrating | Not a token problem — OIDC was never reached. See the failure catalogue |
| `Publish command exited with code 1` | Real failure in the publish step — read further, do not assume auth |

Load `references/failure-catalogue.md` for the full set with worked examples.

**Verify the reusable workflow names actually resolve.** A singular/plural typo fails in 0s and is invisible unless looked for:

```bash
gh api repos/<owner>/.github/contents/.github/workflows --jq '.[].name'
```

## Step 2 — Decide where the repo lives

Two capabilities are unavailable to repos owned by a **user** rather than an organization, and both shape everything downstream:

| | personal namespace | organization |
| --- | --- | --- |
| Shared secrets | none — one copy per repo, PATs expire | org-level secrets |
| Merge queue | unavailable — the ruleset API rejects a `merge_queue` rule with `Invalid rule 'merge_queue':` and no detail | available (public repos on any plan) |

If the repo publishes and its owner has a suitable org, transferring removes the root cause instead of routing around it. Confirm the target org with the user — never pick one for them.

Transferring is fine mid-migration, but **re-register trusted publishing immediately after** (Step 4): the config pins `owner/repo` and silently stops matching.

```bash
gh api -X POST repos/<o>/<r>/transfer -f new_owner=<org>
```

Then update `repository`, `homepage`, and `bugs` in `package.json` — `repository` is read when generating provenance.

## Step 3 — Point the release at a secretless workflow

Once the section above has settled the release tool, the workflow follows from the **package
manager**:

| Package manager | changesets | semantic-release |
| --- | --- | --- |
| pnpm | `pnpm-release-changeset-oidc.yml` | `pnpm-release-semantic-oidc.yml` |
| bun | `bun-release-changeset-oidc.yml` | none |
| yarn | none | `yarn-release-semantic-oidc.yml` — **`unional` only** |

**Check the owner before picking a row.** `unional/.github` and `cyberuni/.github` do not carry the
same set:

```bash
gh api repos/<owner>/.github/contents/.github/workflows --jq '.[].name'
```

**`cyberuni` has no `yarn-*` workflows at all** — not verify, not release. A yarn repo bound for the
org therefore has nowhere to point, and converting it to pnpm stops being a later phase and becomes
a precondition of this one (**modernize-repo**, package-manager phase). Verified 2026-08-08; it is
what blocked three repos in the first OTP batch.

A repo living in the org should call the org's copy for **every** job, release and verify alike.
Reaching into a personal namespace for the `code` job reintroduces the single point of failure the
transfer removed.

If a repo uses a package manager the matching workflow does not cover, derive a new variant from the existing OIDC one and change only the auth — never start from the token-based workflow.

The caller grants permissions; the callee cannot exceed them.

```yaml
  release:
    uses: <owner>/.github/.github/workflows/pnpm-release-changeset-oidc.yml@main
    needs: code
    permissions:
      id-token: write
      contents: write
      pull-requests: write
```

semantic-release needs two more, because `@semantic-release/github` comments on the issues and PRs a release closes:

```yaml
  release:
    uses: <owner>/.github/.github/workflows/yarn-release-semantic-oidc.yml@main
    needs: code
    permissions:
      id-token: write
      contents: write
      issues: write
      pull-requests: write
```

Then confirm the repo's default token can grant that. A callee declaring `id-token: write` under a `read` default produces `startup_failure` with no logs at all:

```bash
gh api repos/<o>/<r>/actions/permissions/workflow --jq .default_workflow_permissions
gh api -X PUT repos/<o>/<r>/actions/permissions/workflow -f default_workflow_permissions=write
```

Add the secretless workflow **alongside** the token-based one in the `.github` repo rather than replacing it, so repos that have not migrated keep working.

## Step 4 — Register trusted publishers

Per **package name**, not per repo — a monorepo publishing four packages needs four registrations. `--file` names the **caller** workflow (`release.yml`); npm validates the entry point, not the reusable workflow it delegates to.

```bash
npm trust github <package> --file release.yml --repo <o>/<r> --allow-publish -y --otp=<code>
npm trust list <package>
```

`--otp=<code>` must use the equals form: `npm trust github` takes a positional package name and otherwise consumes the code as that positional. `-y` skips the confirmation prompt but not the 2FA challenge.

One config per package — changing an existing one needs `npm trust revoke <pkg> --id=<id>` first.

For more than a handful of packages, use the **setup-npm-trusted-publishing** skill (repobuddy), which derives package names from the workspace layout and fails fast on auth errors instead of spending one code per package.

## Step 5 — First release after migrating

Registering trust is additive: token publishing keeps working until explicitly disallowed, so the migration is not a cutover and can be verified before removing anything.

**semantic-release publishes straight from the default branch with no version PR.** Everything below, plus Step 6's ruleset concerns, is changesets-specific — skip it. What a semantic-release repo gets instead is one hazard of its own: the first release on a **maintenance** branch (`1.32.x`) fails `E401` on `npm dist-tag add`, because trusted publishers are not yet allowed to set dist-tags (semantic-release/npm#1023, npm/cli#8547 — both open). A re-run succeeds. Default-branch releases are unaffected, so do not treat this as a failed migration.

The changesets "Version Packages" PR needs a **one-time workflow approval**. Its `pull_request` runs do fire, but land in `action_required` under the `first_time_contributors` policy until `github-actions[bot]` has a merged commit in that repo — so no required check reports and the PR looks checkless.

```bash
gh run list --repo <o>/<r> --status action_required
gh api -X POST repos/<o>/<r>/actions/runs/<id>/approve
```

After that merge the bot is a known contributor and later version PRs run unattended. Delete the `NPM_TOKEN` secret only once a release has published through OIDC.

## Step 6 — Merge queue, if the repo is org-owned

Order matters; reversing it strands every PR.

1. **First**, add `merge_group` to the workflow that produces the required check. The queue builds a temporary branch that fires neither `pull_request` nor `push`, so without this the queue waits forever on a check that never starts.

   ```yaml
   on:
     pull_request:
       types: [opened, synchronize]
     merge_group:
   ```

2. Merge that, **then** add the `merge_queue` rule to the ruleset and set `strict_required_status_checks_policy: false`. The queue tests each candidate against the real base, so requiring up-to-date branches is redundant and strands PRs before they enqueue.

3. Hand dependency merging to one mechanism. A third-party bot's direct `merge` action bypasses a queue rather than feeding it — retire those rules and let Renovate's `platformAutomerge` and Dependabot's `gh pr merge --auto` enqueue natively.

Without a queue the trailing PR still resolves, just slower: Renovate's default `rebaseWhen: auto` detects a strict requirement (it reads rulesets, not only legacy branch protection) and rebases on its next run.

## Step 7 — Validate with two PRs

Open two trivial PRs touching **different files**, arm auto-merge on both, and read the queue branch names:

```bash
gh run list --repo <o>/<r> --limit 10 --json workflowName,event,headBranch \
  --jq '.[] | select(.event=="merge_group") | "\(.headBranch)"'
```

Each is `gh-readonly-queue/main/pr-<N>-<base-sha>`. The second PR's base SHA should be the **first PR's merge commit** — that is the proof the queue rebuilt and re-tested it rather than merging a stale ref. Delete the markers afterwards.

## What NOT to do

- Do not fabricate a required check with a no-op workflow to get a checkless PR through. Approve the runs instead (Step 5).
- Do not try an `on: push` workflow watching `changeset-release/**`. `GITHUB_TOKEN` genuinely does suppress `push` events, so it cannot fire.
- Do not treat trusted publishing as per repo, or point `--file` at the reusable workflow.
- Do not install semantic-release unpinned in a secretless workflow. An old core resolves an old `@semantic-release/npm` that predates trusted publishing, and the OIDC path is skipped silently.
- Do not give `actions/setup-node` a `registry-url` on a semantic-release OIDC job. The `.npmrc` it writes is what produces the spurious `ENONPMTOKEN`.
- Do not chase a maintenance-branch `E401` as a misconfiguration. It is npm/cli#8547 and clears on re-run.
- Do not enable "Require 2FA and disallow tokens" in the same pass as registering trust, before any OIDC publish has succeeded.
- Do not bulk-apply `npm trust` without fail-fast; an auth fault affects every package and burns one 2FA code each.
- Do not add a `merge_queue` rule before the `merge_group` trigger is on the default branch.
- Do not assume a green release run published. Confirm with `npm view <pkg> version`.

## References

- `references/failure-catalogue.md` — release-failure classes with worked examples and diagnostic commands
- https://docs.npmjs.com/trusted-publishers/ — trusted publisher concepts
- https://github.com/semantic-release/npm/issues/1069 — `ENONPMTOKEN` under correct OIDC config; closed as a resolution/`.npmrc` fault, not a plugin bug
- https://github.com/npm/cli/issues/8547 — trusted publishers cannot `npm dist-tag add`; the root of the maintenance-branch `E401`
- https://docs.npmjs.com/cli/v11/commands/npm-trust/ — `npm trust` subcommands and flags
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue — merge queue, including the `merge_group` requirement

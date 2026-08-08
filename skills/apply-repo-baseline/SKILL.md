---
name: apply-repo-baseline
description: "Bring one of unional's repos or organizations up to the standard baseline — branch protection ruleset, merge and Actions settings, security toggles, and the CI/release file layout. Use when setting up a new repo, when asked to 'update branch protection', 'require all-checks', 'apply my repo settings', 'set up this repo like the others', or to audit which repos have drifted from the baseline."
---

# Apply Repo Baseline

Converges a repository (or a whole org) onto the baseline in `assets/`. Two modes: **check** reports drift and changes nothing; **apply** writes after showing the diff. Check is the default when the user has not clearly asked to apply.

The opinions live in `assets/*.json`, not in these steps. Change a default there, never here.

## When to use

- New repo just created, or an existing repo that predates the baseline
- "Update branch protection", "require the all-checks status check", "protect the default branch"
- "Set this repo up like search-packages" / "like the others"
- Auditing: "which of my repos are missing rulesets?"
- Org-level: new org, or aligning org defaults for new repos

Not for: authoring CI workflow content (that lives in each owner's `.github` repo), or repo creation itself.

## Baseline modules

| Module | Target | Data | API |
|---|---|---|---|
| Branch ruleset | repo | `assets/branch-ruleset.json` (+ `rule-code-scanning.json` when CodeQL runs) | `/repos/{o}/{r}/rulesets` |
| Copilot review | repo, opt-in | `assets/copilot-review-ruleset.json` | same |
| Merge settings | repo | `assets/repo-settings.json` | `PATCH /repos/{o}/{r}` |
| Security | repo, public only | `assets/security-settings.json` | `PATCH /repos/{o}/{r}` |
| Actions token | repo | `actions-permissions.json` / `-inherit.json`, by whether the release caller declares `permissions:` — see § 5 | `PUT /repos/{o}/{r}/actions/permissions/workflow` |
| Org defaults | org | `assets/org-settings.json` | `PATCH /orgs/{org}` |
| Dependency automation | repo | `assets/renovate-preset.json` | files + `/repos/{o}/{r}/automated-security-fixes` |
| File layout | repo | table in § File layout | files in the repo |

## Steps

### 1. Resolve targets and stop-conditions

Single repo: `gh repo view --json nameWithOwner` when inside one, else ask.

Whole org or user: `gh repo list <owner> --no-archived --source -L 200 --json nameWithOwner,pushedAt,isPrivate,visibility`. Filter to repos pushed within the last year unless told otherwise — dormant repos are noise, and applying a ruleset to one you will never touch just adds a wall you must bypass later. **Print the target list and get confirmation before any write**, always, even for one repo.

Two hard stops discovered in the field:

- **Private repo on a free plan**: `/rulesets` returns 403 "Upgrade to GitHub Pro or make this repository public". Rulesets and secret scanning are unavailable. Skip those two modules, apply the rest, and say which repos were skipped and why.
- **Org-level rulesets need GitHub Team.** `/orgs/{org}/rulesets` returns 403 on all of unional's orgs. Org-wide protection is therefore applied **per repo** — do not offer an org ruleset as an option.

### 2. Verify the required status check exists before protecting anything

The ruleset requires the context `code / all-checks`. That string is `<caller job id> / <aggregator job id>`, produced only by this shape:

```yaml
# .github/workflows/pull-request.yml
jobs:
  code:                                    # ← job id supplies the first half
    uses: <owner>/.github/.github/workflows/pnpm-verify-linux.yml@main
```

where the reusable workflow ends with an `all-checks` job that fails if `verify` did not succeed.

Check the repo's `.github/workflows/pull-request.yml` for a job whose id is `code` calling one of the owner's `pnpm-verify*` reusable workflows. If it is missing or named differently, **fix CI first or the branch becomes unmergeable** — a required context that no run ever reports blocks every PR forever. Offer either: add the workflow (§ File layout), or apply the ruleset without the `required_status_checks` rule and note the gap.

Confirm from a real run rather than the filename — `gh api repos/$R/commits/$(gh api repos/$R/commits/main --jq .sha)/check-runs --jq '.check_runs[].name'`.

**Stop if the repo is on a legacy CI shape.** A single `nodejs.yml` calling `typescript-build.yml` / `typescript-test*.yml` / `npm-release.yml`, or hand-rolled steps, reports `build / …` and `test / …` and can never produce `code / all-checks`. Do not apply this baseline to such a repo — run **migrate-legacy-ci** first. It decides whether the repo should be archived, have its CI dropped, or be migrated, and most of them should not be migrated at all.

Choose the reusable workflow by owner convention: `pnpm-verify-linux.yml` where it exists (unional), `pnpm-verify.yml` otherwise (clibuilder, cyberuni, repobuddy). Confirm the file exists in `<owner>/.github` before pointing at it.

### 3. Compose the desired ruleset

Start from `assets/branch-ruleset.json`. Then:

- Repo has `.github/workflows/codeql-analysis.yml` → append `assets/rule-code-scanning.json` to `rules`.
- User asked for Copilot review, or the repo already has that ruleset → also reconcile `assets/copilot-review-ruleset.json` as a **separate** ruleset. Keep it separate; that is how the repos that have it are shaped, and it lets the review rule be dropped without touching protection.

### 4. Diff, then apply

For each module, read current state, compare to desired, print a compact diff. Then apply only what differs:

```bash
# Ruleset: reconcile by NAME. Creating a second ruleset over the same branch
# silently stacks both — the union applies and it is confusing to unwind.
id=$(gh api "repos/$R/rulesets" --jq '.[] | select(.name=="main") | .id')
[ -n "$id" ] \
  && gh api -X PUT  "repos/$R/rulesets/$id" --input desired.json \
  || gh api -X POST "repos/$R/rulesets"     --input desired.json

gh api -X PATCH "repos/$R" --input assets/repo-settings.json
gh api -X PUT   "repos/$R/actions/permissions/workflow" --input "$perms"   # § 5 picks the file — run it LAST
gh api -X PATCH "repos/$R" --input assets/security-settings.json   # public repos only
```

<!-- TODO: extract the read-diff-apply loop to a script; it is fully deterministic -->

Invariants to enforce while diffing — these are couplings, not preferences:

| Invariant | Why |
|---|---|
| `required_linear_history` ⇒ `allow_merge_commit: false` | The merge button produces a commit the ruleset rejects. `repo-settings.json` already sets this; never apply the ruleset without it. |
| `strict_required_status_checks_policy: true` ⇒ `allow_auto_merge: true` | Strict means "branch must be current". Without auto-merge every bot PR needs a manual update-and-wait. |
| Callee `permissions:` ⊄ caller's granted set ⇒ `startup_failure` | The caller's granted set is its job `permissions:` block **if present, else the repo default**; a called workflow's declared `permissions:` must fit inside it. Overflow is rejected at resolution: **zero jobs, no logs, no annotation**, and the UI blames "a workflow file issue". `id-token: write` fits a default set only when that default is `write`. See § 5 — a block-less release caller under a `read` default is a hard failure, not a warning. |
| `strict_required_status_checks_policy: true` ⇒ `allow_update_branch: true` | Strict makes a PR stale as soon as another merges, and GitHub auto-merge **does not update the branch**. Without this flag there is no affordance to update at all, so the PR waits on Renovate's next run. |
| Merge queue ⇒ `strict_required_status_checks_policy: false` | The queue tests each candidate against the real base, so up-to-date is redundant and strands PRs before they enqueue. The queue also needs `merge_group` on the workflow producing the required check, landed **before** the rule, or it waits forever on a check that never starts. Unavailable to user-owned repos: the ruleset API rejects the rule with `Invalid rule 'merge_queue':` and no detail. |

### 5. Actions token — decided by the release caller's `permissions:` block

`assets/actions-permissions.json` ships `read` and that stays the default. It is safe **only once
the release caller grants its own scopes**, so the one fact that decides this module is whether the
caller declares a `permissions:` block. Read it, do not infer it:

```bash
gh api "repos/$R/contents/.github/workflows/release.yml" --jq .content | base64 -d
```

Find the job whose `uses:` points at a `pnpm-release-changeset*` reusable workflow, then look for
`permissions:` **on that job** (workflow-level counts too; job-level wins where both appear). The
caller's granted set is that block if present, else the repo default — and a callee can only narrow
what it is given, never widen it. `secrets: inherit` passes secrets, not permissions.

Do **not** decide from the callee filename, from `secrets: inherit`, or from OIDC-vs-token. An
`-oidc` callee under a block-less caller fails exactly like a token-based one; the block is the
whole discriminator.

| Caller state | Do this | Default to apply |
|---|---|---|
| Release job declares `permissions:` | nothing | `actions-permissions.json` — `read` |
| No block, and you are editing this repo's files this run | **add the block** (below), land it, then lower | `actions-permissions.json` — `read` |
| No block, and you are not editing the caller (check mode, or the user declined the edit) | leave the caller alone, widen the default, and say so in the report | `actions-permissions-inherit.json` — `write` |
| No `release.yml`, or no job calling a release workflow | nothing to grant | `actions-permissions.json` — `read` |

Prefer the block. It is least privilege, it works under either default, and it survives someone
tightening the org later:

```yaml
  release:
    uses: <owner>/.github/.github/workflows/pnpm-release-changeset-oidc.yml@main
    needs: code
    permissions:
      id-token: write
      contents: write
      pull-requests: write
```

Declaring `permissions:` drops every unlisted scope to `none` — which is why `contents` and
`pull-requests` appear alongside `id-token`, not just the scope the callee obviously needs.

**Order matters.** Land the caller edit *before* the `PUT .../actions/permissions/workflow` that
lowers the repo. Lowering first breaks the next release **silently** — `startup_failure`, zero jobs,
no logs, no annotation, and the UI blames "a workflow file issue" and points at nothing.

**Fail loudly.** A run must never finish leaving a `read` default under a caller with no block. If
the block cannot be added and the default cannot be widened, stop, do not report the repo as done,
and name the state: *release caller declares no `permissions:` and the default is `read` — the next
release will `startup_failure` before any job starts.* Silence here is the actual bug; a repo whose
release cannot resolve looks identically healthy to one that is fine.

Also worth knowing when a caller is missing more than the release scopes — everything else in the
baseline layout self-declares, so none of it needs a `write` default:

| Workflow | Scopes it needs |
|---|---|
| `pull-request.yml` | read only — which is why it starts fine on a repo whose release does not |
| `dependabot-automerge.yml` | `contents: write`, `pull-requests: write` |
| `codeql-analysis.yml` | `security-events: write`, `actions: read` |
| docs/Pages deploy | `pages: write`, `id-token: write` — the caller must grant these |

Where a repo lands in row three, prefer migrating it to the explicit-block shape
(**setup-secretless-release**) and *then* lowering, rather than leaving `write` in place.

Verified 2026-08-08: `unional/stable-context` (`read`, no block → `startup_failure`) against
`unional/assertron` and `unional/path-equal` (`write`, no block → success, otherwise identical),
`clibuilder/clibuilder` (`read` **with** block → success), and `cyberuni/search-packages`
(block present → works, and would work under `read` too).

`can_approve_pull_request_reviews: false` is unconditional.

### 6. Dependency automation — one updater, not three

The rule: **Renovate opens the PRs, GitHub merges them, Dependabot only detects.** Most repos
currently run Renovate *and* a `dependabot-automerge.yml` workflow *and* Mergify rules for both —
three paths racing for the same merge.

Converge a repo onto:

| Item | Desired state | Action |
|---|---|---|
| `.github/renovate.json` | `{"extends": ["github>unional/renovate-preset"]}` | create if missing |
| Dependabot **alerts** | enabled | `PUT /repos/{o}/{r}/vulnerability-alerts` — Renovate reads these to raise fix PRs |
| Dependabot **security updates** | disabled | `DELETE /repos/{o}/{r}/automated-security-fixes` |
| `.github/dependabot.yml` | absent | delete (version updates move to Renovate) |
| `.github/workflows/dependabot-automerge.yml` | absent | delete — automerge policy belongs in the preset, not in per-repo CI |
| `.github/mergify.yml` | absent | delete — GitHub auto-merge + the required check replace it |

File deletions need a PR (the ruleset blocks direct pushes to the default branch). Batch all of
them into one branch per repo — `chore: consolidate dependency automation on renovate` — rather
than one PR per file.

Do not delete Mergify config while its rules are the only thing merging bot PRs. Order matters:
land the preset (with `platformAutomerge`) first, confirm one bot PR merges through GitHub
auto-merge, then remove Mergify and the automerge workflow.

`assets/renovate-preset.json` is the canonical preset body. It lives here so the policy is
reviewable with the rest of the baseline, but it is **published from `unional/renovate-preset`** —
edit it here, then copy to that repo's `default.json`; repos extend the published preset, never
this file. When they disagree, the published one is what actually runs.

Two couplings in that preset worth preserving:

- `rebaseWhen: "behind-base-branch"` is what makes `strict_required_status_checks_policy: true`
  survive automerge. Without it every bot PR stalls waiting to be brought up to date.
- `minimumReleaseAge` is the supply-chain soak, mirroring `minimumreleaseage=1440` in `.npmrc`.
  `vulnerabilityAlerts` shortens it to 1 day rather than zero — a malicious "fix" release is
  exactly the thing an instant security merge would swallow.

### 7. Verify and report

Re-read each changed resource and confirm it matches. Report per repo: applied / already-matching / skipped-with-reason. Never report a repo as done without the re-read.

One check is not a re-read but a resolution guard — run it on every repo that has a `release.yml`,
including ones where nothing changed:

```bash
gh api "repos/$R/actions/permissions/workflow" --jq .default_workflow_permissions
```

`read` **and** a release caller with no `permissions:` block is a failed run, not a clean one. Say
so in the report and leave the repo listed as broken until one side is fixed.

## File layout

Setup mode only — the per-repo files the baseline assumes. Owner-level content (reusable workflows, community health files) belongs in `<owner>/.github`, not copied here.

| File | Content |
|---|---|
| `.github/workflows/pull-request.yml` | job `code` → `<owner>/.github/.github/workflows/pnpm-verify*.yml@main` |
| `.github/workflows/release.yml` | job `code` (same reusable) + job `release` → `pnpm-release-changeset*.yml@main`, `needs: code`, job `permissions: id-token/contents/pull-requests: write` |
| `.github/workflows/codeql-analysis.yml` | copy of the owner's version; required for the code-scanning rule |
| `.github/renovate.json` | `{"extends": ["github>unional/renovate-preset"]}` — the only dependency-automation file; see § 6 |
| `.node-version`, `.npmrc` | pinned Node; `minimumreleaseage=1440` guards against fresh-publish supply-chain attacks |
| `commitlint.config.js` + `.husky/commit-msg` | conventional commits enforced locally |
| `biome.json` | `extends: ["@repobuddy/biome/recommended"]` |
| `.changeset/config.json` | `access: public`, `baseBranch: main` |
| `package.json` scripts | `verify` = `run-p lint verify:pkg`; the reusable workflow runs `pnpm verify` and nothing else |

Prefer **OIDC/trusted publishing** for release (`pnpm-release-changeset-oidc.yml` under unional, `pnpm-release-changeset.yml` under the orgs) — no `NPM_TOKEN` or `CI_GITHUB_TOKEN` to rotate. Each package needs a trusted publisher registered at `npmjs.com/package/<name>/access` naming the repo and the **caller** workflow filename.

## What NOT to do

- Do not apply to a list of repos without printing it first. "All my repos" plus a wrong baseline is a wide blast radius.
- Do not create a ruleset when one with that name exists — update it.
- Do not require `code / all-checks` on a repo that does not produce it. Verify in step 2.
- Do not apply this baseline to a repo still on a legacy CI shape. Route it to **migrate-legacy-ci** first.
- Do not enable `required_linear_history` while merge commits are still allowed.
- Do not hand-edit values into API payloads mid-run. If a default is wrong, change `assets/*.json` so the next repo gets it too.
- Do not decide the Actions default from the callee's filename or from `secrets: inherit`. Read the caller for a `permissions:` block; that is the only thing that decides it.
- Do not lower a repo to `read` before the caller's `permissions:` block has landed, and do not finish a run that leaves a block-less caller under `read`. That combination fails at resolution with no logs — report it as a failure rather than shipping a repo that looks fine.
- Do not offer org-level rulesets. They need GitHub Team; these orgs are on free.
- Do not leave two updaters opening PRs for the same dependency, or two systems merging them.
- Do not remove Mergify before confirming GitHub auto-merge lands a bot PR — that gap means nothing merges.
- Do not touch archived repos.

## References

- `references/research.md` — where each default came from, the variance found across the six owners, and the drift numbers as of 2026-08-07.

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
- "The Version Packages PR has no checks and cannot merge" on a fresh or just-transferred repo

Not for: authoring CI workflow content (that lives in each owner's `.github` repo), or repo creation itself.

## Baseline modules

| Module | Target | Data | API |
|---|---|---|---|
| Branch ruleset | repo | `assets/branch-ruleset.json` (+ `rule-code-scanning.json` when CodeQL runs) | `/repos/{o}/{r}/rulesets` |
| Merge queue | repo, org-owned only | `assets/rule-merge-queue.json` — a rule inside the `main` ruleset, see § 3 | same |
| Copilot review | repo, opt-in | `assets/copilot-review-ruleset.json` | same |
| Merge settings | repo | `assets/repo-settings.json` | `PATCH /repos/{o}/{r}` |
| Security | repo, public only | `assets/security-settings.json` | `PATCH /repos/{o}/{r}` |
| Actions token | repo | `actions-permissions.json` / `-inherit.json`, by whether the release caller declares `permissions:` — see § 5 | `PUT /repos/{o}/{r}/actions/permissions/workflow` |
| Org defaults | org | `assets/org-settings.json` | `PATCH /orgs/{org}` |
| Dependency automation | repo | `assets/renovate-preset.json` | files + `/repos/{o}/{r}/automated-security-fixes` |
| Bypass and approval hardening | repo | § Hardening audit | rulesets + `/actions/permissions/workflow` |
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
- Repo is org-owned and the user wants a queue → append `assets/rule-merge-queue.json` and flip `strict` off, under the preconditions below.

#### Merge shape — MERGE, not SQUASH, and no linear history (revised 2026-08-09)

The owner wants **semi-linear** history: one merge commit per PR, individual commits preserved
underneath. GitHub has no native semi-linear merge (requested since 2022, still unimplemented), so
the closest enforceable approximation is:

| setting | value |
| --- | --- |
| `allow_merge_commit` | `true` |
| `allow_squash_merge`, `allow_rebase_merge` | `false` |
| `merge_queue.merge_method` | `MERGE` |
| `merge_queue.max_entries_to_merge` | `1` |
| `required_linear_history` | **absent** |

`required_linear_history` forbids merge commits outright, so "merge + linear" cannot coexist —
leave it on and every queued merge is rejected. `max_entries_to_merge: 1` is deliberate: batching
collapses several PRs into a single merge commit and destroys the per-PR boundary that is the whole
point. Throughput is unaffected, because `max_entries_to_build: 5` still builds speculatively in
parallel.

Verified on `cyberuni/cyber-asana`: `git log --first-parent` is linear, individual PR commits remain
visible, and a real `merge_group` run passed. **Still open:** whether `MERGE` rebases the second
parent. The PR used to test was already up to date with `main`, so there was nothing to rebase —
settling it needs a PR whose base moves while it is open.

Do **not** offer SQUASH as the streamlining option. It does not reduce friction — the friction is
the review rule and the approval gate, neither of which the merge method touches — and it discards
the history the owner explicitly wants kept.

#### Merge queue — recommended for every org-owned repo

Not opt-in. `strict_required_status_checks_policy: true` is what the baseline ships, and it costs
something: merging one PR makes every other PR stale, and nothing else in the baseline updates them.
GitHub's native auto-merge waits for checks and **never** updates the branch; `allow_update_branch:
true` in `repo-settings.json` is only a manual affordance. Renovate does resolve it — default
`rebaseWhen: auto` detects the strict requirement and reads rulesets, not only legacy branch
protection — but at its polling cadence, and each rebase re-runs the full matrix, so draining N
dependency PRs costs N + (N-1) + … full CI runs. A queue replaces that with one build per candidate
against the real base.

**Do not talk anyone out of a queue on the grounds that they work solo.** The queue's value is not
conflict-serialization — it is that GitHub rebases and merges each PR **server-side** as the one
ahead lands. Without it, something must watch `main` and rebase every other open PR: O(n²) rebase +
CI cycles, and in an agent-driven fleet, O(n²) token spend on a local monitor holding credentials.
Concurrency is also higher than it looks — `cyberuni/cyber-asana` had 7 PRs open at once (6
Dependabot plus the version PR). Check `gh pr list` before asserting a repo is quiet.

Three preconditions, in this order. Each is a hard gate, not a preference:

1. **The repo must be org-owned.** `gh api "repos/$R" --jq .owner.type` → `Organization`. On a
   user-owned repo the ruleset API rejects the rule with `Invalid rule 'merge_queue': ` and an
   **empty** error detail; the identical call succeeds after a transfer to an org. Detect ownership
   *before* offering the queue — the error tells you nothing, so do not learn this from the API.
2. **`merge_group:` must already be on the workflow producing the required check.** The queue builds
   a temporary branch that fires neither `pull_request` nor `push`. Without the trigger, `code /
   all-checks` never starts and the queue waits forever. Land that edit to `pull-request.yml`,
   confirm a run appears, *then* add the rule.
3. **Set `strict_required_status_checks_policy: false` in the same PUT.** The queue tests each
   candidate against the real base, so up-to-date is redundant — and left on, it strands PRs before
   they ever enqueue.

Working parameters live in `assets/rule-merge-queue.json`. All seven are **required**; omitting any
gives the same empty-detail rejection as the org limitation, so the error does not distinguish a
missing parameter from a user-owned repo. Check ownership first and you will know which it was.

Where a queue exists, retire the third-party bot merge rules. A bot's direct `merge` action
**bypasses** the queue rather than feeding it. Renovate's `platformAutomerge` and Dependabot's
`gh pr merge --auto` both enqueue natively, so § 6's convergence is what the queue wants anyway.

Verify with two trivial PRs touching different files, auto-merge armed on both:

```bash
gh run list --repo "$R" --limit 10 --json event,headBranch \
  --jq '.[] | select(.event=="merge_group") | .headBranch'
```

Each is `gh-readonly-queue/main/pr-<N>-<base-sha>`. The second PR's base SHA must be the **first
PR's merge commit** — that is the proof it was rebuilt and re-tested rather than merged stale. Same
base SHA on both means the queue is not doing its job.

On a user-owned repo the queue is unavailable, so the stall stands. There, `strict` stays `true` and
`allow_update_branch: true` is mandatory, not optional — without it a stale PR has no affordance to
update at all and waits on Renovate's next run. Never leave a user-owned repo with `strict: true`
and `allow_update_branch: false`.

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
| `required_linear_history` ⇔ **not** `allow_merge_commit` | Mutually exclusive, in both directions. The current baseline keeps merge commits, so `required_linear_history` must be **absent**; leave it on and every queued merge is rejected. If a repo is deliberately linear instead, then `allow_merge_commit: false` — but do not mix the two. |
| `strict_required_status_checks_policy: true` ⇒ `allow_auto_merge: true` | Strict means "branch must be current". Without auto-merge every bot PR needs a manual update-and-wait. |
| Callee `permissions:` ⊄ caller's granted set ⇒ `startup_failure` | The caller's granted set is its job `permissions:` block **if present, else the repo default**; a called workflow's declared `permissions:` must fit inside it. Overflow is rejected at resolution: **zero jobs, no logs, no annotation**, and the UI blames "a workflow file issue". `id-token: write` fits a default set only when that default is `write`. See § 5 — a block-less release caller under a `read` default is a hard failure, not a warning. |
| `strict_required_status_checks_policy: true` ⇒ `allow_update_branch: true` | Strict makes a PR stale as soon as another merges, and GitHub auto-merge **does not update the branch**. Without this flag there is no affordance to update at all, so the PR waits on Renovate's next run. |
| Merge queue ⇒ `strict_required_status_checks_policy: false` | The queue tests each candidate against the real base, so up-to-date is redundant and strands PRs before they enqueue. The queue also needs `merge_group` on the workflow producing the required check, landed **before** the rule, or it waits forever on a check that never starts. Unavailable to user-owned repos: the ruleset API rejects the rule with `Invalid rule 'merge_queue':` and no detail. Both gates and the parameters are in § 3. |

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

## Hardening audit — four things the ruleset alone does not cover

Run these on every repo whose default branch publishes. Each is a read; report before changing anything.

```bash
R=<owner>/<repo>
gh api repos/$R/rulesets/<id> --jq '{bypass:.bypass_actors, rules:[.rules[].type]}'
gh api repos/$R/actions/permissions/workflow --jq .can_approve_pull_request_reviews
gh api repos/$R/keys --jq 'length'
gh api orgs/<org>/installations --jq '.installations[]|{app:.app_slug,scope:.repository_selection}'
```

| Finding | Why it matters | Fix |
|---|---|---|
| No `pull_request` rule | On a repo with **more than one** write-access actor, nothing requires review | Add the rule with `required_approving_review_count: 1`. **Do not add it to a solo repo** — see below |
| `can_approve_pull_request_reviews: true` | A workflow can satisfy the review requirement itself, hollowing out the rule above | Set `false`; nothing in this baseline needs it |
| `DeployKey` bypass with **zero** deploy keys | Reads as harmless and is — until someone adds a key, which then bypasses every rule silently | Remove the bypass actor. Re-add deliberately if a key is ever needed |
| Apps installed org-wide (`repository_selection: "all"`) | A retired tool keeps posting checks on every repo in the org, including ones transferred in later. Removing its **config** does not stop it; only uninstalling does | Uninstall or re-scope at `/organizations/<org>/settings/installations`. **Human-only** — needs an app JWT or owner UI |

The first three constrain *other* actors, not the admin running the baseline. Say that plainly in the
report rather than implying the repo is now protected against its own owner's automation — that risk is
governed by the auto-merge rule below, not by settings.

#### The review rule costs more than "nothing" on a solo repo — verified 2026-08-09

Earlier guidance here said admin bypass keeps a solo maintainer unblocked "so it costs nothing now".
That is wrong on two counts, both established by adding the rule to all three reference repos and
then removing it again.

1. **Bypass does not apply to the path you actually use.** You cannot approve your own PR, so every
   merge needs a bypass. `gh pr merge` returns `BLOCKED`, because with a queue it tries to *enqueue*
   and enqueueing respects the requirement; only a direct `PUT /repos/{o}/{r}/pulls/{n}/merge`
   bypasses. Every merge, forever, on every repo.
2. **Bypass actors are per-ruleset and easy to omit.** `cyberuni/search-packages` had
   `bypass_actors: []`. Adding the review rule locked the owner out of the repo entirely until
   `RepositoryRole:5` was added. **Read `current_user_can_bypass` before adding this rule** — if it
   is `never`, you are about to lock someone out.

A control that is bypassed on 100% of merges is not a control. It trains the reflex to click through
protection, which is exactly the habit you want intact when a rule *should* stop you.

It also does **not** address the threat people reach for it to stop. An external contributor cannot
merge their own PR regardless — they have no write access. The rule constrains write-access
collaborators, of which a solo repo has none.

Add it when a second write-access human appears. Not before.

Note `RepositoryRole:2` is **triage**, which cannot push — a bypass entry for it grants nothing.
Where you find one, it was almost certainly meant to be `4` (maintain).

**Auto-merge rule.** Enable auto-merge only for PRs from branches **in the repo**, authored by the owner
or the owner's automation, whose commit type cannot publish (`refactor:` / `chore:` / `ci:` / `test:` /
`docs:`). Never a fork PR, whatever its title claims. A fork PR cannot enable auto-merge on itself — that
needs write access — but the rule matters once more than one actor has it.

## Code scanning is attached from the ORG, not set on the repo — 2026-08-09

`PUT /repos/{o}/{r}/code-scanning/default-setup` returns **404**. That is not a permissions error,
which is what makes it easy to misdiagnose — and it is also why the option cannot be found in the
repo's own settings UI.

Default setup is governed by an **org code security configuration**. Attach it:

```bash
gh api orgs/<org>/code-security/configurations --jq '.[] | {id, name, code_scanning_default_setup}'
gh api -X POST "orgs/<org>/code-security/configurations/<id>/attach" \
  --input <(echo '{"scope":"selected","selected_repository_ids":[<repo_id>]}')
gh api "repos/$R/code-security-configuration" --jq .status   # attached | failed
```

The attach **fails while advanced setup exists** — a committed `codeql-analysis.yml` must be deleted
**first**, then attached. Check `status`, not the HTTP code: the POST returns `{}` and 2xx even when
the attach fails.

Also set the configuration as the default for new repos, once per org — otherwise every repo created
from now on starts with no scanning at all:

```bash
gh api -X PUT "orgs/<org>/code-security/configurations/<id>/defaults" \
  --input <(echo '{"default_for_new_repos":"all"}')
```

**Verify with an analysis, not a state field.** `cyberuni/cyber-asana` reported
`state: configured` with `languages: []`; the proof it was really running was
`gh api "repos/$R/code-scanning/analyses?per_page=1"` showing 87 rules evaluated. That repo had **no
code scanning for three weeks** after a commit deleted its CodeQL workflow "in favor of default
setup" that was never enabled — a state that reads as healthy from every settings page.

## Publish gate — the release PR is the last reviewable point

Repos releasing with changesets should call the gate from `pull-request.yml`:

```yaml
  publish-gate:
    if: startsWith(github.head_ref, 'changeset-release/')
    uses: cyberuni/.github/.github/workflows/pnpm-publish-gate.yml@main
    permissions:
      contents: read
```

It diffs the tarball contents and runtime `dependencies` against the published version, **blocking**
files that must never ship (tests, key material, `.env`, repo metadata) and new runtime deps, while
**reporting without failing** on ordinary churn. Do not add it to the required contexts — it is
skipped on every non-release PR, and a skipped check never satisfies a required one.

**This is the argument for changesets over semantic-release, and it is a security argument, not a
preference.** semantic-release publishes straight off a push to the default branch, so there is no
point between "merged" and "on npm" where anything can be inspected — there is nowhere to put this
gate. changesets splits it: a push only opens the Version Packages PR, and nothing publishes until
that PR merges. Prefer changesets on any repo that publishes; migrate semantic-release repos
(worked example: cyberuni/color-map#212).

When migrating off semantic-release: set the package `version` to the **currently published**
version (replacing `0.0.0-development`), and give `CHANGELOG.md` a `# <package>` H1 — changesets
inserts immediately after it, and without one the entries land in the wrong place.

## File layout

Setup mode only — the per-repo files the baseline assumes. Owner-level content (reusable workflows, community health files) belongs in `<owner>/.github`, not copied here.

| File | Content |
|---|---|
| `.github/workflows/pull-request.yml` | job `code` → `<owner>/.github/.github/workflows/pnpm-verify*.yml@main`; add `merge_group:` to `on:` before adding a merge queue rule (§ 3) — the queue's branch fires neither `pull_request` nor `push` |
| `.github/workflows/release.yml` | job `code` (same reusable) + job `release` → `pnpm-release-changeset*.yml@main`, `needs: code`, job `permissions: id-token/contents/pull-requests: write` |
| `.github/workflows/codeql-analysis.yml` | copy of the owner's version; required for the code-scanning rule |
| `.github/renovate.json` | `{"extends": ["github>unional/renovate-preset"]}` — the only dependency-automation file; see § 6 |
| `.node-version`, `.npmrc` | pinned Node; `minimumreleaseage=1440` guards against fresh-publish supply-chain attacks |
| `commitlint.config.js` + `.husky/commit-msg` | conventional commits enforced locally |
| `biome.json` | `extends: ["@repobuddy/biome/recommended"]` |
| `.changeset/config.json` | `access: public`, `baseBranch: main` |
| `package.json` scripts | `verify` = `run-p lint verify:pkg`; the reusable workflow runs `pnpm verify` and nothing else |

Prefer **OIDC/trusted publishing** for release (`pnpm-release-changeset-oidc.yml` under unional, `pnpm-release-changeset.yml` under the orgs) — no `NPM_TOKEN` or `CI_GITHUB_TOKEN` to rotate. Each package needs a trusted publisher registered at `npmjs.com/package/<name>/access` naming the repo and the **caller** workflow filename.

## The version PR with no checks — approve once

Right after applying the baseline to a **newly created or newly transferred** repo, the changesets
"Version Packages" PR appears to have no status checks, and so cannot satisfy the required
`code / all-checks` context. It looks like the check will never arrive.

It already did. Under GitHub's default `first_time_contributors` approval policy, a repo where
`github-actions[bot]` has not previously committed holds the bot's `pull_request` runs in
`action_required` awaiting approval, so nothing reports:

```bash
gh api "repos/$R/actions/runs/<id>" --jq '{event, conclusion, actor: .actor.login}'
# {"event":"pull_request","conclusion":"action_required","actor":"github-actions[bot]"}
```

Approve once. Afterwards the bot is a known contributor and later version PRs run unattended:

```bash
gh run list --repo "$R" --status action_required
gh api -X POST "repos/$R/actions/runs/<id>/approve"
```

Read the policy — repo level, then org — if you want to confirm which rule is holding the run:

```bash
gh api "repos/$R/actions/permissions/fork-pr-contributor-approval"
gh api "orgs/<org>/actions/permissions/fork-pr-contributor-approval"
```

**Change nothing.** The policy is a sensible default; it is not a drift item and the baseline does
not carry a setting for it.

Two corrections from trying otherwise on 2026-08-09:

- **Do not "harden" this to `all_external_contributors`.** It was tried on all three reference repos
  and reverted. On a repo that has never had an external contributor, `first_time_contributors`
  already gates *everyone*, so the stricter value buys nothing — while making the release PR's runs
  need approval every time.
- **"Self-clearing after one approval" is not reliable.** On `cyberuni/cyber-asana` the bot's runs
  were still landing in `action_required` after several approvals and several merged version PRs.
  Treat approving the release PR's runs as a recurring step, not a one-off.

When clearing a backlog, **approve the newest run first**. Approving an older queued run last makes
it start last and cancel the newer one through the shared concurrency group — which surfaces as a
one-second "failure" on the required checks and looks like a broken workflow.

Two dead ends, both tried and reverted on `unional/search-packages`:

- **Do not fabricate the check** with a no-op reusable workflow whose job name reproduces the
  required context (unional/search-packages#203, reverted in #204). It misdiagnoses the cause and
  leaves a permanently green check that verified nothing.
- **Do not reach for an `on: push` workflow watching `changeset-release/**`.** `GITHUB_TOKEN`
  genuinely does suppress `push` events, so it cannot fire — the same recursion guard, real this
  time.

A merge queue **can** merge the version PR once its runs are approved — verified on
`cyberuni/search-packages`, which merged it through the queue with no admin bypass. Earlier guidance
that a queue could never handle a checkless version PR was wrong; the PR is not checkless, its
checks are waiting.

## What NOT to do

- Do not apply to a list of repos without printing it first. "All my repos" plus a wrong baseline is a wide blast radius.
- Do not create a ruleset when one with that name exists — update it.
- Do not require `code / all-checks` on a repo that does not produce it. Verify in step 2.
- Do not apply this baseline to a repo still on a legacy CI shape. Route it to **migrate-legacy-ci** first.
- Do not enable `required_linear_history` while merge commits are still allowed — and note the current baseline keeps merge commits, so it should be absent.
- Do not add a `pull_request` review rule to a repo with one write-access human. It is bypassed on every merge, and on a ruleset with empty `bypass_actors` it locks the owner out. Check `current_user_can_bypass` first.
- Do not propose squash as a way to reduce friction. The friction is the review rule and the approval gate; the merge method is unrelated, and squash discards history the owner wants.
- Do not set `code-scanning/default-setup` on the repo. It 404s. Attach the org code security configuration instead, after deleting any `codeql-analysis.yml`.
- Do not trust `code-scanning/default-setup.state` as proof scanning runs. Check for a real analysis.
- Do not hand-edit values into API payloads mid-run. If a default is wrong, change `assets/*.json` so the next repo gets it too.
- Do not decide the Actions default from the callee's filename or from `secrets: inherit`. Read the caller for a `permissions:` block; that is the only thing that decides it.
- Do not lower a repo to `read` before the caller's `permissions:` block has landed, and do not finish a run that leaves a block-less caller under `read`. That combination fails at resolution with no logs — report it as a failure rather than shipping a repo that looks fine.
- Do not offer org-level rulesets. They need GitHub Team; these orgs are on free.
- Do not leave two updaters opening PRs for the same dependency, or two systems merging them.
- Do not offer a merge queue on a user-owned repo. The rule is rejected with an empty error detail, which reads like a malformed payload and sends you looking in the wrong place.
- Do not add the queue rule before `merge_group:` is on the workflow producing the required check. The queue then waits forever on a check that never starts.
- Do not leave a user-owned repo with `strict: true` and `allow_update_branch: false` — a stale PR would have no way to update at all.
- Do not remove Mergify before confirming GitHub auto-merge lands a bot PR — that gap means nothing merges.
- Do not treat a checkless version PR as a missing check. Approve the `action_required` run once; never fabricate the context with a no-op workflow, and never try to produce it from an `on: push` workflow.
- Do not touch archived repos.

## References

- `references/research.md` — where each default came from, the variance found across the six owners, and the drift numbers as of 2026-08-07.

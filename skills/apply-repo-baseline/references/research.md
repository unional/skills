# Baseline research — 2026-08-07

Survey of `unional`, `repobuddy`, `cyberuni`, `justland`, `clibuilder`, `mocktomata`, with
`unional/search-packages` and `clibuilder/clibuilder` as the most recently worked repos.

## Where the ruleset default came from

Three repos had a default-branch ruleset. They agree on the core and differ at the edges:

| Rule | search-packages (Aug 6, newest) | repobuddy/repobuddy | cyberuni/universal-plugin |
|---|---|---|---|
| `deletion` | ✓ | ✓ | ✓ |
| `non_fast_forward` | ✓ | ✓ | ✓ |
| `required_linear_history` | ✓ | ✓ | — |
| `required_status_checks` → `code / all-checks` | ✓ strict | ✓ strict | ✓ non-strict |
| `code_scanning` (CodeQL) | — | ✓ | — |

Baseline takes the newest as canonical (strict + linear history) and makes CodeQL conditional on
the repo actually running `codeql-analysis.yml`. `integration_id: 15368` is GitHub Actions.

Bypass actors are copied verbatim from search-packages: DeployKey, plus repository roles 2 and 5,
all `always`. They are reproduced rather than reasoned about — if you want to tighten them, decide
once and change `assets/branch-ruleset.json`.

## Drift, measured

74 active (non-archived, source, pushed in 2026) repos across the five orgs:

- **0 rulesets** — the large majority, including `mocktomata/mocktomata`, `justland/just-web*`, `repobuddy/agent-*`
- **1 ruleset** — 13 repos (`main` only)
- **2 rulesets** — `repobuddy/vis-bot`, `cyberuni/cyber-asana` (`main` + Copilot review)
- **403** — private repos on free plans; rulesets unavailable

`unional` (275 repos, personal account) was not scanned exhaustively.

## Settings variance found

| Setting | Observed | Baseline | Note |
|---|---|---|---|
| `allow_merge_commit` | false in search-packages, **true** in the other four | **false** | Required by `required_linear_history`; the `true` repos are the unfixed ones |
| `delete_branch_on_merge` | true everywhere | true | Already consistent |
| `allow_auto_merge` | true everywhere | true | Already consistent |
| `squash_merge_commit_title` | `COMMIT_OR_PR_TITLE` (unional, clibuilder) vs `PR_TITLE` (repobuddy, cyberuni) | `COMMIT_OR_PR_TITLE` | Follows the newest |
| `has_wiki` | false everywhere except `unional/skills` | false | |
| Actions default token | `write` (search-packages, repobuddy) vs `read` (clibuilder) | **conditional** | `read` only where the release caller declares its own `permissions:`; `write` for `secrets: inherit` callers. See below |
| `can_approve_pull_request_reviews` | true except repobuddy/repobuddy | **false** | A workflow approving its own PR defeats review |
| Secret scanning | enabled only on `unional/skills` | enabled (public repos) | Uplift, not current practice |

## Actions default token — the experiment (2026-08-08)

An early draft of this baseline shipped a flat `read` on the reasoning that job-level
`permissions:` make the default irrelevant. That is wrong, and four repos settle it:

| Repo | Caller block | Default | Callee | Result |
|---|---|---|---|---|
| `unional/assertron` | none, `secrets: inherit` | `write` | token-based | success |
| `unional/path-equal` | none, `secrets: inherit` | `write` | token-based | success |
| `unional/stable-context` | none, `secrets: inherit` | `read` | token-based | `startup_failure` |
| `clibuilder/clibuilder` | explicit id-token/contents/pull-requests | `read` | OIDC | success |

The first three are identical in caller shape and callee and differ only in the default, so the
default is decisive when no block is present. The fourth shows a block lifts a `read` repo.

Unified rule: **the caller's granted set is its `permissions:` block if present, else the repo
default; the callee's declared `permissions:` must fit inside it.** `id-token: write` is in a
default set only when that default is `write`.

Not the cause: `CI_GITHUB_TOKEN` vs `GITHUB_TOKEN`. `assertron` and `path-equal` use
`secrets: inherit` against the same CI_GITHUB_TOKEN-consuming callee as `stable-context` and
publish fine. The token split does explain why two baselines exist at all — unional's older
`pnpm-release-changeset.yml` needs `CI_GITHUB_TOKEN` + `NPM_TOKEN` and declares its own
`id-token: write`, while the OIDC callee is secretless and takes its scopes from the caller.

Failure signature to recognize: `startup_failure`, zero jobs, no logs, no annotation; the UI
reports "a workflow file issue" and points at nothing.

## Org level

`/orgs/{org}/rulesets` → 403 "Upgrade to GitHub Team" on all five orgs. Org-wide branch protection
is not purchasable at the current plan, so protection is applied per repo.

`cyberuni` org defaults, representative of the others: `default_repository_permission: read`
(good), every new-repo security default **false**. `assets/org-settings.json` flips the four
new-repo security toggles on; that is an uplift over current state, not a description of it.

## CI shape, converged

Both recent repos are identical in structure: pnpm workspaces + turbo + changesets + biome
(`@repobuddy/biome/recommended`) + commitlint/husky + `.node-version` + mergify + renovate
(`github>unional/renovate-preset`), with thin `pull-request.yml` / `release.yml` delegating to
`<owner>/.github` reusable workflows. `unional/search-packages` additionally carries
`minimumreleaseage=1440` in `.npmrc` and OIDC trusted publishing with no repo secrets.

The `.github` repos hold the reusable workflows; there are variants per package manager
(`pnpm-`, `yarn-`, `bun-`, `rush-`) and per matrix (`-linux`, `-cross-platform`). `unional/.github`
has by far the largest set, including the only `-oidc` release variant.

## Decided: Renovate is the only updater (2026-08-07)

Observed state was three automerge paths per repo — `renovate.json`, `dependabot-automerge.yml`,
and `mergify.yml` rules covering Dependabot, Renovate and Snyk. Collapsed to:

| Layer | Owner | Why |
|---|---|---|
| Detect vulnerabilities | Dependabot **alerts** | Renovate reads GitHub's alerts to raise fix PRs; alerts also feed the security tab |
| Open PRs | Renovate | grouping, scheduling, and `minimumReleaseAge` — none of which Dependabot version updates offer |
| Merge PRs | GitHub auto-merge via `platformAutomerge` | the ruleset stays the gate; no third-party app with write access to main |

Rejected: **Mergify**, because GitHub auto-merge plus a required status check now covers what it
did here, and it is another write-scoped app on every repo — a real supply-chain surface for a
setup that already soaks releases for a day before installing them. Its remaining edge is complex
merge queues, which none of these repos need.

Rejected: **Dependabot version updates**, because automerge policy then lives in a per-repo CI
workflow, which is exactly the thing that drifts. Dependabot *security updates* are off too — the
same fix arrives via Renovate's `vulnerabilityAlerts`, in one queue with one policy.

`assets/renovate-preset.json` holds the resulting policy. Note the published preset
(`unional/renovate-preset/default.json`) still extends `config:base`, deprecated in favour of
`config:recommended` — updating it is part of adopting this.

## Merge queue — probed 2026-08-08

The stall the open question below predicted is real, and nothing in the baseline resolved it on its
own:

| Component | Updates a behind PR? |
|---|---|
| `strict_required_status_checks_policy: true` | no — it creates the stall |
| GitHub native auto-merge | **no** — waits for checks, never updates the branch |
| `allow_update_branch` | was absent from `repo-settings.json`, so no manual affordance either |

Renovate does resolve it — default `rebaseWhen: auto` detects the strict requirement and reads
rulesets, not only legacy branch protection — but at its polling cadence, and every rebase re-runs
the full matrix. Draining N dependency PRs costs N + (N-1) + … full CI runs.

Two things came out of the probe:

- `allow_update_branch: true` is now in `assets/repo-settings.json`, unconditionally. It is the
  floor for repos that cannot have a queue.
- `assets/rule-merge-queue.json` carries the parameters verified working on
  `cyberuni/search-packages`. All seven are required.

The org limitation was established by probing the rule in an isolated disabled ruleset on a
user-owned repo: `Invalid rule 'merge_queue': ` with an **empty** detail. The identical call
succeeded first try after transferring the repo to an org. Omitting any of the seven parameters
produces the same empty-detail rejection, so the error does not distinguish the two causes — check
`.owner.type` first and the ambiguity disappears.

A third-party bot's direct `merge` action bypasses a queue rather than feeding it. Renovate's
`platformAutomerge` and Dependabot's `gh pr merge --auto` enqueue natively, which is another reason
the § 6 convergence and the queue want the same end state.

## Open questions

- **`strict_required_status_checks_policy: true`** stays the default because the alternative needs
  an org. On org-owned repos the answer is the merge queue (which requires `strict: false`); on
  user-owned repos strict stays on and `allow_update_branch: true` is the only affordance.
- **Bypass actors** — role ids 2 and 5 inherited without verification of which UI roles they map to.

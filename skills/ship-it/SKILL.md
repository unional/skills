---
name: ship-it
description: "Ship a pending changesets release: find the repo's open Version Packages PR, approve the workflow run GitHub is holding for approval, verify the required check goes green, merge, and confirm the version actually advanced on the registry. Use when asked to 'ship it', 'release', 'ship', or 'publish' a package, when a Version Packages PR is stuck BLOCKED with no failing check, when a release PR has been open for days, or when `gh pr merge` refuses because a required context never ran."
---

# Ship It

The Version Packages PR is the release gate, and that gate is deliberate — with changesets a human (or an explicitly instructed agent) decides when to publish. This skill is how that decision gets carried out. It does **not** make releases automatic.

## When to use

- "release `<pkg>`" / "ship it" / "publish the pending release"
- A `Version Packages` PR is `BLOCKED` and its check list is **empty**
- A release PR has been open for days with nothing red
- `gh pr merge` fails with a required context that never appeared

## The failure this exists to fix

A changesets release PR can sit unmergeable forever **with nothing reporting a problem**. The required context (`code / all-checks`) never appears, and branch protection blocks the merge on a check that will never exist. Nothing is red and there is no failing job to open. This is green-by-absence, the same shape as a release workflow that references a file that does not exist.

The usual cause is that the PR's `pull_request` runs exist but are held. GitHub creates them and parks them as `action_required`, with zero jobs, until someone approves them. Both release workflows hit it. What differs is who approves:

| Release workflow | Opens the PR with | Who approves the held runs |
| --- | --- | --- |
| `pnpm-release-changeset.yml` (token variant) | the `CI_GITHUB_TOKEN` PAT | you, in step 3. The `first_time_contributors` policy holds a bot with no merged commit in the repo |
| `pnpm-release-changeset-oidc.yml` (secretless) | the built-in `GITHUB_TOKEN` | the workflow itself, right after it opens or updates the PR, when the caller grants `actions: write`. You, in step 3, when it does not, or when the approval step warned |

The secretless workflow's header says so. `cyberuni/.github`'s `pnpm-release-changeset-oidc.yml` at `v2`: "GitHub creates the PR's `on: pull_request` runs (CI, CodeQL) but parks them as `action_required` until someone approves them. A ruleset that requires their checks leaves the PR blocked." Its step "Approve the version packages PR's pending runs" then approves them. `repobuddy/.github`'s copy at `v2` carries the same header and step. Which owners' workflows have the step, and the caller grant it needs, belong to **setup-secretless-release** Step 6 and **apply-repo-baseline** § 5.

An older version of this skill said the secretless workflow's runs never fire. That was wrong. On `repobuddy/buddy-agent-harness` PR #264, changesets/action opened the Version PR with `GITHUB_TOKEN`, and GitHub created its `pull-request` and `CodeQL` runs, each parked as `action_required`. Once approved, they ran full jobs and passed, and the PR went `CLEAN`.

Tell held runs from missing runs by listing them, not by reading the PR:

```bash
gh api "repos/<o>/<r>/actions/runs?branch=changeset-release/main&per_page=20" \
  --jq '.workflow_runs[] | "\(.id) \(.name) \(.head_sha[0:7]) \(.conclusion) \(.created_at)"'
```

- **Held.** A run on the branch's current head with conclusion `action_required`. Approve it (step 3). Approving moves it to `queued`, and jobs appear.
- **Missing.** No `pull_request` run on the branch's current head at all. Nothing can be approved. Use the empty-commit fallback in step 3, which a real user's push fires normally.

Changing the fork-approval policy is not a fix. The policy exists for fork PRs, its three values (`first_time_contributors_new_to_github`, `first_time_contributors`, `all_external_contributors`) offer no way to exempt a bot, and making it stricter only adds approvals.

### If you want it to stop happening

| option | cost |
|---|---|
| **Grant `actions: write` to the secretless release caller** | none. The workflow approves its own Version PR's runs, and no secret is stored. **apply-repo-baseline** § 5 has the caller block |
| GitHub App installation token for `changesets/action` | a private key kept in secrets. The workflow header above rejects it for that reason: "it means a long-lived private key in org secrets" |
| PAT (`CI_GITHUB_TOKEN`) | reintroduces exactly the long-lived secret the migration removed, and its runs are still held |
| leave it | zero setup; one approval per release, which is what this skill does |

**None of these makes a release automatic.** See "Does fixing this risk an accidental release?" below.

## Steps

### 1. Find the release PR

```bash
gh pr list --repo <o>/<r> --state open --head changeset-release/main \
  --json number,mergeStateStatus,createdAt
```

Note `createdAt`. **An open release PR older than a day or two is a stuck release, not a pending decision.**

### 2. Confirm the diagnosis before acting

```bash
gh pr view <n> --repo <o>/<r> --json mergeStateStatus,statusCheckRollup
```

`BLOCKED` with an **empty or short** `statusCheckRollup` is the signature. Then list the branch's runs, newest first, rather than assuming they are held:

```bash
sha=$(gh api repos/<o>/<r>/branches/changeset-release/main --jq .commit.sha)
gh api "repos/<o>/<r>/actions/runs?branch=changeset-release/main&head_sha=$sha&per_page=100" \
  --jq '.workflow_runs[] | "\(.id) \(.name) \(.event) \(.conclusion) \(.created_at)"'
```

A held run has conclusion `action_required` and zero jobs until it is approved:

```bash
gh api repos/<o>/<r>/actions/runs/<id>/jobs --jq '.jobs | length'   # 0 = not run yet
```

On the secretless workflow, also read the latest `release.yml` run on `main`. Its step "Approve the version packages PR's pending runs" either approved the runs or logged a `::warning::` saying why not, such as a caller that does not grant `actions: write`:

```bash
gh run view <release run id> --repo <o>/<r>     # annotations list the step's warning
```

If instead a check is genuinely **failing**, stop — this is not that problem. Fix the failure.

### 3. Approve the held runs, newest first

```bash
gh api -X POST repos/<o>/<r>/actions/runs/<run_id>/approve
```

Returns `{}` and moves the run `action_required` → `queued`. Approve every held run on the branch's current head, not just the one named `pull-request`. CodeQL and any changeset-checking workflow are held too, and a required context may live in any of them. Work newest first: the PR's checks come from the runs on its current head, and a run held on an older head reports on a commit the PR no longer points at. Do not approve those older runs; they spend CI time and change nothing.

**Fallback if there is nothing to approve** (no `pull_request` run on the current head, no permission to approve, or the runs have aged out): push an empty commit from a real user account, which fires `synchronize` and runs the workflows normally.

```bash
git clone --branch changeset-release/main --depth 1 <repo> && cd <repo>
git commit --allow-empty -m "chore: trigger required checks on the release PR"
git push origin changeset-release/main
```

The changesets bot force-pushes over it on its next run, so it costs nothing.

### 4. Wait for green, then merge

Merge normally — respect the repo's merge method and queue:

```bash
gh pr merge <n> --repo <o>/<r>            # enqueues where a merge queue exists
```

### 5. Prove it published

A merged release PR is not a release.

```bash
curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \
  | jq '{latest: ."dist-tags".latest, tags: ."dist-tags"}'
```

Read the registry directly. `npm view` can serve a cache that lags a publish by minutes, long enough to conclude a release failed when it succeeded.

For a package in **prerelease mode** (`.changeset/pre.json` exists), `latest` will not move — the release lands on the prerelease tag. Check `dist-tags.<tag>`, and do not read an unchanged `latest` as a failure.

Confirm provenance where the repo publishes via OIDC:

```bash
curl -s https://registry.npmjs.org/<pkg>/<version> | jq .dist.attestations
```

## Does fixing this risk an accidental release?

No — and it is worth being precise, because the current breakage *feels* like a safety control.

**The release trigger is `push` to `main`**, via `release.yml`. That fires only when the Version Packages
PR is **merged**. Approving a workflow run, or making CI trigger properly, only lets the PR *become
mergeable*; merging it is still a separate, deliberate act.

Verified on these repos before saying so:

- no workflow matches release PRs for auto-merge — the automerge workflows that exist filter on
  `dependabot[bot]` / `renovate[bot]`
- `allow_auto_merge: true` is only the repo *capability*; GitHub auto-merge must be armed on each PR by
  someone
- Renovate's `platformAutomerge` applies to Renovate's own PRs, not to `changeset-release/main`

So the gate that matters — a human or an explicitly instructed agent merging the release PR — is
untouched.

**What you would lose is protection-by-breakage.** Today nothing can merge a release PR because it can
never go green. That is not a designed control,.
Trading it for a real gate is the improvement.

## What NOT to do

- **Do not use `gh pr merge --admin`.** It merges by skipping the verification rather than running it. On a release PR — the one commit that reaches users — skipping the check is least defensible, and the fix costs one API call.
- **Do not go changing the fork-approval policy.** It is not the fix (see above), it guards genuine fork PRs, and it cannot exempt a bot.
- **Do not release on your own initiative.** This skill runs when the owner asks for a release. Landing dependency PRs is routine; publishing is not.
- **Do not treat a merged PR as a shipped release** — check the registry.
- **Do not approve a run on a branch you have not read.** Approving executes that branch's workflows; on a release PR the diff should be only `CHANGELOG.md` and version bumps.

## Sweep the fleet for stuck releases

The failure is silent, so look for it deliberately rather than waiting for someone to notice:

```bash
for r in $(gh repo list <owner> --no-archived --source -L 200 --json nameWithOwner --jq '.[].nameWithOwner'); do
  gh pr list --repo "$r" --state open --head changeset-release/main \
    --json number,createdAt --jq ".[] | \"$r#\(.number) opened \(.createdAt[0:10])\"" 2>/dev/null
done
```

Any result older than a couple of days is a release that stopped shipping.

## References

- **audit-release-health** — the read-only sweep; its second net covers this detection
- **setup-secretless-release** — how these repos publish (OIDC, no tokens); Step 6 says which owners' secretless workflow approves its own Version PR's runs
- **apply-repo-baseline** — § 5 has the release caller's `permissions:` block, `actions: write` included; § The version PR with no checks has the diagnosis in more depth
- **merge-dep-prs** — deliberately excludes release PRs; this skill is where they are handled instead

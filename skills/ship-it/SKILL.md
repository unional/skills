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

There are two causes, and the release workflow the repo calls decides which one you have:

| Release workflow | Opens the PR with | What happens to the PR's `pull_request` runs |
| --- | --- | --- |
| `pnpm-release-changeset.yml` (token variant) | the `CI_GITHUB_TOKEN` PAT | the runs fire and are held in `action_required` until approved, because the `first_time_contributors` policy holds a bot with no merged commit in the repo |
| `pnpm-release-changeset-oidc.yml` (secretless) | the built-in `GITHUB_TOKEN` | the runs do not fire: GitHub does not run workflows for events raised by `GITHUB_TOKEN`, a guard against workflows triggering themselves. A run may still be recorded, as `action_required` with zero jobs |

`cyberuni/.github`'s `pnpm-release-changeset-oidc.yml` states the trade-off in its own header: "No CI_GITHUB_TOKEN. Uses the built-in GITHUB_TOKEN with elevated `permissions`. Trade-off: a PR opened with GITHUB_TOKEN does not trigger `on: pull_request`". Removing the long-lived PAT was the point of the secretless migration. This is the cost.

Tell them apart by approving and reading the result, not by the label:

```bash
gh api repos/<o>/<r>/actions/runs/<id> --jq '{status,conclusion,actor:.actor.login}'
gh api repos/<o>/<r>/actions/runs/<id>/jobs --jq '.jobs | length'
```

- **Held by the approval policy (token variant).** Approving moves the run to `queued` and jobs appear. Treat the approval as a step of every release: the policy is meant to clear once the bot has a merged commit, but it has not reliably done so.
- **Suppressed (secretless variant).** There is no run to approve, or approving produces no jobs. Use the empty-commit fallback in step 3, which a real user's push fires normally.

Changing the fork-approval policy is not a fix for either case. The policy exists for fork PRs, its three values (`first_time_contributors_new_to_github`, `first_time_contributors`, `all_external_contributors`) offer no way to exempt a bot, and making it stricter only adds approvals.

### If you want it to stop happening

Have the release PR opened by an identity whose events do trigger workflows:

| option | cost |
|---|---|
| **GitHub App installation token** for `changesets/action` | short-lived, no long-lived secret — the principled fix |
| PAT (`CI_GITHUB_TOKEN`) | reintroduces exactly the long-lived secret the migration removed |
| leave it | zero setup; one approval or one empty commit per release, which is what this skill does |

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

`BLOCKED` with an **empty or short** `statusCheckRollup` is the signature. Then confirm the runs are parked, rather than assuming:

```bash
gh api "repos/<o>/<r>/actions/runs?status=action_required&per_page=10" \
  --jq '.workflow_runs[] | "\(.id) \(.name) \(.head_branch) \(.created_at)"'
```

Confirm the run really did nothing, rather than trusting the label:

```bash
gh api repos/<o>/<r>/actions/runs/<id>/jobs --jq '.jobs | length'   # 0 = never executed
```

If instead a check is genuinely **failing**, stop — this is not that problem. Fix the failure.

### 3. Approve the parked runs

```bash
gh api -X POST repos/<o>/<r>/actions/runs/<run_id>/approve
```

Returns `{}` and moves the run `action_required` → `queued`. Approve every parked run on `changeset-release/main`, not just the one named `pull-request` — CodeQL and any changeset-checking workflow are parked too, and a required context may live in any of them.

**Fallback if approval is unavailable** (no permission, or the runs have aged out): push an empty commit from a real user account, which fires `synchronize` and runs the workflows normally.

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
- **setup-secretless-release** — how these repos publish (OIDC, no tokens)
- **merge-dep-prs** — deliberately excludes release PRs; this skill is where they are handled instead

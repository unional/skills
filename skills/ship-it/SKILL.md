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

A changesets release PR can sit unmergeable forever **with nothing reporting a problem**.

The changesets action opens and updates `changeset-release/main` using the built-in
`GITHUB_TOKEN`. **GitHub does not run workflows for events raised by `GITHUB_TOKEN`** — a
deliberate guard against workflows triggering themselves in a loop. The run is still recorded, so it
looks like something happened:

```bash
gh api repos/<o>/<r>/actions/runs/<id> --jq '{status,conclusion,actor:.actor.login}'
# {"status":"completed","conclusion":"action_required","actor":"github-actions[bot]"}
gh api repos/<o>/<r>/actions/runs/<id>/jobs --jq '.jobs | length'
# 0
```

**`action_required` with zero jobs is the signature.** Nothing executed. The required context
(`code / all-checks`) therefore never appears, and branch protection blocks the merge on a check that
will never exist.

Nothing is red. There is no failing job to open. The release simply never ships.

**This is green-by-absence** — the same shape as a release workflow that references a file that does not
exist. Both look fine because nothing ran.

### This is a known trade-off, not a misconfiguration

`cyberuni/.github`'s `pnpm-release-changeset-oidc.yml` says so in its own header:

> No CI_GITHUB_TOKEN. Uses the built-in GITHUB_TOKEN with elevated `permissions`.
> Trade-off: a PR opened with GITHUB_TOKEN does not trigger `on: pull_request`

Removing the long-lived PAT was the point of the secretless migration. This is the cost, and it is paid
per release.

### Two things it is *not*

- **Not the fork-approval policy.** `actions/permissions/fork-pr-contributor-approval` is often set to
  `first_time_contributors`, which looks like the culprit and is not: it governs **fork** PRs, and the
  release PR is same-repo (`isCrossRepository=false`). Changing it fixes nothing here, and its three
  values (`first_time_contributors_new_to_github`, `first_time_contributors`,
  `all_external_contributors`) offer no way to exempt a bot anyway.
- **Not a status `github-actions[bot]` can graduate out of.** There is no contributor standing to
  promote. The only lever is **which identity opens the PR**.

### If you want it to stop happening

Have the release PR opened by an identity whose events do trigger workflows:

| option | cost |
|---|---|
| **GitHub App installation token** for `changesets/action` | short-lived, no long-lived secret — the principled fix |
| PAT (`CI_GITHUB_TOKEN`) | reintroduces exactly the long-lived secret the migration removed |
| leave it, approve per release | zero setup, one API call each time — what this skill does |

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
npm view <pkg> version
npm view <pkg> dist-tags
```

For a package in **prerelease mode** (`.changeset/pre.json` exists), `latest` will not move — the release lands on the prerelease tag. Check `dist-tags.<tag>`, and do not read an unchanged `latest` as a failure.

Confirm provenance where the repo publishes via OIDC:

```bash
npm view <pkg> dist.attestations
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
never go green. That is not a designed control, and it is exactly what hid a release stuck for 27 days.
Trading it for a real gate is the improvement.

## What NOT to do

- **Do not use `gh pr merge --admin`.** It merges by skipping the verification rather than running it. On a release PR — the one commit that reaches users — skipping the check is least defensible, and the fix costs one API call.
- **Do not go changing `approval_policy`.** It is not the cause (see above), it guards genuine fork PRs, and it cannot exempt a bot. Changing it is a settings edit that fixes nothing.
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

Any result older than a couple of days is a release that stopped shipping. One found this way had been open **27 days**.

## References

- **audit-release-health** — the read-only sweep; its second net covers this detection
- **setup-secretless-release** — how these repos publish (OIDC, no tokens)
- **merge-dep-prs** — deliberately excludes release PRs; this skill is where they are handled instead

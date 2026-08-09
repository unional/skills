---
name: audit-release-health
description: "Sweep an owner's repos to find which ones stopped publishing, classify each failure by root cause, and report the evidence needed to fix them. Use when asked 'which of my repos are broken?', 'is anything not publishing?', 'audit my releases', 'find repos that need modernizing', or before running modernize-repo so you know which repos to run it on."
metadata:
  internal: true
---

# Audit Release Health

Finds **which** repos are not publishing. `modernize-repo` fixes one repo; this skill produces its worklist. Read-only from start to finish — it inspects, classifies, and reports, and changes nothing.

## When to use

- "Which of my repos are broken?" / "is anything not publishing?"
- Before a modernization pass, to decide which repos are worth the work
- Periodically, because a dead release is silent — nobody notices a package that stopped shipping months ago

Not for: repairing a repo (that is **modernize-repo**), or diagnosing one repo you already know is broken (go straight to **setup-secretless-release**'s `references/failure-catalogue.md`).

## The trap this skill exists to avoid

A combined recent-runs list drops the repos that matter most:

```bash
# WRONG — repos whose last release attempt predates the window vanish silently
gh run list --repo <o>/<r> --limit 40 --json workflowName,conclusion
```

The window is measured in *runs*, not time, so a repo that stopped releasing in May and has been merging PRs ever since has pushed its last release run out of view. Those are exactly the repos broken longest. `color-map`, `fixture` and `events-plus` — dead since May 2026 — were missed this way on the first sweep and found only by a second, targeted pass.

Query each repo's release workflow **directly**, one repo at a time:

```bash
gh run list --repo <o>/<r> --workflow=release.yml --limit 1 \
  --json conclusion,createdAt,databaseId,status
```

Nothing derived from a run window is complete. Say so in the output — see § Report.

## Steps

### 1. Enumerate candidates

```bash
gh repo list <owner> --source --no-archived --limit 400 \
  --json nameWithOwner,pushedAt,isPrivate --jq '.[].nameWithOwner'
```

`--source` drops forks, `--no-archived` drops repos deliberately retired. Do not filter by `pushedAt` here — a repo can be dormant *because* its release broke, and pre-filtering by activity re-introduces the same blind spot in a different shape.

### 2. Resolve each repo's release workflow

`release.yml` is the convention, not a guarantee. A missing file returns HTTP 404 from `gh run list`, which is a **finding**, not an error to swallow:

```bash
gh api repos/<o>/<r>/actions/workflows --jq '.workflows[].path'
```

| What you find | Class |
|---|---|
| `release.yml` exists, has runs | Read its latest run (step 3) |
| `release.yml` exists, zero runs | `never-ran` — workflow landed but never triggered |
| Only `nodejs.yml` (legacy `typescript-build`/`npm-release`) | `legacy-layout` — predates the `pull-request.yml` + `release.yml` split |
| No release workflow at all | `no-pipeline` — publishes by hand, or does not publish |

### 3. Read the latest run and classify

Read the run's **conclusion, duration, and failing job name before any log** — they identify the class faster than log text does:

```bash
gh run view <id> --repo <o>/<r> --json conclusion,jobs \
  --jq '{c:.conclusion, jobs:[.jobs[]|{name,conclusion,startedAt,completedAt}]}'
```

The signatures live in **setup-secretless-release**'s `references/failure-catalogue.md`. Use them; do not restate them here or invent new ones. Route by what you see:

| Observation | Catalogue entry |
|---|---|
| ~0s, zero jobs, no logs | Broken reusable-workflow reference |
| `startup_failure`, zero jobs, no annotation | Callee requests more permission than the caller holds |
| `Input required and not supplied: token` | Missing PAT |
| `401 ... /-/whoami`, `E401` | Expired npm token |
| `changeset: not found` | Missing release tooling |
| `Publish command exited with code 1` after a build step | Publish-time build failure |
| Release job never ran; `verify` failed first | Verify gate failing |

Only read logs for a run you could not classify from job names and durations. When two classes are both plausible, record the **verify gate** one — it masks everything downstream, so a repo can be missing its PAT and never show it.

### 4. Exclude repos that publish nothing — before counting them broken

A red release on a repo with nothing to publish is not a bug worth anyone's time. Check before you file it:

```bash
gh api repos/<o>/<r>/contents/package.json --jq .content | base64 -d \
  | jq -c '{name, private, workspaces}'
```

`private: true` at the root with no publishable workspace package means the pipeline has no output. Two of the twenty-one found in the original sweep (`monorepo-template`, `stable-context`) were exactly this.

Two shapes will fool a naive check:

- **pnpm workspaces are not in `package.json`.** `workspaces` reads `null` and the repo looks like a single private package. Read `pnpm-workspace.yaml` too, then check each matched package's own `private` field — one public workspace package makes the repo publishing.
- **A private root with public workspace packages publishes.** The root's `private: true` only stops the root.

Report these as `no-output`, listed separately. Excluded is not the same as healthy, and the owner may still want the run green.

### 5. Second net — catch what the run query cannot

Step 3 only sees repos whose release workflow ran. A repo whose release stopped being *triggered* looks clean. Cross-check against the registry:

```bash
npm view <pkg> time.modified
gh repo view <o>/<r> --json pushedAt --jq .pushedAt
```

A repo pushed within the year whose package was last published years ago is publishing nothing regardless of what its runs say — `color-map` last published 2022-10, pushed 2026-08.

This is a **suspicion signal, not a verdict**: `pushedAt` moves on any branch push, and a repo can legitimately have had no releasable change. Flag these for a look; do not classify them from this alone.

## Report

Group by root cause, not by repo — the grouping is what makes the work batchable, since one fix usually clears several repos at once. Per repo give: name, class, last release attempt date, the one-line evidence, and the fix owner (**modernize-repo** for most; the catalogue entry names the rest).

State the coverage caveat in the output itself, every time:

> Counts are a **floor, not a ceiling**. Repos with no release workflow, or whose release stopped being triggered, are not visible to a run-based sweep. N repos were checked; M produced a classifiable run.

Say what you actually checked and what you could not. A sweep that implies full coverage is worse than one that admits its edge, because the next person stops looking.

## What NOT to do

- Do not filter a combined `gh run list` by workflow name — query each repo's release workflow directly.
- Do not pre-filter candidates by `pushedAt`; dormancy can be the symptom.
- Do not count a `no-output` repo as broken.
- Do not assume `workspaces` in `package.json` is the whole picture — pnpm repos declare theirs elsewhere.
- Do not read logs before job names and durations; you will spend the time and learn less.
- Do not report a count without the floor-not-ceiling caveat.
- Do not fix anything during the sweep. Audit produces a worklist; **modernize-repo** works it, one repo at a time.
- Do not write to any repo — no dispatching workflows, no re-running runs, no settings changes.

## References

- **setup-secretless-release** — `references/failure-catalogue.md` carries every signature step 3 routes to, plus the fix for each
- **modernize-repo** — the per-repo repair pass this audit feeds
- **apply-repo-baseline** — for repos whose finding is settings drift rather than a broken release

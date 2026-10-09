---
name: sweep-dependency
description: Use this skill when bumping one package across all repos the owner publishes, leaf-first, merging and releasing each.
---

# Sweep Dependency

Apply when one package (usually one of the owner's own, such as `type-plus`) must move to a new version in every repo the owner controls, and each repo's own packages must be released so the repos above it pick up the aligned versions. The owner dispatches pods through the cyberfleet Operator persona. This skill supplies the order, the brief, and the merge and release gates.

## Prerequisites

- The Operator persona is connected (`cyberfleet:operator`). Pods are spawned with `cyberlegion unit spawn --at workspace`.
- The target version is on npm. Confirm the exact string with `npm view <pkg> versions`. The owner may write `beta-12` for `8.0.0-beta.12`.
- The order must say "merge and release". Without that, stop at merged PRs and raise a decision-request for each release.

## Workflow

### 1. Inventory and layer

Run `scripts/inventory.sh <pkg> <owner>...` once with every owner: the orgs the owner named, plus `unional`, `just-func` and `justland` unless excluded. Producers only resolve among repos found in that same call. stdout is one JSON object per dependent repo: `repo`, `archived`, `fork`, `packages[]` (`name`, `version`, `private`, `range`) and `producers[]` (runtime-only).

- Order by **runtime edges only** (`dependencies` and `peerDependencies`). Dev-dependency edges form cycles (assertron ↔ satisfier ↔ tersify) and are ignored.
- Skip `<pkg>`'s own repo, forks of third-party projects, and demo or repro repos. Name each skip in the first report.
- Private or never-published repos still get the update, but no release.
- Keep the queue in a scratchpad file (repo, local checkout, producers, state). A session restart wipes context, and the file is the only record left.

### 2. Dispatch under the cap

- Hold at most the cap the owner set (default 4) of live pods.
- A repo is ready when every runtime producer is **on npm** at its new version, not only merged. A producer whose change was dev-only has no new release and counts as ready once merged.
- When several repos are ready, pick first the repos with the longest chain above them (just-web before mocktomata) and the repos most others use in dev (assertron).
- Spawn from the repo's local checkout. Fill `brief.md`. Append the released-producers list and every break found so far (step 4).
- After each spawn, read the new pane (`herdr pane read <pane>`):
  - Trust prompt shown → `herdr pane send-keys <pane> Down`, `Enter`, wait, then `Enter` again to submit the brief line.
  - Brief line typed but idle (cost `$0.00`) → `Enter`.

### 3. Gate and merge each pod PR

On each report, gate on four facts: done reported, `mergeable` true with `mergeStateStatus` CLEAN, no changes-requested review or unresolved thread, all checks pass. A repo with no PR checks is gated by running its tests on the merged result locally.

- Clean → `scripts/merge-pr.sh <owner/repo> <pr>`. It uses the merge queue when a ruleset has one. Otherwise it uses the method the repo allows: squash, then merge commit, then rebase. stdout is JSON with `method` and `state`. `state` OPEN after `method: queue` means queued. Poll until it reads MERGED before tearing down.
- Not clean → hold. Keep the pod, and raise a decision-request naming the PR and what holds it.
- `DIRTY` after another merge (for example Renovate bumping the same package) → mail the pod on its thread: rebase, keep the target version, re-verify, report again. Gate the rebased PR from scratch.
- After a merge → `scripts/teardown.sh <local-dir> <unit-id>`. It closes the pod, and also the repo workspace that spawn opened on the primary checkout. It is safe only once the worktree holds nothing but `.agents/`.

### 4. Carry breaks forward

A pod that reports a removed export or changed type adds it to the break list. New briefs include the full list, for example: type-plus beta.12 dropped `Pick`/`Omit`/`Required`/`unpartial`/`reduceKey`/`CanAssign`/`IsExtend`, `isType.equal`, and one-arg `assertType`. Briefs also say to avoid adding a new runtime dependency where an inline change works.

### 5. Release

- Changesets repos open a "Version Packages" PR on `changeset-release/main`. If it was opened by `github-actions` (GITHUB_TOKEN), it has no checks. Run `scripts/release-ci.sh <local-dir>` to push an empty commit that starts CI. Ask once per sweep before the first push. A PR opened by a GitHub App (for example `app/repobuddy`) runs CI on its own.
- Gate the release PR like a pod PR (no pod report needed), then merge it.
- **Verify on npm**: `curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> | jq -r '."dist-tags".latest'`; read the registry directly, because `npm view` can lag a publish. A success log and a new git tag prove nothing.
  - Version missing a few minutes after a green run → wait. npm staged-publish lag is normal.
  - Re-run fails `409 Cannot publish over previously staged version` → the first publish landed. Wait.
  - Log stops at `Publishing packages (n/m)` and the version never appears → re-run the release workflow once.
- Release job failed at `publish-gate` with "new runtime dependencies" → the owner decides: add an allow-list entry to the shared gate, or inline the dependency. Never bypass the gate.
- A dependent repo is ready only after this step.

### 6. Report

Lead with state: merged, released (with versions), pods out, held and why, next wave. Name everything deferred, such as dev dependencies a repo could not take without a toolchain migration.

## Anti-patterns

- Ordering by dev-dependency edges, or waiting on a dev-only change's release.
- Treating "merged" or "release run green" as "published".
- Commanding a pod to merge, or merging a PR from another order.
- `gh pr merge --admin`, or an empty-commit push, without the owner's approval.
- Moving a shared workflow tag (`v1`, `v2`) as a side effect. It is a separate decision.
- Leaving the repo workspace open after `unit close`.

## References

- `brief.md`: the pod brief template
- `scripts/`: inventory, merge, release-CI trigger, teardown
- `cyberfleet:authority-governance`, `cyberfleet:merge-backstop-governance`: merge authority and order
- `repobuddy:min-release-age`: exemptions for freshly released packages

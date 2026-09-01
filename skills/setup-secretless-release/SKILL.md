---
name: setup-secretless-release
description: "Move a package's release off long-lived NPM_TOKEN/PAT secrets onto OIDC trusted publishing, migrating it to pnpm + changesets on the way, and keep dependency PRs merging themselves. Use this skill when a release publishes with a token, has silently stopped publishing, fails with 401 on /-/whoami or ENONPMTOKEN, or when asked to 'fix releases', 'remove NPM_TOKEN', or 'set up trusted publishing'."
---

# Setup Secretless Release

Converts a release pipeline from long-lived secrets to OIDC trusted publishing, then makes dependency PRs merge without manual rebasing. Apply per repo; diagnose before changing anything.

## When to use

- A release workflow authenticates with `NPM_TOKEN` or a `CI_GITHUB_TOKEN` PAT
- A release is failing, or "succeeding" without publishing
- Dependency PRs pile up because each needs a manual rebase after the previous merges
- Auditing an owner's repos for pipelines that stopped publishing

Not for: converging repo settings onto a baseline (**apply-repo-baseline**), or authoring the reusable workflow content itself (that lives in the owner's `.github` repo).

## The target is pnpm + changesets. Migrate whenever possible.

**These are not two supported options to choose between.** The standard is pnpm as the package
manager and changesets as the release tool, everywhere. yarn and semantic-release are **legacy
states to be migrated**, not destinations to select — so the question a repo raises is never "which
should this use?" but "can it be migrated in this pass?"

Migrate whenever possible. Defer only when something concrete blocks it, and say what: a released
maintenance branch mid-flight, or a repo whose CI is too broken to prove the conversion. "It
currently works" is not a blocker.

The two moves come as a pair more often than not. Converting the package manager breaks a `yarn-*`
release workflow, so `release.yml` has to move in the same commit anyway (**modernize-repo**,
package-manager phase) — and once it is moving, pointing it at changesets costs almost nothing extra.

### Why changesets is the release tool — a security boundary, not a preference

The difference decides whether a publish can be inspected at all.

- **semantic-release publishes straight off a push to the default branch.** Nothing sits between
  "merged" and "on npm". There is no artifact to review and nowhere to attach a check.
- **changesets splits the release in two.** A push only opens or updates the Version Packages PR;
  nothing publishes until that PR merges. That PR is the only reviewable view of the next release,
  and it is where **pnpm-publish-gate** diffs the tarball contents and runtime dependencies against
  the published version.

Every semantic-release repo that comes through this skill gets migrated (worked example:
cyberuni/color-map#212):

- reconcile `version` against the registry (Step 3). `0.0.0-development` is the placeholder shape, but
  the reconciliation is not migration-specific and repos already on changesets need it too
- add a `# <package>` H1 to `CHANGELOG.md` — changesets inserts right after it, and without one the
  entries land in the wrong place
- drop `issues: write` from the release caller; only semantic-release needs it
- the trusted publisher names `release.yml`, which does not change — no npm-side reconfiguration

There is a second, non-security reason under the current merge baseline: semantic-release derives
the release type from **commit messages**, so with merge commits every branch commit is analyzed and
a stray `feat:` in a WIP commit cuts an unintended release. changesets ignores commit messages.

Accepted cost, deliberately: a changesets release requires remembering to write a changeset. Forget
one and the release run goes green and publishes **nothing** — see the proof step in
**modernize-repo**.

### Why pnpm is the package manager

Beyond matching the rest of the estate, it is the only one the shared workflows fully cover.
`cyberuni/.github` carries `pnpm-*` and `bun-*` reusable workflows and **no `yarn-*` at all** — so a
yarn repo bound for the org has nowhere to point its `code` job or its release, and converting stops
being a later phase and becomes a precondition. Verified 2026-08-08; it is what blocked three repos
in the first OTP batch.

pnpm's strict, non-hoisted `node_modules` is also the point, not a side effect: it surfaces
undeclared dependencies the repo was resolving by accident. Expect the conversion to expose
pre-existing bugs rather than introduce them.

**bun is a legitimate destination where a repo already uses it** — both `bun-verify.yml` and
`bun-release-changeset-oidc.yml` exist in both orgs. Do not convert bun to pnpm as part of this
skill; that is a separate decision. npm and yarn are the ones to migrate.

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
| `E403 cannot publish over previously published versions` | Either `version` was lowered below the registry, or the caller is on `@v1` and got npm 12 |
| Release skipped, publish gate red, everything else green | The tarball or its runtime dependencies changed. PR CI never runs this gate |

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

Transferring is fine mid-migration, but **re-register trusted publishing immediately after** (Step 5): the config pins `owner/repo` and silently stops matching.

```bash
gh api -X POST repos/<o>/<r>/transfer -f new_owner=<org>
```

Then update `repository`, `homepage`, and `bugs` in `package.json` — `repository` is read when generating provenance.

## Step 3 — Reconcile the package against the registry

Run this on **every** repo, including one already on changesets and needing no migration at all.
Nothing below is visible to PR CI, and the first two have shipped broken packages to npm.

First, read the registry directly. `npm view` answers from a cache that was observed serving the
previous version for minutes after a publish, so it is not sound for any before-and-after check:

```bash
curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \
  | jq -r '."dist-tags".latest'
```

### The `version` field has three shapes, and only one is left alone

changesets bumps whatever `package.json` already says. It never consults the registry, so a wrong
starting version publishes exactly as written.

| `version` is | What the next release does | Do |
| --- | --- | --- |
| a placeholder — `0.0.0-development` | publishes the literal stub, and npm moves `dist-tags.latest` onto it | set it to the registry's `latest` |
| behind the registry — repo `7.1.1`, npm `7.2.0` | cuts `7.1.2`, which is older than what is published | set it to the registry's `latest` |
| ahead of the registry — repo `0.2.2`, npm `0.1.0` | cuts forward; correct as it stands | **leave it.** Lowering it queues an `E403 cannot publish over previously published versions` |

Reconcile in the same PR that introduces changesets or first uses it, not in a follow-up.

Two production incidents, both on repos that were **already** on changesets and so skipped every
migration instruction: `fsa-emitter` published `0.0.0` and it took `latest`, and `satisfier` published
`0.0.0-development` and held `latest` for two weeks.

Behind-the-registry is a history artifact rather than carelessness. A repo that went
standard-version → semantic-release → changesets loses versions on the way: standard-version commits
the bump back, and semantic-release derives the version from tags and deliberately does not. Tags
`v7.1.2` and `v7.2.0` then both point at commits whose `package.json` still reads `7.1.1`. Move the
version and leave `CHANGELOG.md` alone. Do not fabricate entries for releases that never generated one.

### Audit the published tarball

One command per package, and it catches defects that PR CI structurally cannot see:

```bash
url=$(curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \
  | jq -r '.versions[."dist-tags".latest].dist.tarball')
curl -sL "$url" | tar tzf - | grep -iE '\.(spec|test)\.|LICENSE'
```

**No licence text, five packages.** All five declare a licence in `package.json` and ship none.
`jest-watch-repeat@3.0.2`, `find-installed-packages@4.0.0` and `@type-plus/kind` keep `LICENSE` only
at the monorepo root, and npm packs relative to the *package* directory. `sort-configs`,
`sort-configs-typescript` and all seven `create` packages have no `LICENSE` file in the repository at
all.

**Tests in the tarball, three packages**, every one from `files` naming a raw source directory:
`files: ["dist", "ts"]` takes that whole tree. `jest-watch-repeat`, `jest-audio-reporter@2.2.3`,
`test-progress-tracker@2.0.6`. The robust form keeps sources for debuggers and excludes the suffixes:

```json
"files": ["dist", "src", "!**/*.{spec,test,unit,accept,integrate,system,perf,stress,study,stories}.*"]
```

The reverse also happens: `color-map-rainbow` shipped no typings because `files` was `["dist"]` and
npm auto-includes `main` but not `typings`.

### Run the publish gate locally before opening the PR

`publish-gate-cli.mjs` packs the working tree and diffs it against the registry. It is a `needs:` of
the release job, so a block stops the release with everything else green, and `code / all-checks`
never runs it — the PR is not where this surfaces. It has caught four real defects so far: a bad
tarball, shipped specs twice, a missing licence, and the `"<pkg>": "link:"` a local `pnpm link .`
wrote into `eslint-plugin-harmony`'s own runtime dependencies (**modernize-toolchain** owns that
mechanism).

Two of its behaviours surprise people, and both block on something that is not a defect:

- **It walks the tree for every non-private `package.json` rather than parsing the workspace globs.**
  An out-of-workspace directory — `old/`, `archive/`, `examples/`, a template payload — trips it on a
  package changesets would never publish. Add `private: true` to that manifest.
- **It diffs runtime dependencies against the published `latest`, which may be years stale.**
  `@unional/create-monorepo@0.1.0` (2019) declared its whole toolchain under `dependencies`, so local
  `0.2.2`'s six real dependencies read as four new ones. There is no per-package allowlist, so the
  judgement is yours: compare against what the package needs now, not against 2019.

## Step 4 — Point the release at a secretless workflow

There are only two destinations, because the target is pnpm + changesets:

| Package manager | Release workflow |
| --- | --- |
| pnpm | `pnpm-release-changeset-oidc.yml` |
| bun — where the repo already uses it | `bun-release-changeset-oidc.yml` |

Both exist in `unional/.github` **and** `cyberuni/.github`. A repo on yarn or npm converts first
(**modernize-repo**, package-manager phase) rather than picking a third row.

`pnpm-release-semantic-oidc.yml` and `yarn-release-semantic-oidc.yml` still exist so unmigrated
repos keep publishing. **They are not destinations.** Do not point a repo at one, and do not
reintroduce the retired rule that simple single-package repos take semantic-release.

`cyberuni` has **no `yarn-*` workflows at all** — not verify, not release — so for an org-bound repo
the conversion is a precondition of this step, not a later phase. Verified 2026-08-08; it is what
blocked three repos in the first OTP batch. Confirm what the owner actually carries rather than
assuming the two are the same:

```bash
gh api repos/<owner>/.github/contents/.github/workflows --jq '.[].name'
```

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

Declare the block even where the repo default is already `write`. It is least privilege, it works
under either default, and it is what allows the default to be lowered to `read` afterwards — which
is the end state. **Land the block before lowering the default**, never the reverse.

A repo still on semantic-release needs `issues: write` as well, because `@semantic-release/github`
comments on the issues and PRs a release closes. Drop it when migrating — it is a reliable marker
that a caller was never converted.

Then confirm the repo's default token can grant that. A callee declaring `id-token: write` under a `read` default produces `startup_failure` with no logs at all:

```bash
gh api repos/<o>/<r>/actions/permissions/workflow --jq .default_workflow_permissions
gh api -X PUT repos/<o>/<r>/actions/permissions/workflow -f default_workflow_permissions=write
```

Add the secretless workflow **alongside** the token-based one in the `.github` repo rather than replacing it, so repos that have not migrated keep working.

### Which ref the caller pins, and why `@v1` is now a hazard

The ref is not cosmetic. `@v1` of the changeset release workflows runs `npm install -g npm@latest`;
only `@v2` and `@main` pin `npm@11`. npm 12 went stable on 2026-07-08 and wraps `npm info --json` in
an array (changesets/changesets#2164), which breaks publishing under **both** changesets CLI majors:

| changesets CLI | What npm 12 does to it |
| --- | --- |
| 2.x | every version reads as unpublished, so it republishes and dies on `E403` |
| 3.x | the npm path is fixed, the pnpm one is not — a pnpm workspace gets a `TypeError` in `getUnpublishedPackages` |

Three repos were exposed on `@v1` under one major or the other. Move them off it.

Between the remaining two, `@main` lands every upstream change in every repo at once; that is how one
`pnpm-verify` playwright bug reached five repos in a day. A moving major tag (`@v2`) is the middle
ground. Advancing that tag for a bugfix is normal, but read the interface diff before you point
repos at it:

```bash
gh api repos/<owner>/.github/compare/v2...main
```

**Pinning the caller does not pin what the workflow calls.** `pnpm-verify.yml` references
`setup-playwright@main` internally, so that composite still floats however tightly every caller is
pinned. Treat a pinned caller as reducing the blast radius, not removing it.

### The changesets action and CLI versions are a matched pair

`changesets/action@v2.x` requires `@changesets/cli` v3; `action@v1` is the pair for cli v2. Batch 2's
first merge died on that mismatch, and it dies at release time because the Version PR is the first
place the action runs.

Two v3 changes are worth knowing here because **PR CI cannot see either one** — both surface only
when `changeset version` runs on the default branch:

- the `prettier` option became `format`, and the detector picks the first installed formatter from a
  fixed order that puts prettier **last**. Three repos died on it.
- the `privatePackages` default flipped to `{version: false, tag: false}`, which hard-fails a
  publishable package that depends on a private one, and silently no-ops an all-private workspace.

Both signatures are in `references/failure-catalogue.md`. The config itself, including the migration
and the option semantics, belongs to **setup-changesets** — do the upgrade there and come back.

## Step 5 — Register trusted publishers

Per **package name**, not per repo — a monorepo publishing four packages needs four registrations. `--file` names the **caller** workflow (`release.yml`); npm validates the entry point, not the reusable workflow it delegates to.

```bash
npm trust github <package> --file release.yml --repo <o>/<r> --allow-publish -y --otp=<code>
npm trust list <package>
```

`--otp=<code>` must use the equals form: `npm trust github` takes a positional package name and otherwise consumes the code as that positional. `-y` skips the confirmation prompt but not the 2FA challenge.

One config per package — changing an existing one needs `npm trust revoke <pkg> --id=<id>` first.
**Expect to need that on every package**, not on the odd one: batch 1 found a stale config on five of
five. Run `npm trust list` before `npm trust github` and revoke what is already there.

### Budget the OTP per window, not per repo

A 2FA code is good for the window, not for a single call — one code registered four packages across
three calls each. So sequence the whole batch around the code rather than around the repo:

1. **Transfer every repo first.** A transfer needs no OTP, and a registration made while the repo is
   still under the old owner returns `E404 PUT`. That is the unauthenticated-write signature, not a
   fault in the workflow you just wrote, and chasing it as one costs another code.
2. Then chain every `npm trust list` / `revoke` / `github` call for the batch onto one code.

For more than a handful of packages, use the **setup-npm-trusted-publishing** skill (repobuddy), which derives package names from the workspace layout and fails fast on auth errors instead of spending one code per package.

## Step 6 — First release after migrating

Registering trust is additive: token publishing keeps working until explicitly disallowed, so the migration is not a cutover and can be verified before removing anything.

**semantic-release publishes straight from the default branch with no version PR.** Everything below, plus Step 7's ruleset concerns, is changesets-specific — skip it. What a semantic-release repo gets instead is one hazard of its own: the first release on a **maintenance** branch (`1.32.x`) fails `E401` on `npm dist-tag add`, because trusted publishers are not yet allowed to set dist-tags (semantic-release/npm#1023, npm/cli#8547 — both open). A re-run succeeds. Default-branch releases are unaffected, so do not treat this as a failed migration.

### The Version PR looks checkless either way, for two different reasons

The "Version Packages" PR reports nothing on both sides of this migration, and the two causes need
opposite responses. **Which one you have is decided by the workflow the repo now calls**, so read
that first rather than the symptom:

| Release workflow | How the PR is opened | What reports |
| --- | --- | --- |
| `pnpm-release-changeset.yml` — token variant | `checkout` `token:` and `github-token:` are the `CI_GITHUB_TOKEN` **PAT** | runs fire, then wait in `action_required` |
| `pnpm-release-changeset-oidc.yml` — secretless | the built-in **`GITHUB_TOKEN`** | **nothing at all** |

**On the token variant the PR needs a one-time workflow approval.** Its `pull_request` runs do fire,
but land in `action_required` under the `first_time_contributors` policy until `github-actions[bot]`
has a merged commit in the repo:

```bash
gh run list --repo <o>/<r> --status action_required
gh api -X POST repos/<o>/<r>/actions/runs/<id>/approve
```

After that merge the bot is a known contributor and later version PRs run unattended.

**On the secretless workflow that remedy does not apply, and there is no run to approve.** A PR
opened with `GITHUB_TOKEN` does not trigger `on: pull_request` workflows at all; the `-oidc`
workflow says so in its own header comment. So under a required-check ruleset the Version PR is
permanently `BLOCKED` and merges only by **admin override**. All five batch-2 repos were merged that
way. Budget for it as a standing cost of the migration rather than a fault to diagnose — a reader
following the `action_required` path here will hunt for a run that does not exist.

Three exits look open and are not. Do not spend a session re-deriving them:

- **A head-branch exemption.** Rulesets key on the **target** ref, so `changeset-release/**` cannot be
  exempted.
- **A merge queue.** A PR must pass its required checks before it can be queued, so the queue is
  downstream of the block.
- **A same-named commit status posted by another job.** A check and a status sharing one name must
  **both** pass, so this adds a second thing to satisfy rather than satisfying the first.

Delete the `NPM_TOKEN` secret only once a release has published through OIDC.

## Step 7 — Merge queue, if the repo is org-owned

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

## Step 8 — Validate with two PRs

Open two trivial PRs touching **different files**, arm auto-merge on both, and read the queue branch names:

```bash
gh run list --repo <o>/<r> --limit 10 --json workflowName,event,headBranch \
  --jq '.[] | select(.event=="merge_group") | "\(.headBranch)"'
```

Each is `gh-readonly-queue/main/pr-<N>-<base-sha>`. The second PR's base SHA should be the **first PR's merge commit** — that is the proof the queue rebuilt and re-tested it rather than merging a stale ref. Delete the markers afterwards.

## What NOT to do

- Do not fabricate a required check with a no-op workflow to get a checkless PR through. On the token
  variant, approve the runs (Step 6). On the secretless one, override as admin and say so.
- Do not hunt for an `action_required` run on a secretless Version PR. `GITHUB_TOKEN` opened it, so no
  run was ever created.
- Do not try an `on: push` workflow watching `changeset-release/**`. `GITHUB_TOKEN` genuinely does suppress `push` events, so it cannot fire.
- Do not treat trusted publishing as per repo, or point `--file` at the reusable workflow.
- Do not install semantic-release unpinned in a secretless workflow. An old core resolves an old `@semantic-release/npm` that predates trusted publishing, and the OIDC path is skipped silently.
- Do not give `actions/setup-node` a `registry-url` on a semantic-release OIDC job. The `.npmrc` it writes is what produces the spurious `ENONPMTOKEN`.
- Do not chase a maintenance-branch `E401` as a misconfiguration. It is npm/cli#8547 and clears on re-run.
- Do not enable "Require 2FA and disallow tokens" in the same pass as registering trust, before any OIDC publish has succeeded.
- Do not bulk-apply `npm trust` without fail-fast; an auth fault affects every package and burns one 2FA code each.
- Do not add a `merge_queue` rule before the `merge_group` trigger is on the default branch.
- Do not assume a green release run published. Confirm against the registry (Step 3), not with
  `npm view` — its cache served the pre-publish version for minutes afterwards.
- Do not lower a `version` that is ahead of the registry. It reads as a typo and it queues an `E403`.
- Do not treat the version reconciliation as part of the semantic-release migration. Both production
  incidents were on repos already using changesets.
- Do not leave a caller on `@v1` of a changeset release workflow. It installs `npm@latest`, and npm 12
  breaks publishing under both changesets CLI majors.
- Do not read a publish-gate block as a bad tarball before checking what it packed. An out-of-workspace
  `package.json` without `private: true` blocks a release for a package nobody publishes.
- Do not spend one OTP code per package or per repo. Transfer everything first, then chain the calls.
- Do not treat yarn or semantic-release as a destination. They are legacy states; migrate, or name the concrete blocker. "It currently works" is not one.
- Do not point a repo at `pnpm-release-semantic-oidc.yml` or `yarn-release-semantic-oidc.yml`. They exist so unmigrated repos keep publishing, not to be selected.
- Do not convert a bun repo to pnpm here. bun has both a verify and an OIDC release workflow, so it is supported; changing it is a separate decision.
- Do not leave a changesets repo without a changeset for the change. The run goes green, publishes nothing, and the version never moves.
- Do not lower `default_workflow_permissions` to `read` before every workflow's own `permissions:` block has landed.

## References

- `references/failure-catalogue.md` — release-failure classes with worked examples and diagnostic commands
- **setup-changesets** — the changesets config itself, including the v2 → v3 upgrade this skill only pairs versions for
- https://docs.npmjs.com/trusted-publishers/ — trusted publisher concepts
- https://github.com/changesets/changesets/issues/2164 — npm 12 wraps `npm info --json` in an array; the root of the `@v1` publish failures
- https://github.com/semantic-release/npm/issues/1069 — `ENONPMTOKEN` under correct OIDC config; closed as a resolution/`.npmrc` fault, not a plugin bug
- https://github.com/npm/cli/issues/8547 — trusted publishers cannot `npm dist-tag add`; the root of the maintenance-branch `E401`
- https://docs.npmjs.com/cli/v11/commands/npm-trust/ — `npm trust` subcommands and flags
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue — merge queue, including the `merge_group` requirement

---
name: modernize-repo
description: "Bring one repo fully current: settings baseline, a release that publishes without long-lived tokens, dependency PRs that merge themselves, and proof it all works. Use this skill when asked to 'modernize this repo', 'bring it up to standard', 'fix everything about this repo', or after a sweep flags a repo as broken."
---

# Modernize Repo

Orchestrates the other skills into one pass over a single repository, in the order their dependencies require. Diagnose first; each phase gates the next.

## When to use

- A repo predates the current conventions and should match the others
- A release-health sweep flagged the repo and it needs end-to-end repair
- Handing one repo to an agent to bring current without further instruction

Not for: sweeping many repos (do that first, then run this per repo), or authoring reusable workflow content in the owner's `.github`.

## Phases

Run in order. Each phase's failures make the next phase's diagnosis ambiguous, so do not parallelize.

### 1. Establish what is broken

Never start by applying config. A verify failure **masks** a missing secret behind it, so a repo can look like one class and be another.

```bash
gh repo view <o>/<r> --json isFork,isArchived,visibility,pushedAt
gh run list --repo <o>/<r> --limit 5
gh secret list --repo <o>/<r>
```

#### Diagnose the evidence before you diagnose the repo

Four false conclusions cost real time in the sweep, and each came from trusting a signal that meant something narrower than it looked.

| Signal | What it actually proves | Read it correctly |
|---|---|---|
| A red workflow run | the state of that workflow **at that run's SHA**, and nothing about the file today | check when the file last changed before concluding anything about it. Five agents independently called a shared workflow broken from runs that predated its fix |
| A commit's date | the *author* date is not the *commit* date | a rebased fix looked 17 days older than it was and produced a wrong conclusion. Read `%cI`, not `%aI` |
| `gh pr list` | the state of open branches, several of which are stale Renovate majors | diagnose from the default branch's own runs. A whole pre-written CI table was wrong on all five repos it covered |
| A workflow that exists | nothing about whether it ever ran | check the trigger branch against the actual default branch. One repo's `nodejs.yml` triggered on `push: master` while the default branch was `main`, so its release job **had never executed once**. Inert from the start, not broken |
| `ELIFECYCLE` | a script exited non-zero | pnpm's generic wrapper. It is not a diagnosis; read the script's own output |
| `gh pr checks` saying `pending` | little; it reports `pending` for checks that have completed | cross-check `gh api repos/<o>/<r>/commits/<sha>/check-runs` |

One more, because it wastes a whole cycle: **`gh run rerun` replays a reusable workflow at the SHA the original run resolved.** It will not pick up a fix landed upstream since. Push a fresh `synchronize` event instead.

Record the failing job's **name and duration** before reading any log — they identify the class faster. Then decide whether the repo is worth the work at all:

```bash
gh api repos/<o>/<r>/contents/package.json --jq .content | base64 -d | jq '{name, private, workspaces}'
curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \
  | jq -r '."dist-tags".latest'
```

Read the registry directly rather than through `npm view`, here and everywhere else in this pass. `npm view` serves a cache that stayed stale for minutes after a publish during the sweep, which is long enough to conclude a release failed when it succeeded.

A private root whose workspace packages are all `private: true` publishes nothing; a red release there may not be worth fixing. Say so and stop rather than repairing a pipeline with no output.

**But "publishes nothing" is not "does not matter."** The sweep found one repo in exactly that shape whose changesets setup failed green, versioning nothing while exiting 0 (see **setup-changesets**, Private packages), and a *template* repo in that shape propagating nine broken patterns into every repo scaffolded from it. Weigh what the repo feeds, not just what it ships.

### 2. Decide the repo's home

A user-owned repo has neither org-level secrets nor a merge queue. If the repo publishes and the owner has a suitable org, transferring removes the root cause instead of routing around it — but it is a one-way door and the target is the user's call, never the agent's.

Transfer before the later phases, not after: trusted publishing pins `owner/repo` and silently stops matching.

### 3. Settings baseline

Invoke **apply-repo-baseline**. Check mode first, apply after showing the diff.

Two couplings matter for what follows: a repo whose release uses OIDC needs `default_workflow_permissions: write`, and `strict_required_status_checks_policy` must be `false` if a merge queue is coming.

**GitHub Projects is off by default** (`has_projects: false` in `assets/repo-settings.json`). Issues are where the work is tracked; a repo-level Projects tab nobody curates is one more stale surface. Turn it back on only when the repo actually runs a board, and say so. This toggle only governs the repo's own Projects tab — org- or user-level Projects (v2) linked to the repo are unaffected, so disabling it does not orphan an existing board.

The About panel is part of the same phase: where the repo has Pages and no deliberate homepage, point `homepage` at the Pages URL. The **Include in the home page → Packages** checkbox has no API at all, so it ends up in the report as a manual step rather than something this pass can do or verify. Both are in the baseline's § About panel.

### 4. Package manager — convert to pnpm

**pnpm is the standard, and yarn or npm is a legacy state to migrate, not a property to preserve.**
Convert whenever possible; defer only for a concrete blocker, and name it. "It currently works" is
not one. Leave **bun** alone where a repo already uses it — both its verify and its OIDC release
workflow exist, so it is a supported destination.

**This cannot be a separate PR from the release pipeline below.** Changing package manager breaks a
`yarn-*` release workflow, so `release.yml` moves in the same commit or publishing breaks — and
since the release is moving anyway, migrate it to changesets in the same pass
(**setup-secretless-release**). The two conversions are cheaper together than apart.

For a repo bound for `cyberuni` this is a precondition rather than a preference: the org carries
**no `yarn-*` workflows at all**, so there is nothing for either job to call.

pnpm's strict, non-hoisted `node_modules` stops masking whatever the repo was resolving by accident.
Everything below is a **pre-existing bug surfacing**, not a regression you introduced — say so in the
PR, or the diff reads as gratuitous churn.

Expect an undeclared dependency. **Three of the sweep's four yarn conversions had one** that had only
ever resolved through hoisting, which makes it the most reliable finding of the conversion. Hunt for
it rather than waiting for it to surface:

| symptom | cause | fix |
|---|---|---|
| `TS2307: Cannot find module 'assert'` / `'events'` | dep undeclared; yarn was hoisting it in | declare `@types/node` |
| `TS2318: Cannot find global type 'Array'` | an explicit `lib` **replaces** the default set, so `lib: ["DOM"]` alone loads no ES lib | set each config's `lib` to match its own `target` |
| `TS2339` on a method a dependency adds | module augmentation — see below | declare the members on the subclass |
| `TS1005` / `TS1109` *inside* a dependency's `.d.ts` | its syntax is newer than your TypeScript | **pin that dependency.** `skipLibCheck` skips type *checking*, not *parsing*, and does not help |
| `depcheck` says a dep is unused | bin-only in `scripts`, or referenced only by a config file | add to `.depcheckrc.yml`, one package per line |
| a devDependency missing only in CI | lost while rewriting `package.json` | **diff the old and new dependency lists explicitly** |

Those first two are usually the same accident: the hoisted `@types/node` is often where the ES lib
was quietly coming from, so fixing one exposes the other.

**A dependency that ships a module augmentation stops augmenting.** Where a package augments
*another* package from inside its own directory, pnpm resolves that specifier to its own copy — a
different module identity than the `@types/*` your repo sees — so the augmentation never merges.
Re-declaring it in `typings/` makes it worse: anchored there it becomes an *ambient* declaration
that shadows the module instead of merging into it, and a class can no longer extend it at all
(`TS2689`). Declare the members on the subclass, in the file that uses them.

Native postinstalls and the lockfile soak are covered in **modernize-toolchain**; both apply here
too. Prove the result with `pnpm install --frozen-lockfile` before opening the PR.

Skipping the `packages/<name>` layout move avoids the `.gitignore` anchoring trap entirely — `/cjs`
and `/esm` stop matching under a subdirectory, leaving build output untracked but not ignored.

### 5. Release pipeline

Invoke **setup-secretless-release**. It covers the OIDC migration, the semantic-release → changesets
migration, trusted-publisher registration, the one-time version-PR approval, and merge queue setup.

**changesets is the standard**, so a repo still on semantic-release migrates here rather than
staying. Combine it with the phase above where both apply — the release workflow has to move anyway.

Do not proceed until a release has actually published — a green run is not proof:

```bash
curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \
  | jq -r '."dist-tags".latest'
```

Audit the published tarball before migrating, not after. It takes two seconds per package and catches
defects PR CI structurally cannot see, and because the publish gate is a `needs:` of release, an
unfixed one blocks the release with everything else green. **setup-secretless-release** carries the
commands and the defect catalogue; the sweep found five packages declaring a licence they do not ship
and three shipping their own tests.

### 6. Legacy CI layout, if present

A repo still on a single `nodejs.yml` (calling `typescript-build` / `typescript-test` / `npm-release`) predates the `pull-request.yml` + `release.yml` split and will not satisfy a `code / all-checks` required context.

Decide before migrating: archive the repo, delete the workflow, or migrate. Do not sink effort into a pipeline for a package nobody consumes.

### 7. Toolchain, build, tests and dependencies

Invoke **modernize-toolchain**. It is a whole phase, not a bump pass.

**Do the toolchain swap before the version bumps.** Most of an old repo's outdated list is *deleted*
by the swap, and the deleted ones are the expensive upgrades. On `color-map`, 11 of 18 outdated
packages were removed rather than upgraded. Bumping first throws that work away.

Do not split dependencies, toolchain and build into separate missions — the split is what creates
the wasted bumps.

### 8. Dependency automation

One updater and one merge mechanism. A third-party bot's direct `merge` action bypasses a merge queue rather than feeding it, so retire those rules where a queue exists and let Renovate's `platformAutomerge` and Dependabot's `gh pr merge --auto` enqueue natively.

Majors stay manual; they break builds in ways CI catches but humans should choose to absorb.

### 9. Prove it

Claiming done without evidence is the failure mode this whole pass exists to remove.

**What decides the release depends on the tool, and the answer changed with the merge baseline.**

On **changesets** — the destination for every repo here — the *changeset file* decides, and the PR
title publishes nothing. So the failure mode is omission: a PR that changes the published package
with no changeset produces a green release run that **publishes nothing**, and `dist-tags.latest`
never moves. That is the quiet way a "finished" repo fails its own proof below.

On a repo **not yet migrated**, commit messages decide. Under the merge-commit baseline that is
worse than it used to be: every branch commit reaches `main` and gets analyzed, so a stray `feat:`
in a WIP commit cuts an unintended release. It is one more reason to migrate before proving.

Either way, pick against what the published artifact does, not how much work the PR was:

| The PR... | Bump | semantic-release type |
|---|---|---|
| adds public API | minor | `feat:` |
| changes what ships, without new API — a rebuild, different emitted output | patch | `fix:` |
| changes only repo-internal things — repo layout, test runner, CI | **no changeset** | `refactor:` / `chore:` / `ci:` |

Two toolchain PRs on `color-map` were titled `feat:` and each cut a minor while adding no API. No
semver contract broke — a minor is a safe superset of a patch — but the changelog now advertises
features that do not exist.

The proof table is the one place `npm view` does the most damage, because a stale read there is
indistinguishable from a release that did not happen. Read the registry:

| Claim | Proof |
|---|---|
| Publishes | `curl -s -H "Accept: application/vnd.npm.install-v1+json" https://registry.npmjs.org/<pkg> \| jq -r '."dist-tags".latest'` shows the new version |
| Secretless | `gh secret list` shows no `NPM_TOKEN` / `CI_GITHUB_TOKEN`, and a release has published since |
| Provenance | the same registry document carries `.versions[<v>].dist.attestations`; the key is absent on a package published without it |
| Installable | install the published tarball and exercise the public API |
| Queue serializes | two trivial PRs; the second's `gh-readonly-queue/main/pr-<N>-<sha>` base is the first's merge commit |

Delete any temporary validation artifacts in the same pass.

## What NOT to do

- Do not apply settings before diagnosing; you will fix the wrong class and mask the real one.
- Do not transfer a repo after registering trusted publishing — the config pins `owner/repo`.
- Do not fabricate a required status check to get a checkless PR through.
- Do not treat a green release run as proof of publication, and do not prove publication with `npm view`; its cache lags the registry.
- Do not read a workflow run as the current state of the workflow file. Check when the file last changed first.
- Do not repair pipelines for repos that publish nothing without saying so first.
- Do not run this across many repos at once; sweep first, then per repo.
- Do not leave a repo on yarn or semantic-release because it currently works. Both are legacy states; migrate, or name the blocker that stopped you.
- Do not convert a bun repo to pnpm as part of this pass. bun has both a verify and an OIDC release workflow, so it is a supported destination — that is a separate decision.
- Do not land a package-manager change and its release-workflow change in separate PRs. The old release workflow breaks the moment the lockfile does.

## References

- **apply-repo-baseline** — settings, rulesets, Actions token, file layout
- **modernize-toolchain** — the build/lint/test/dependency swap phase 7 delegates to
- **setup-secretless-release** — OIDC migration, trusted publishers, merge queue; its `references/failure-catalogue.md` carries the diagnostic signatures for phase 1
- **setup-changesets** — if the repo has no changesets setup yet
- **verification-before-done** — the evidence bar phase 9 applies

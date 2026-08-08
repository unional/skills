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

Record the failing job's **name and duration** before reading any log — they identify the class faster. Then decide whether the repo is worth the work at all:

```bash
gh api repos/<o>/<r>/contents/package.json --jq .content | base64 -d | jq '{name, private, workspaces}'
npm view <pkg> version
```

A private root whose workspace packages are all `private: true` publishes nothing; a red release there may not be worth fixing. Say so and stop rather than repairing a pipeline with no output.

### 2. Decide the repo's home

A user-owned repo has neither org-level secrets nor a merge queue. If the repo publishes and the owner has a suitable org, transferring removes the root cause instead of routing around it — but it is a one-way door and the target is the user's call, never the agent's.

Transfer before the later phases, not after: trusted publishing pins `owner/repo` and silently stops matching.

### 3. Settings baseline

Invoke **apply-repo-baseline**. Check mode first, apply after showing the diff.

Two couplings matter for what follows: a repo whose release uses OIDC needs `default_workflow_permissions: write`, and `strict_required_status_checks_policy` must be `false` if a merge queue is coming.

### 4. Release pipeline

Invoke **setup-secretless-release**. It covers the OIDC migration, trusted-publisher registration, the one-time version-PR approval, and merge queue setup.

Do not proceed until a release has actually published — a green run is not proof:

```bash
npm view <pkg> version
```

### 5. Legacy CI layout, if present

A repo still on a single `nodejs.yml` (calling `typescript-build` / `typescript-test` / `npm-release`) predates the `pull-request.yml` + `release.yml` split and will not satisfy a `code / all-checks` required context.

Decide before migrating: archive the repo, delete the workflow, or migrate. Do not sink effort into a pipeline for a package nobody consumes.

### 6. Dependency automation

One updater and one merge mechanism. A third-party bot's direct `merge` action bypasses a merge queue rather than feeding it, so retire those rules where a queue exists and let Renovate's `platformAutomerge` and Dependabot's `gh pr merge --auto` enqueue natively.

Majors stay manual; they break builds in ways CI catches but humans should choose to absorb.

### 7. Prove it

Claiming done without evidence is the failure mode this whole pass exists to remove.

| Claim | Proof |
|---|---|
| Publishes | `npm view <pkg> version` shows the new version |
| Secretless | `gh secret list` shows no `NPM_TOKEN` / `CI_GITHUB_TOKEN`, and a release has published since |
| Provenance | `npm view <pkg>@<v> dist.attestations` |
| Installable | install the published tarball and exercise the public API |
| Queue serializes | two trivial PRs; the second's `gh-readonly-queue/main/pr-<N>-<sha>` base is the first's merge commit |

Delete any temporary validation artifacts in the same pass.

## What NOT to do

- Do not apply settings before diagnosing; you will fix the wrong class and mask the real one.
- Do not transfer a repo after registering trusted publishing — the config pins `owner/repo`.
- Do not fabricate a required status check to get a checkless PR through.
- Do not treat a green release run as proof of publication.
- Do not repair pipelines for repos that publish nothing without saying so first.
- Do not run this across many repos at once; sweep first, then per repo.

## References

- **apply-repo-baseline** — settings, rulesets, Actions token, file layout
- **setup-secretless-release** — OIDC migration, trusted publishers, merge queue; its `references/failure-catalogue.md` carries the diagnostic signatures for phase 1
- **setup-changesets** — if the repo has no changesets setup yet
- **verification-before-done** — the evidence bar phase 7 applies

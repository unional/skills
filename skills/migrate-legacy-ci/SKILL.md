---
name: migrate-legacy-ci
description: "Decide what to do with one of unional's repos still on a legacy CI shape — a single `nodejs.yml` calling `typescript-build.yml`/`typescript-test.yml`/`npm-release.yml`, or inlined yarn steps — and then archive it, drop its CI, or migrate it to the `pull-request.yml` + `release.yml` split. Use before **apply-repo-baseline** touches a repo, when a ruleset would require `code / all-checks` on a pipeline that cannot produce it, when asked to 'migrate the old workflows', 'fix nodejs.yml', 'why is this PR unmergeable', or when auditing which repos are on the old pipeline."
---

# Migrate Legacy CI

A legacy pipeline produces no `code / all-checks` context. Applying **apply-repo-baseline**'s ruleset to
one makes the repo **unmergeable forever** — the required check can never report and there is nothing to
wait for. Run this skill **before** the baseline, on every repo whose CI predates the split layout.

**This skill is mostly a decision, not a file shuffle.** Most legacy repos are dormant. Migrating one is
an hour of work on a package nobody installs. Step 2 forces the archive / drop / migrate choice **before**
any file is written, and the default when the evidence is thin is to **ask the owner**, not to migrate.

## When to use

- A repo has `.github/workflows/nodejs.yml` (or hand-rolled steps) instead of `pull-request.yml` + `release.yml`
- A PR sits unmergeable on a required check that never appears
- **apply-repo-baseline** step 2 found no job `code` calling a `pnpm-verify*` reusable workflow
- Auditing an owner for repos still on the old pipeline

Not for: repos that already report `code / all-checks` — those are baseline-ready, and a token-based
release on top of a correct split is **setup-secretless-release**'s job, not this one. Not for authoring
the reusable workflows themselves; those live in `<owner>/.github`.

## Step 1 — Classify by the check context, never by the filename

The filename is a bad proxy. Two repos in the audited set have the modern split and are already fine; one
has a *misspelled* `ndoejs.yml` that runs anyway. The ground truth is what the default branch actually
reported:

```bash
R=unional/<repo>
sha=$(gh api "repos/$R/commits/main" --jq .sha)
gh api "repos/$R/commits/$sha/check-runs" --jq '.check_runs[].name' | sort -u
```

| Contexts seen | Verdict |
|---|---|
| `code / all-checks` present | **Not legacy.** Baseline-safe. Stop — you have the wrong skill. |
| `build / …`, `test / …`, `release / npm`, `docgen` | Legacy monolith. Continue. |
| Bare job names (`build`, `test`) with no `/` | Hand-rolled steps, no reusable workflow. Continue. |
| Nothing at all | CI never ran, or the workflow fails at resolution. Continue, and treat "no successful run ever" as strong dormancy evidence in step 2. |

If no run exists on `main`, read the file instead — but say in your report that the classification is from
source, not from a run.

`code / all-checks` is `<caller job id> / <callee's terminal job id>`. It appears only when a job **named
`code`** calls a reusable workflow whose last job is **named `all-checks`**. Renaming the caller job is not
enough; the callee has to supply the second half. `unional/.github`'s `pnpm-verify.yml`,
`pnpm-verify-linux.yml`, and the org equivalents all end in `all-checks`. The legacy
`typescript-build.yml` / `typescript-test*.yml` / `npm-release.yml` do not, and never will.

See `references/legacy-shapes.md` for each shape's anatomy and what it reports.

## Step 2 — Force the outcome decision before writing anything

Gather the evidence, present it, and get an explicit choice. Do not start migrating because migrating is
the interesting option.

```bash
R=unional/<repo>; PKG=<package-name>
gh repo view "$R" --json pushedAt,isArchived,description,stargazerCount
gh api "repos/$R/contents/package.json" --jq .content | base64 -d | jq '{name, private, version}'
npm view "$PKG" version                                  # published at all? how stale?
npm view "$PKG" time.modified                            # last publish date
gh run list --repo "$R" --status success --limit 1 --json updatedAt,workflowName
gh api "repos/$R/dependents" 2>/dev/null || echo "check https://github.com/$R/network/dependents"
```

Three legitimate outcomes. Pick by evidence, not by effort already spent:

| Outcome | When | Cost of getting it wrong |
|---|---|---|
| **Archive** the repo | Not on npm, or published years ago with no consumers; no successful run in months; nothing depends on it | Low — archiving is reversible |
| **Delete** the legacy workflow | Repo is alive but `private: true` / never publishes; CI adds nothing | Low — re-add later if needed |
| **Migrate** to the split layout | Package is genuinely maintained: recent publishes, real consumers, you still fix bugs in it | High — this is the expensive one |

**Decision defaults, in order:**

1. `"private": true` in `package.json`, or the package is not on npm → **delete the workflow**. There is
   no release to preserve. This needs no owner input; say what you did.
2. Published, but **no successful run since the last release** and no recent pushes → **ask**. Present the
   evidence rows above and the three options. Do not guess.
3. Published, actively maintained → **migrate** (step 5).

When in doubt the answer is **ask**, and the fallback while waiting is to leave CI alone and **exclude the
repo from the baseline run** — never to apply a ruleset it cannot satisfy.

**Hard boundary: archiving and deleting are the owner's calls.** This skill may inspect freely, and may open
PRs against a repo the owner has chosen. It must not archive, transfer, or delete a repo on its own
initiative — even when the evidence is overwhelming. Recommend, then wait.

## Step 3 — Archive

Owner-executed. When the owner confirms:

```bash
npm deprecate "$PKG" "No longer maintained; the repository is archived."   # only if published
gh repo archive "$R" --yes
```

Deprecate **before** archiving — an archived repo's README edit needs unarchiving again, and the npm
deprecation notice is what an installer actually sees. Then drop the repo from the baseline target list;
apply-repo-baseline skips archived repos, but an explicit exclusion documents the intent.

## Step 4 — Delete the legacy workflow

For a repo that stays alive but does not publish. One PR, everything in it:

```bash
git switch -c chore/remove-legacy-ci
git rm .github/workflows/nodejs.yml .github/workflows/dependabot-automerge.yml
```

Then decide what replaces it:

- **Nothing** — the repo has no tests worth gating. Apply the baseline **without** the
  `required_status_checks` rule and note the gap, exactly as apply-repo-baseline § 2 allows.
- **Verification only** — add `pull-request.yml` (`assets/pull-request.yml`) and no `release.yml`. This is
  the better default when the repo has a `verify` script: it costs one file and makes the repo
  baseline-eligible with the full ruleset.

Deleting `nodejs.yml` while leaving a ruleset requiring `code / all-checks` in place is the one ordering
that strands the repo. Land the workflow change first, confirm a run reports the context, then apply the
ruleset.

## Step 5 — Migrate to the split layout

Only for packages that earned it in step 2. The target is **apply-repo-baseline § File layout**; this step
is the delta from a `nodejs.yml` monolith.

**5a. Split one file into two.** `nodejs.yml` fires on both `push: main` and `pull_request`, gating release
behind `if: github.ref == 'refs/heads/main'`. The split replaces that conditional with two files:

| Old (`nodejs.yml`) | New |
|---|---|
| `build` → `typescript-build.yml` | folded into `code` |
| `test` → `typescript-test-linux.yml`, `needs: build` | `code` → `pnpm-verify-linux.yml` (job id **must** be `code`) |
| `release` → `npm-release.yml` + `secrets: npm-token` | `release.yml`'s `release` job → `pnpm-release-changeset-oidc.yml`, `needs: code` |
| `docgen` → `build-docs.yml` | `pnpm-docs.yml` in `release.yml`, if the repo publishes docs at all |

Copy `assets/pull-request.yml` and `assets/release.yml`, then `git rm .github/workflows/nodejs.yml`.
Pick the reusable workflow by owner convention: `pnpm-verify-linux.yml` under `unional`,
`pnpm-verify.yml` under the orgs. Confirm the file exists before pointing at it:

```bash
gh api "repos/<owner>/.github/contents/.github/workflows" --jq '.[].name'
```

**5b. Prefer OIDC — migration must not introduce a token.** The legacy `npm-release.yml` takes
`secrets: npm-token`. Do not carry that forward. `pnpm-release-changeset-oidc.yml` with an explicit job
`permissions:` block needs no secret, and it keeps the repo eligible for
`default_workflow_permissions: read` (apply-repo-baseline § 5). Register the trusted publisher **before**
the first release run, naming the **caller** file:

```bash
npm trust github "$PKG" --file release.yml --repo "$R" --allow-publish -y --otp=<code>
```

Full procedure, prerequisites, and failure classes: **setup-secretless-release**. If the package cannot
move to OIDC yet, migrate the *verification* half only and leave the old release path alone — a repo with
a correct `pull-request.yml` is already baseline-safe.

**5c. The package must actually have what the reusable workflow runs.** `pnpm-verify*` runs `pnpm install`
then `pnpm verify` and nothing else. A repo on yarn with no `verify` script goes red on the first run:

```bash
gh api "repos/$R/contents/package.json" --jq .content | base64 -d | jq '.scripts.verify, .packageManager'
```

Missing → add `"verify": "run-p lint verify:pkg"` and a lockfile migration in the **same** PR. Splitting
the workflow before the package can satisfy it just moves the red from one file to another.

**5d. Land, then verify the context appears.** Merge the CI PR, then re-run step 1's check-runs command and
confirm `code / all-checks` is in the list. Only then hand the repo to apply-repo-baseline.

## Step 6 — Record the outcome

Every repo in the audit ends with one written line: `archived` / `workflow deleted` / `migrated, verified`
/ `deferred — owner decision pending`. A repo with no recorded outcome is the failure mode this skill
exists to prevent, because it is the one that later silently gets a ruleset it cannot satisfy.

Report the exclusion list explicitly to whoever runs apply-repo-baseline next.

## What NOT to do

- **Do not apply the baseline ruleset to a repo that does not report `code / all-checks`.** That is the
  whole reason this skill runs first.
- Do not classify by filename. Read the check contexts (step 1) — `ndoejs.yml` runs, and a correct-looking
  `pull-request.yml` pointed at a callee without an `all-checks` job still reports nothing usable.
- Do not migrate a dormant package because migrating is the more satisfying option. Step 2 first.
- Do not archive, transfer, or delete a repo without the owner saying so. Inspect freely; act narrowly.
- Do not carry `secrets: npm-token` into the new `release.yml`. Migration is the moment the token leaves.
- Do not delete `nodejs.yml` before its replacement reports green, or in the same breath as applying a
  ruleset — that ordering strands the repo with a required check and no producer.
- Do not point at a reusable workflow without confirming it exists in `<owner>/.github`. A missing callee
  fails the run in ~0s with no jobs and no logs.
- Do not leave a repo classified but undecided. Step 6 or it did not happen.

## References

- `references/legacy-shapes.md` — the shapes found in the wild, what each reports, and the per-repo audit
- `assets/pull-request.yml`, `assets/release.yml` — the target files
- **apply-repo-baseline** § File layout (target shape), § 2 (the required-context guard), § 5 (Actions token)
- **setup-secretless-release** — the OIDC half of step 5

# Legacy CI shapes

Field notes behind `migrate-legacy-ci`. Audited **2026-08-08** against `unional/*`. Anatomy first, then
the per-repo table.

## Why the context is the only reliable classifier

`code / all-checks` is `<caller job id> / <callee's terminal job id>`. Both halves must line up:

- The caller's job must be named **`code`**.
- The callee must end in a job named **`all-checks`** that fails when `verify` did not succeed.

`unional/.github`'s `pnpm-verify.yml` and `pnpm-verify-linux.yml` both end in `all-checks` (verified
2026-08-08), as does `justland/.github`'s `yarn2-library-verify-linux.yml`. The legacy callees —
`typescript-build.yml`, `typescript-test-linux.yml`, `npm-release.yml` — do not. Renaming the caller job to
`code` on a legacy callee produces `code / typescript`, which is still not the required context.

That is why the skill classifies from `check-runs` on the default branch head rather than from the file.

## Shape A — the `nodejs.yml` monolith

One workflow on both `push: main` and `pull_request`, release gated by a ref conditional.

```yaml
name: nodejs
on:
  push: { branches: [main] }
  pull_request: { types: [opened, synchronize] }
jobs:
  build:
    uses: unional/.github/.github/workflows/typescript-build.yml@main
  test:
    uses: unional/.github/.github/workflows/typescript-test-linux.yml@main
    needs: build
  release:
    if: github.ref == 'refs/heads/main'
    uses: unional/.github/.github/workflows/npm-release.yml@main
    needs: test
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
  docgen:
    if: github.ref == 'refs/heads/main'
    uses: unional/.github/.github/workflows/build-docs.yml@main
    needs: release
```

Reports, on `color-map-rainbow@main`:

```
build / typescript
test / typescript (ubuntu-latest, 12)
test / typescript (ubuntu-latest, 14)
test / typescript (ubuntu-latest, 16)
release / npm
docgen
```

Three separate problems, not one:

1. **No `code / all-checks`.** The baseline ruleset can never be satisfied.
2. **`secrets: npm-token`.** A long-lived `NPM_TOKEN` that expires silently — the thing
   **setup-secretless-release** exists to remove. Migration must not carry it forward.
3. **Node 12/14/16 matrix.** Pinned inside the legacy callee. Even a passing run is verifying against
   runtimes nothing supports; a green check here is not evidence the package works.

## Shape B — hand-rolled steps, no reusable workflow

`jest-progress-tracker` (in a file spelled `ndoejs.yml` — the typo does not stop it running, but it does
make `gh run list --workflow=nodejs.yml` return nothing, which reads as "no CI" when there is CI):

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - run: echo "::set-output name=dir::$(yarn cache dir)"
      - uses: actions/cache@v1
      - run: yarn && yarn lint && yarn build && yarn dependency-check
      - uses: actions/upload-artifact@v1
```

`actions/checkout@v1`, `actions/cache@v1`, `actions/upload-artifact@v1`, and `::set-output` are all
retired. This shape does not fail cleanly — it fails at the action level with deprecation errors. Repos on
shape B have typically **never had a successful run**, which is itself the dormancy signal step 2 wants.

Migrating shape B is strictly more work than shape A: there is no reusable workflow to swap, the package is
on yarn, and it usually has no `verify` script. Weigh that before choosing migrate.

## Shape C — right split, wrong details

The trap. `iso-path` looks legacy from a distance but reports the required context:

```
code / all-checks
code / verify (ubuntu-latest, lts/*)
code / verify (ubuntu-latest, lts/-1)
```

Its `pull-request.yml` calls `justland/.github/.github/workflows/yarn2-library-verify-linux.yml@main` — a
different owner's `.github` repo than the repo lives under, but the callee does end in `all-checks`, so the
context resolves. **It is baseline-safe.** What it actually has is a `secrets: inherit` token release
(`yarn2-library-release.yml`), which is **setup-secretless-release**'s problem and apply-repo-baseline § 5's
Actions-token branch — not this skill's.

`unional.github.io` is the same story: `pull-request.yaml` (`.yaml`, which GitHub does not care about)
with job `code` → `unional/.github`'s `pnpm-verify.yml`, and a `release.yml` that publishes docs rather than
a package. Baseline-safe. Its only real defects are two dependency-automation workflows racing
(`automerge-dependabot.yml` **and** `dependabot-automerge.yml`), which is apply-repo-baseline § 6.

**Lesson:** the audit list from the issue was assembled by filename. Two of the ten were false positives.
Re-classify from the check contexts before doing anything.

## Per-repo audit — 2026-08-08

| Repo | Shape | npm | Last successful run | `private` | Suggested outcome |
|---|---|---|---|---|---|
| `color-map-rainbow` | A | `2.1.4` | 2026-07-30 (`nodejs`) | no | **Ask** — published and running, but nothing recent depends on it |
| `jest-audio-reporter` | A | `2.2.3` | 2026-07-30 (`nodejs`) | no | **Ask** — same profile |
| `test-progress-tracker` | A (no `release.yml`) | `2.0.6` | 2026-07-30 (`typescript`) | no | **Ask** — publishes, but has no release workflow to migrate |
| `create` | A | not published | 2026-01-26 | **yes** | **Delete workflow** — `private: true`, nothing to release |
| `sort-configs` | A | `0.0.1` (root is private) | never | **yes** | **Delete workflow** — root `private: true` |
| `eslintest` | A | not published | never | no | **Archive** — never published, never ran green |
| `prettier-plugin-tidy-json` | A | not published | never | no | **Archive** — never published, never ran green |
| `jest-progress-tracker` | B (`ndoejs.yml`) | `3.0.4` | never | no | **Archive or ask** — published once, CI never worked |
| `iso-path` | **C — not legacy** | `0.1.2` | — | no | Baseline-safe. Route to **setup-secretless-release** for its `secrets: inherit` release |
| `unional.github.io` | **C — not legacy** | n/a (site) | — | n/a | Baseline-safe. Duplicate automerge workflows → apply-repo-baseline § 6 |

Four of eight legacy repos have **never** had a successful run. That is the number that should settle the
default: the expected outcome for this set is archive-or-delete, and migration is the exception.

These are recommendations from evidence, not decisions. `archive` and `delete` rows still need the owner's
word before anything is executed — see the skill's step 2 boundary.

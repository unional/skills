# Release failure catalogue

Classes observed while sweeping 106 source repos under one personal namespace, 21 of which were not publishing. Each entry gives the signature, how to confirm it, and the fix.

Read the failing job's **name and duration** before the log — they identify the class faster.

## Broken reusable workflow reference

**Signature** — run fails in ~0s with no jobs and no logs.

**Confirm** — list what actually exists:

```bash
gh api repos/<owner>/.github/contents/.github/workflows --jq '.[].name'
grep -rn 'uses:.*\.github/\.github/workflows/' .github/workflows/
```

A singular/plural mismatch (`pnpm-release-changesets.yml` vs `pnpm-release-changeset.yml`) is invisible in review and fails identically every time. Worth sweeping an owner's repos for, since templated repos inherit it.

**Fix** — correct the filename.

## Callee requests more permission than the caller holds

**Signature** — `startup_failure`, **zero jobs**, no logs, no annotation. The UI says only "This run likely failed because of a workflow file issue", which misdirects toward YAML syntax.

**Confirm** — compare against a repo whose release works:

```bash
gh api repos/<o>/<r>/actions/permissions/workflow --jq .default_workflow_permissions
```

A reusable workflow declaring `permissions: id-token: write` cannot run from a caller whose default token is `read`, and GitHub rejects it at resolution time — before any job exists, which is why no log survives.

Discriminator: another workflow in the same repo calling a reusable workflow that declares **no** `permissions:` will start normally. If that one runs and the release one does not, it is permissions, not syntax.

**Fix** — `gh api -X PUT repos/<o>/<r>/actions/permissions/workflow -f default_workflow_permissions=write`.

## Missing PAT

**Signature** — `##[error]Input required and not supplied: token`, release job dies in a few seconds.

**Confirm** — `gh secret list --repo <o>/<r>` and grep the reusable workflow for `secrets.CI_GITHUB_TOKEN`.

**Fix** — migrate to the secretless workflow. Adding another PAT reinstates the expiry treadmill; on a personal namespace it must be added per repo.

## Expired npm token

**Signature** — `npm error code E401` / `401 Unauthorized - GET https://registry.npmjs.org/-/whoami`.

This is the publisher plugin's own auth pre-check — precisely the step trusted publishing removes. Failures here are silent in practice: nobody notices a release that stopped months ago.

**Fix** — trusted publishing. Rotating the token works but recurs.

## Missing release tooling

**Signature** — `sh: 1: changeset: not found`, then `Publish command exited with code 1`.

**Confirm** — the root `package.json` defines `release`/`version` scripts but does not depend on the CLI:

```bash
gh api repos/<o>/<r>/contents/package.json --jq .content | base64 -d \
  | jq '.devDependencies["@changesets/cli"], .dependencies["@changesets/cli"]'
```

**Fix** — add the missing devDependency.

## Publish-time build failure

**Signature** — `Publish command exited with code 1`, preceded by the build the publish step invokes, and `packages failed to publish: <pkg>@<version>`.

Not a CI or auth problem. Reproduce locally with the package's own build script.

## Verify gate failing

**Signature** — the release job never runs; a `verify` matrix job or the aggregate check fails first.

Fix the verify failure before assuming anything about publishing. Note this **masks** downstream faults: a repo can be missing its PAT and never show it because verify fails earlier.

## Sweeping an owner's repos

```bash
gh repo list <owner> --source --no-archived --limit 400 --json nameWithOwner --jq '.[].nameWithOwner'
gh run list --repo <o>/<r> --workflow=release.yml --limit 1 --json conclusion,createdAt
```

**Coverage caveat learned the hard way:** filtering a combined recent-runs list (`gh run list --limit 40`) silently misses repos whose last release attempt predates that window. Repos broken longest — the ones that matter most — are exactly the ones that drop out. Query each repo's `release.yml` runs directly, and treat any count derived from a run window as a floor.

Also exclude repos that publish nothing before counting them as broken:

```bash
gh api repos/<o>/<r>/contents/package.json --jq .content | base64 -d | jq '{name, private}'
```

A private root with private workspace packages means the pipeline has nothing to publish, and a red release there may not be worth fixing.

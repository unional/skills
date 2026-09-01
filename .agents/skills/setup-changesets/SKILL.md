---
name: setup-changesets
description: "Set up changesets in a new or existing repository, or upgrade an existing setup across a major. Use when asked to 'add changesets', 'set up releases', or 'configure versioning'; when a release job fails with a Changesets CLI/action version mismatch; or when asked to upgrade changesets from v2 to v3. Handles single packages and monorepos. Optionally sets up a shared reusable workflow in a <user/org>/.github repo."
metadata:
  internal: true
---

# Setup Changesets

Changesets automates versioning and changelog generation. Contributors add changeset files describing their changes; CI consumes them to bump versions, update changelogs, and publish packages.

## Step 1 — Gather context

Before doing anything, detect or ask:

**Detect automatically:**

| Check | How |
|---|---|
| Package manager | Look for `pnpm-lock.yaml`, `bun.lock`/`bun.lockb`, `yarn.lock`, `package-lock.json` |
| Monorepo | `pnpm-workspace.yaml`, `workspaces` field in root `package.json`, or `bun.workspace.ts` |
| Already initialized | `.changeset/` directory exists |
| CLI major in use | the `@changesets/cli` range in the root `package.json` |
| Action major in use | `grep -rn 'changesets/action@' .github/workflows/`, following any `uses:` into the shared workflow |

If `.changeset/` already exists this is not a fresh setup. Read the CLI major against the action major before touching anything: a mismatch there is the failure, whatever else is green. Go to [Upgrading an existing setup](#upgrading) rather than re-running init.

**Ask the user:**

1. "Do you want to also create a reusable workflow in a `<org-or-user>/.github` repo, so other repos can share the same release pipeline?"
   - Yes → follow [Shared workflow setup](#shared-workflow-setup) after completing local setup
   - No → inline the workflow in `.github/workflows/release.yml`

2. If monorepo: "Are any packages versioned together (always share the same version)?" → `fixed` groups
3. "Are any packages private/internal and should be excluded from publishing?" → `ignore` list

## Step 2 — Initialize

```bash
# pnpm
pnpm dlx @changesets/cli@3 init

# bun
bunx @changesets/cli@3 init

# npm / yarn
npx @changesets/cli@3 init
```

This creates `.changeset/config.json` and `.changeset/README.md`.

### The CLI and the action are a matched pair <a name="version-pairing"></a>

`changesets/action@v2` requires `@changesets/cli` v3, and `action@v1` is the pair for cli v2. The
action refuses to run against the wrong major, so the release dies before the CLI is ever invoked:

```
Error: This version of the Changesets action is designed to work with Changesets CLI v3.
Changesets CLI v2 is not supported; use Changesets action v1 instead, which is compatible with CLI v2.
```

| `@changesets/cli` | `changesets/action` | Input names |
|---|---|---|
| v2 | `@v1` | `version:`, `publish:`, `commit:`, and a `GITHUB_TOKEN` env var |
| v3 | `@v2` | `version-script:`, `publish-script:`, `commit-message:`, and a `github-token:` input |

The renamed inputs are ignored rather than rejected under the wrong major, so a half-done bump
leaves the action running with no publish script at all. Move both sides in one commit.

Set new repos up on cli v3 with `action@v2`.

## Step 3 — Configure `.changeset/config.json`

Replace the generated config with appropriate settings:

**Single package:**
```json
{
  "$schema": "https://unpkg.com/@changesets/config@4.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "access": "public",
  "baseBranch": "main"
}
```

**Monorepo with grouped packages:**
```json
{
  "$schema": "https://unpkg.com/@changesets/config@4.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "access": "public",
  "baseBranch": "main",
  "fixed": [["package-a", "package-b"]],
  "linked": [],
  "ignore": ["internal-tools"],
  "updateInternalDependencies": "patch"
}
```

Key decisions:
- `"access": "public"` — required for publishing scoped packages (`@scope/name`) publicly; private packages ignore this
- `"fixed"` — packages that must always share the exact same version number
- `"linked"` — packages that share the highest bump type but keep independent version numbers
- `"ignore"` — packages excluded from changeset versioning entirely (e.g. `examples`, internal CLIs)
- `"commit": false` — recommended; `changeset version` won't auto-commit, giving you control
- `"privatePackages"` — see [Private packages](#private-packages). Set `{ "version": true, "tag": false }` on any workspace that contains a private package, including one whose packages are all private
- `"format"` — leave it unset unless the detected formatter is wrong. See [Formatting](#formatting)

Two keys people expect and neither schema has ever defined: `"title"` and `"prettier"`. A `"title"`
key in `.changeset/config.json` has never existed in any version, confirmed against
`@changesets/config@2.1.1` and `@4.0.0`. It is the `changesets/action` input `pr-title:`, which
belongs in the workflow. `"prettier"` existed under config v3 and is now `"format"`.

### Private packages <a name="private-packages"></a>

`@changesets/config@4` flipped the `privatePackages` default from `{ "version": true, "tag": false }`
to `{ "version": false, "tag": false }`. Private packages are now skipped unless you opt back in, and
both failure modes are invisible to PR CI, because a pull-request check never runs `changeset
version`. They surface on `main`, at release time.

| Workspace shape | What happens on the default | Fix |
|---|---|---|
| A publishable package depends on a private one | hard fail: `Invalid tree: "pyrenees" depends on the skipped package "design", but "pyrenees" is not skipped.` | opt the private package back into versioning, or add the dependent to `ignore` |
| Every package is private | `changeset version` processes nothing and exits 0. It **fails green** | `"privatePackages": { "version": true, "tag": false }` |

Only that direction fails. A private package depending on a publishable one is fine.

The green failure is the dangerous one, because a repo that publishes nothing still needs its
versions and changelogs to move. Do not read a clean release run as proof the config is right.

### Formatting <a name="formatting"></a>

`format` replaced the `prettier` option. It takes `"auto"` (the default), `"prettier"`, `"oxfmt"`,
`"deno"`, `"dprint"`, or `false`. Under `"auto"` the detector walks up from the working directory
looking for each formatter's config file, then falls back to probing `node_modules`, in this fixed
order:

```js
const defaultDetectOrder = Object.freeze(["dprint", "deno", "oxfmt", "biome", "prettier"]);
```

Biome is detectable but is not a legal value of `format`, so a biome repo relies on `"auto"`.
Prettier is last, which is what makes the common failure counter-intuitive: **the error is that the
detector resolved a formatter the repo has not installed**, not that a config file exists. A
`biome.json` beats a `.prettierrc`, so a dead prettier config sitting beside one is harmless, and a
biome repo missing `@biomejs/biome` fails in exactly the same way. Fix it by installing what the
detector found, or by naming the formatter explicitly. Set `false` where the repo formats nothing.

## Step 4 — Add scripts to `package.json`

```json
{
  "scripts": {
    "version": "changeset version",
    "release": "changeset publish",
    "cs": "changeset"
  }
}
```

`cs` is a shorthand for adding changesets during development. `version` and `release` are called by CI.

**Call the version script as `<pm> run version`, never `pnpm version`.** pnpm has a builtin `version`
command and intercepts the bare form, so `pnpm version` does an npm-style bump and the script never
runs. Testing with the wrong form locally proves nothing about what CI will do.

If the project has a build step that must run before publishing, update `release`:
```json
"release": "pnpm build && changeset publish"
```

## Step 5 — Set up the CI release workflow

### Option A — Inline workflow (simpler, self-contained)

Create `.github/workflows/release.yml`:

```yaml
name: release
on:
  push:
    branches: [main]

concurrency: ${{ github.workflow }}-${{ github.ref }}

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # Insert package manager setup here (see below)

      - run: <install-command>
      - run: <build-command>        # remove if no build step

      - name: Create Release PR or Publish
        uses: changesets/action@v2
        with:
          version-script: <pm> run version
          publish-script: <pm> run release
          github-token: ${{ secrets.GITHUB_TOKEN }}
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Replace `<pm>` with `pnpm`, `bun`, `npm`, or `yarn`. Replace `<install-command>` with `pnpm install --frozen-lockfile`, `bun install`, etc.

**Package manager setup snippets:**

pnpm:
```yaml
- uses: pnpm/action-setup@v4
- uses: actions/setup-node@v4
  with:
    node-version: 22
    cache: pnpm
```

bun:
```yaml
- uses: oven-sh/setup-bun@v2
- uses: actions/setup-node@v4
  with:
    node-version: 22
```

npm/yarn:
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: 22
    cache: npm   # or: yarn
```

**Token note:** `GITHUB_TOKEN` is sufficient for most setups. If your repo has branch protection rules that require CI status checks on the "Version Packages" PR, you'll need a PAT with `repo` scope stored as a secret (e.g. `RELEASE_TOKEN`) and passed as the action's `github-token: ${{ secrets.RELEASE_TOKEN }}` input — this lets the action's commits trigger CI.

### Option B — Shared workflow <a name="shared-workflow-setup"></a>

Use this when you want all your repos to share one release pipeline definition. Changes to the shared workflow apply to all repos at once.

**In the `<user-or-org>/.github` repo**, create `.github/workflows/release-changeset.yml`:

```yaml
name: release-changeset
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '22'
    outputs:
      published:
        description: 'Whether packages were published'
        value: ${{ jobs.release.outputs.published }}

concurrency: ${{ github.workflow }}-${{ github.ref }}

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  release:
    runs-on: ubuntu-latest
    outputs:
      published: ${{ steps.changesets.outputs.published }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      # Add your standard setup steps here (package manager, node, install, build)
      - name: Create Release PR or Publish
        id: changesets
        uses: changesets/action@v2
        with:
          version-script: <pm> run version
          publish-script: <pm> run release
          github-token: ${{ secrets.GITHUB_TOKEN }}
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**A shared workflow makes the action major a fleet-wide decision.** Bumping `changesets/action` here
breaks the release job in every consuming repo still on cli v2, and the failure surfaces in those
repos rather than this one. Upgrade each consumer's CLI in the same pass, or the next push to their
`main` goes red.

**In each consuming repo**, create `.github/workflows/release.yml`:

```yaml
name: release
on:
  push:
    branches: [main]

jobs:
  release:
    uses: <user-or-org>/.github/.github/workflows/release-changeset.yml@main
    secrets: inherit
```

## Step 6 — Add secrets to the repository

Go to **Settings → Secrets and variables → Actions** and add:

- `NPM_TOKEN` — an npm automation token (create at npmjs.com → Access Tokens → Generate New Token → Automation)
- `RELEASE_TOKEN` — optional PAT, only needed if branch protection requires CI on the "Version Packages" PR

## Step 7 — Verify

```bash
# Add a test changeset
npx changeset add --empty

# Check it was created
ls .changeset/

# Check the release workflow is valid (if using GitHub CLI)
gh workflow list
```

A green PR check is not verification. `code / all-checks` never runs `changeset version`, so nothing
in PR CI exercises the config: the private-package failures above, a formatter that is not
installed, and a version script pnpm intercepted all pass the pull request and fail on `main`. Run
the real command locally and throw the result away:

```bash
<pm> exec changeset status     # parses every pending changeset and prints the bumps
<pm> run version               # the full version, changelog, and any wrapper scripts
git diff                       # confirm the versions, changelog and derived files moved
```

Then revert. Do it one path per command and re-read the version field afterwards: `git checkout --
<a> <b>` is atomic, so one bad pathspec aborts the whole command and silently leaves the bumped
version in place.

## What the automated flow looks like

Once set up, the full cycle is:

1. Developer adds a changeset file to their PR (see `add-changeset` skill)
2. PR merges to main
3. CI runs `changesets/action` — detects new changesets, opens/updates a **"Version Packages"** PR
4. When ready to release, merge the "Version Packages" PR
5. CI runs again — no pending changesets, so it runs `release` and publishes to npm

The "Version Packages" PR is fully managed by the action. Do not manually edit `CHANGELOG.md` or the version numbers it touches.

## Upgrading an existing setup <a name="upgrading"></a>

Trigger: a red `release` job carrying the mismatch error from
[the matched pair](#version-pairing), or any repo still pinning `@changesets/cli` to `^2`.

Go forward rather than pinning the action back to `@v1`. Pinning back is a fallback for a repo that
genuinely cannot meet v3's Node or package-manager floors, and it leaves the repo on a cli major
that npm 12 breaks. `setup-secretless-release` carries that hazard and the workflow-pinning
decision; this section covers only the changesets side.

**1. Check the floors.** These are the only things that can block the upgrade, and they are declared
in the CLI's own `engines`:

| Requirement | v3 floor |
|---|---|
| Node | `^22.11 \|\| ^24 \|\| >=26` |
| npm | `>=10.9.0` |
| pnpm | `>=10.0.0` |
| yarn | `>=4.5.2`, and Yarn Classic is gone entirely |

`"engines": { "node": ">=22" }` nominally allows 22.0, below the 22.11 floor. Check what CI pins
before widening the range.

**2. Bump the CLI, the action, and the schema URL together.** `@changesets/cli` to `^3`,
`changesets/action` to `@v2` with the renamed inputs, and the `$schema` to
`https://unpkg.com/@changesets/config@4.0.0/schema.json`. If the workflow is shared from a
`<org>/.github` repo it may already be on `@v2`, which is usually what turned the repo red, and only
the CLI side needs the fix.

**3. Walk the config against what the repo actually uses.** Every common key survives config v4
unchanged: `changelog`, `commit`, `fixed`, `linked`, `access`, `baseBranch`,
`updateInternalDependencies`, `ignore`. What moved:

| v1-era or v3 config | v4 |
|---|---|
| `prettier` | `format`, with a different detection model. See [Formatting](#formatting) |
| `privatePackages` defaulted to versioning private packages | defaults to skipping them. See [Private packages](#private-packages) |
| `___experimentalUnsafeOptions_WILL_CHANGE_IN_PATCH.useCalculatedVersionForSnapshots` | `snapshot.useCalculatedVersion` |
| `changeset status --sinceMaster` | `--since=main` |
| Yarn Classic | unsupported; the yarn floor is 4.5.2 |

**A clean run does not prove the config is right.** v4 ignores v1-era keys silently instead of
rejecting them, so an obsolete key produces no error and no effect. Read the config against the
schema key list yourself.

**4. Expect the prerelease bookkeeping to move.** Prerelease state now lives in `.changeset/pre/`,
and `pre.json` reduces to `{"mode","tag"}` with `initialVersions` removed. The migration runs on
`changeset version` **or on `changeset status`**, so a command that reads as read-only rewrites the
repository. The first Version PR after the upgrade shows `pre.json` gutted and dozens of files
appearing under a new directory. That is the migration, not damage. Exit the prerelease before
upgrading if you can.

**5. Grep for anything else that calls the CLI.** Scripts wrapping `changeset version`, or reading
the versions it decides, run inside the same `version` script and break quietly.

**6. Prove it with the local dry run in [Step 7](#step-7--verify).** Commit the CLI bump, the action
bump, the schema URL and the lockfile. A devDependency-only change needs no changeset of its own.

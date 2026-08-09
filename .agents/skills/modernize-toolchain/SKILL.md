---
name: modernize-toolchain
description: "Replace a TypeScript library's build, lint, test and dependency stack in one pass — tsdown for the build, biome for lint, turbo for tasks, vitest for tests — instead of upgrading tools that the swap deletes. Use when asked to 'modernize the toolchain', 'bring the deps current', 'replace webpack/eslint/jest', 'upgrade to TypeScript 7', or when a repo's dependency list is long and mostly obsolete."
metadata:
  internal: true
---

# Modernize Toolchain

The build/lint/test half of **modernize-repo** (its phase 7). Everything here is internal to the repo — a separate concern from the release pipeline, settings and automation, which the other skills own.

## When to use

- A repo is on webpack / eslint 8 / jest / raw `tsc` and should match the current stack
- A dependency report lists many outdated packages and you are about to start bumping them
- A `modernize-repo` pass has reached the toolchain phase

Not for: changing what the package *exports* (that is an API change, and a release decision), or the release workflow itself.

## The ordering rule that saves the most work

**Swap the toolchain first, then bump what survives.** Never the reverse.

Most of an old repo's outdated list is deleted by the swap, and the deleted ones are the expensive upgrades — `eslint` 8→10 with its plugin ecosystem, `webpack-cli` 5→7, `@typescript-eslint` 5→8. Bumping those first is work thrown away.

On the worked example, **11 of 18 outdated packages were removed rather than upgraded.** Budget the phase on that ratio, not on the length of the outdated list.

Do dependencies, toolchain and build as **one mission**. Splitting them is what creates the wasted bumps.

## Target stack

| Concern | Use | Replaces |
|---|---|---|
| Build | **tsdown** (rolldown) | webpack, `tsc` build passes, esbuild scripts, `ncp` |
| Lint + format | **biome** via `@repobuddy/biome` | eslint, its plugins, prettier |
| Task running | **turbo** | `pnpm -r`, `npm-run-all` chains at root |
| Tests | **vitest** | jest, ts-jest, jest-watch-\* plugins |
| Hooks | husky 9 + commitlint 21 | husky 8 (`prepare` changes from `husky install` to `husky`) |

`npm-run-all` → `npm-run-all2` (the maintained fork). Reference implementation for layout: `cyberuni/search-packages`.

## Traps

Each of these cost real time. They are not hypothetical.

### tsdown does not typecheck

The `tsc -p` passes it replaces were typechecking as a side effect. Removing them silently removes that. Add an explicit script and put it in `verify`:

```jsonc
"typecheck": "tsc",          // with "noEmit": true in tsconfig
"verify": "npm-run-all -p build depcheck typecheck coverage"
```

**Prove it works** by appending a deliberate type error and confirming a non-zero exit. A `typecheck` script that passes because it checks nothing is worse than none.

### Check the published tarball before deleting any build output

`files` may publish an artifact no one documented. On the worked example a webpack UMD bundle was shipping in every release; the handoff notes said to delete it.

```bash
npm view <pkg> version
npm pack <pkg>@latest && tar tzf <pkg>-*.tgz | sort
```

If a build output is published, either keep emitting it or treat its removal as **breaking**. tsdown emits an IIFE, so usually keep it:

```ts
{ entry: { '<name>': 'ts/index.ts' }, format: 'iife', globalName: 'PascalName',
  outDir: 'dist', outputOptions: { entryFileNames: '[name].es5.js' } }
```

Preserving every published path means the swap needs no major version at all.

### tsdown config specifics

- Multiple outputs = an **array** of configs, one per format, each with its own `outDir`.
- `outExtensions: () => ({ js: '.js', dts: '.d.ts' })` — without it you get `.mjs` / `.d.mts`, which moves published paths.
- IIFE gets a **format infix** (`name.iife.es5.js`). Override with `outputOptions.entryFileNames`.
- `copy`'s `to` is treated as a **directory**, so it cannot write `cjs/package.json`. Use a `build:done` hook that writes the file.
- `unbundle: true` on the ESM build keeps the per-module shape `tsc` used to emit.
- A `"type": "module"` package needs `cjs/package.json` = `{"type":"commonjs"}` or the CJS output is parsed as ESM.

### TypeScript 7 stops auto-including `@types/*`

Specs lose `test` / `expect`; configs lose node builtins. Name them explicitly — this is more precise anyway:

```jsonc
"types": ["node", "vitest/globals"]
```

### Blanket depcheck ignores hide dead dependencies

A `jest-*` wildcard in `.depcheckrc.yaml` concealed four packages nothing referenced. **List ignores one package at a time.** Before upgrading any tool-adjacent dep, grep for it — if the only hit is its own `package.json` entry, delete it instead.

### Skip the swap entirely when the package IS a jest plugin

`jest-audio-reporter`, `jest-progress-tracker`, `jest-watch-repeat` and anything else whose
*product* extends jest keep jest. It is their integration target, not a stale test-runner choice —
swapping it would mean the package no longer runs against the thing it exists to extend.

Every other step still applies to those repos: tsdown, biome, turbo, TypeScript 7, husky 9,
commitlint 21, the dependency cull, and the whole release and settings baseline. Only the test
runner is out of scope.

Ask what the package *is* before applying this section. The same caution covers any repo that
exists to extend a tool this skill would otherwise replace — an eslint plugin keeps eslint, a
webpack loader keeps webpack.

### jest → vitest is usually near-free

Check the spec surface first:

```bash
grep -hoE "\b(test|it|expect|describe)\(" ts/*.spec.ts | sort | uniq -c
grep -nE "jest\.|mock|Snapshot|spyOn|useFakeTimers" ts/*.spec.ts
```

No mocks, spies, snapshots or timers means `globals: true` covers it and **the spec files do not change**. Seven packages typically collapse to `vitest` + `@vitest/coverage-v8`.

Take the opportunity to *enforce* coverage rather than only report it — set `thresholds` to the level the repo already meets, and verify by introducing an uncovered branch. Note that vitest's `text` reporter lists only files with gaps, so an empty table means full coverage, not a broken report.

### pnpm blocks native postinstalls

New tools drag in native binaries (`unrs-resolver` with jest 30, `esbuild`, `@swc/core`). They fail at build time, not install time. Add them to `allowBuilds` in `pnpm-workspace.yaml` — and **remove them again** when the tool that pulled them leaves.

### Check the git hooks actually run

Two independent faults are common and silent: the hook still invokes the **old package manager** after a pnpm/yarn migration, and it is committed **without the executable bit**, so git skips it entirely.

```bash
git ls-files -s .husky/commit-msg   # want 100755, not 100644
echo "bad message" | pnpm exec commitlint   # must fail
```

## Commit shape

One PR, one commit per swap, so each is reviewable and revertible:

1. `build:` tsdown replaces the old build
2. `build:` biome replaces eslint (the reformat lands here — say so in the message)
3. `build:` turbo + hooks toolchain
4. `chore(deps):` the test-runner group
5. `chore(deps):` TypeScript, on its own commit

**A toolchain swap needs no changeset** — it changes nothing the published package exposes. Add one only if the emitted output actually changes. On a repo not yet migrated to changesets the commit messages decide instead, so pick the type deliberately rather than defaulting to `feat:`. See modernize-repo's phase 9 note.

## Proof

A green CI run is not evidence. Before opening the PR:

| Claim | Proof |
|---|---|
| Build outputs work | Import the ESM, `require` the CJS, and evaluate the IIFE in a `vm` context checking the global's keys |
| Nothing left the package | `pnpm pack`, list the tarball, diff against the published one |
| Types still resolve | `tsc --noEmit --module nodenext --strict` against the installed tarball |
| Install is reproducible | Delete `node_modules`, `pnpm install --frozen-lockfile`, `turbo run ... --force` |
| Coverage gate is real | Introduce an uncovered branch; confirm non-zero exit |

`--force` matters: turbo will happily report success from cache and tell you nothing.

## What NOT to do

- Do not bump dependencies before swapping the toolchain.
- Do not delete a build output before checking whether it ships in the tarball.
- Do not assume the bundler typechecks.
- Do not keep wildcard depcheck ignores; they hide dead weight.
- Do not commit a lockfile built with the `minimumreleaseage` soak bypassed — pnpm rejects it on the next run.
- Do not trust a cached turbo run as verification.

## References

- **modernize-repo** — the full pass this is one phase of
- **verification-before-done** — the evidence bar applied above
- `cyberuni/search-packages` — layout reference
- `cyberuni/color-map` — the worked example (PRs #210, #211)

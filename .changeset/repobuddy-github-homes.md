---
"unional-skills": patch
---

`apply-repo-baseline`, `migrate-legacy-ci`, `setup-secretless-release` and `ship-it` now name `repobuddy/.github` as the one home of the shared workflows for every owner, pinned at the released tag `v2`. `v1` is retired, and `unional/.github`, `cyberuni/.github` and `stable-packages/.github` are old homes to move callers off. `unional` repos get the publish gate too. The `migrate-legacy-ci` assets call `repobuddy/.github@v2`, with the publish gate and `actions: write`.

`apply-repo-baseline` names `github>repobuddy/renovate-preset`, and its canonical `assets/renovate-preset.json` now matches the published preset, including the `dep-changeset:*` labels for `optionalDependencies` and pnpm catalog updates ([unional/renovate-preset#5](https://github.com/unional/renovate-preset/pull/5)).

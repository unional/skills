# Brief: bump __PKG__ to __VERSION__ in __REPO__

Return address: `__OPERATOR__`, the Operator session that holds this order. If `__OPERATOR__` resolves to no live unit, report to `operator` instead. Report on this brief's thread (your unit id) with `cyberlegion mail send --to __OPERATOR__ --thread <your unit id>`.

## Why

The owner is moving every package they own to `__PKG__@__VERSION__`. The fleet goes leaf-first, so packages further up get the freshly released versions of the lower ones.

Released in this sweep: __RELEASED__

Known breaks in __VERSION__: __BREAKS__

## Work

1. Branch off the latest `origin/<default>`. Do not reuse an old local branch.
2. In every `package.json` (all workspaces, templates and test cases, but not `node_modules`), set `__PKG__` to `__VERSION__`. Keep the repo's range style.
3. Bump every dependency on the owner's packages to its latest npm version (`npm view <pkg> version --prefer-online`). Keep the range style.
4. Lift the minimum-release-age gate for `__PKG__` and for any freshly released owned package the install needs (`repobuddy:min-release-age`). Prefer an auto-expiring exemption, and never turn the gate off globally. Many repos already exempt first-party packages.
5. Reinstall so the lockfile updates. Fix what the new version breaks. Avoid adding a new runtime dependency where an inline change works, since the publish gate blocks them. Run the repo's full verify.
6. For published packages that list a bumped package in `dependencies` or `peerDependencies`, add a patch changeset (`buddy-changesets:changesets`), or follow the repo's release convention. Private packages get no changeset.
7. Commit using conventional commits, push, and open a PR.

## Watch

- **Never merge** the PR or any release PR. The Operator merges and releases.
- Report when done (PR URL, CI state, how the repo releases) or when blocked. Also report any break not listed above.
- When told trunk moved: rebase, adapt, re-verify, push, and report again. Stay alive after reporting.

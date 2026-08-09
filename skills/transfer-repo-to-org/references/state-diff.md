# Transfer state diff

Capture before, diff after. The value is not the capture — it is being able to say *which* setting the transfer dropped instead of re-applying the whole baseline blind.

## Capture

Run against the old owner immediately before the transfer, and against the new owner immediately after. Same script, different `REPO`.

```bash
#!/usr/bin/env bash
# usage: capture.sh <owner>/<repo> <out-dir>
set -euo pipefail
REPO="$1"; OUT="$2"; mkdir -p "$OUT"

gh api "repos/$REPO" \
  --jq '{allow_auto_merge, allow_update_branch, delete_branch_on_merge,
         allow_squash_merge, allow_merge_commit, allow_rebase_merge,
         has_issues, has_discussions, default_branch, visibility}' > "$OUT/settings.json"

gh api "repos/$REPO/actions/permissions/workflow" > "$OUT/actions.json"

gh api "repos/$REPO/rulesets" --jq '.[].id' | while read -r id; do
  gh api "repos/$REPO/rulesets/$id" \
    --jq '{name, target, enforcement, bypass_actors, rules}'
done | jq -s 'sort_by(.name)' > "$OUT/rulesets.json"

gh secret list --repo "$REPO" --json name --jq '[.[].name] | sort' > "$OUT/secrets.json"
gh variable list --repo "$REPO" --json name --jq '[.[].name] | sort' > "$OUT/variables.json"
```

```bash
./capture.sh unional/<repo>  /tmp/xfer/before
# ... transfer ...
./capture.sh cyberuni/<repo> /tmp/xfer/after
diff -ru /tmp/xfer/before /tmp/xfer/after
```

Ruleset ids change on transfer, which is why the capture drops them and sorts by `name` — otherwise every ruleset reads as modified.

## What a clean diff looks like

Exactly one difference, in `actions.json`:

```diff
-  "default_workflow_permissions": "write",
+  "default_workflow_permissions": "read",
```

That is the org default replacing the repo's value. OIDC needs `write`; restore it before the next release.

`settings.json`, `rulesets.json`, `secrets.json`, and `variables.json` should be byte-identical. Anything else that moved is drift worth naming out loud, not silently re-applying — it means the transfer did more than expected and the rest of the repo deserves a look.

## Not captured, and why

| | why |
| --- | --- |
| npm trusted publisher | lives on the registry, not the repo — `npm trust list <package>` before and after, and it will not change on its own; you change it (SKILL.md step 4) |
| Branch protection (legacy API) | superseded by rulesets in this baseline; if a repo still uses it, add `gh api repos/$REPO/branches/<b>/protection` to the capture |
| Environments | not used by the secretless release path; add if the repo has them |
| Webhooks, deploy keys | survive, and are cheap to eyeball in the UI if the repo has any |

#!/usr/bin/env bash
# usage: teardown.sh <local-checkout> <unit-id>
# Closes a merged pod, then the herdr workspace spawn opened on the primary checkout.
set -uo pipefail
d=$(cd "$1" && pwd); id=$2
wt=$(git -C "$d" worktree list --porcelain | awk -v id="${id:0:6}" '/^worktree/ && $2 ~ id {print $2}')
if [ -n "$wt" ] && git -C "$wt" status --short | grep -qv '\.agents/'; then
  echo "refusing: $wt has changes outside .agents/" >&2; exit 1
fi
cl() {
  if command -v cyberlegion >/dev/null; then cyberlegion "$@"; return; fi
  node "$(ls -d ~/.claude/plugins/cache/*/cyberlegion/*/bin/cyberlegion.mjs | sort -V | tail -1)" "$@"
}
(cd "$d" && cl unit close "$id" --force 2>&1 | tail -1)
herdr workspace list 2>/dev/null | jq -r --arg d "$d" \
  '.result.workspaces[]|select(.worktree.checkout_path==$d and (.worktree.is_linked_worktree|not))|.workspace_id' \
  | while read -r w; do herdr workspace close "$w" >/dev/null && echo "closed workspace $w"; done

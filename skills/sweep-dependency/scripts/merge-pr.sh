#!/usr/bin/env bash
# usage: merge-pr.sh <owner/repo> <pr>
# Merge-queue repos: enqueue. Otherwise merge with the first allowed method: squash, merge commit, rebase.
# stdout: {"repo","pr","method","state"}; gh messages go to stderr.
set -uo pipefail
R=$1; N=$2
base=$(gh api "repos/$R" -q .default_branch)
if gh api "repos/$R/rules/branches/$base" -q '.[]|.type' | grep -q merge_queue; then
  m=queue; gh pr merge "$N" -R "$R" >&2
else
  m=$(gh api "repos/$R" -q 'if .allow_squash_merge then "squash" elif .allow_merge_commit then "merge" else "rebase" end')
  gh pr merge "$N" -R "$R" "--$m" >&2
fi
s=$(gh pr view "$N" -R "$R" --json state -q .state)
printf '{"repo":"%s","pr":%s,"method":"%s","state":"%s"}\n' "$R" "$N" "$m" "$s"

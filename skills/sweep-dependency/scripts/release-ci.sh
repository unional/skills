#!/usr/bin/env bash
# usage: release-ci.sh <local-checkout> [branch=changeset-release/main]
# Pushes an empty commit to a bot-opened release branch so its pull_request CI runs.
set -euo pipefail
d=$1; b=${2:-changeset-release/main}
w=$(mktemp -d)/rel
git -C "$d" fetch -q origin "$b"
git -C "$d" worktree add -q "$w" "origin/$b"
git -C "$w" commit -q --allow-empty -m "ci: trigger checks for release PR"
git -C "$w" push -q origin "HEAD:$b"
git -C "$d" worktree remove --force "$w"
echo "pushed empty commit to $b in $d"

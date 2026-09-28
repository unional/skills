#!/usr/bin/env bash
# usage: inventory.sh <pkg> <owner>...
# stdout: one JSON object per dependent repo:
#   {"repo","archived","fork","packages":[{"name","version","private","range"}],"producers":[owned repos it depends on at runtime]}
set -euo pipefail
pkg=$1; shift
hits=$(mktemp); pkgs=$(mktemp); trap 'rm -f "$hits" "$pkgs"' EXIT
for o in "$@"; do
  gh search code "\"$pkg\"" --owner "$o" --filename package.json --limit 100 --json repository,path \
    -q '.[]|.repository.nameWithOwner+" "+.path' 2>/dev/null || true
done | sort -u | grep -vE 'node_modules|fixtures' > "$hits" || true
while read -r repo file; do
  gh api "repos/$repo/contents/$file" -q .content 2>/dev/null | base64 -d 2>/dev/null \
    | jq -c --arg r "$repo" --arg p "$pkg" '{repo:$r,name,version,private:(.private//false),
        range:([.dependencies[$p],.devDependencies[$p],.peerDependencies[$p]]|map(select(.))|join(",")),
        rt:((.dependencies//{})+(.peerDependencies//{})|keys)}' >> "$pkgs" || true
done < "$hits"
[ -s "$pkgs" ] || { echo "no repos depend on $pkg" >&2; exit 1; }
jq -s -c --arg p "$pkg" '
  (map({key:.name,value:.repo})|from_entries) as $own
  | group_by(.repo)[] | .[0].repo as $r
  | {repo:$r, packages:map({name,version,private,range}),
     producers:([.[].rt[]]|unique|map($own[.]//empty)|unique|map(select(. != $r and . != ($own[$p]//""))))}
' "$pkgs" | while read -r line; do
  r=$(jq -r .repo <<<"$line")
  flags=$(gh repo view "$r" --json isArchived,isFork -q '{archived:.isArchived,fork:.isFork}')
  jq -c --argjson f "$flags" '. + $f' <<<"$line"
done

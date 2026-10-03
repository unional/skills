#!/usr/bin/env bash
# usage: capture.sh <manifest-dir> [repo-root...]
# Writes what this machine has into <manifest-dir>. Captures no secrets, keys, or logins.
# Repo roots default to ~/code.
set -euo pipefail
out=${1:?usage: capture.sh <manifest-dir> [repo-root...]}; shift
roots=("${@:-$HOME/code}")
mkdir -p "$out"/{apt,system,user-services}

apt-mark showmanual | sort > "$out/apt/packages.txt"
cp /etc/apt/sources.list.d/*.list "$out/apt/" 2>/dev/null || true
find /etc/apt/keyrings /usr/share/keyrings /etc/apt/trusted.gpg.d -maxdepth 1 -type f -not -name 'ubuntu-*' 2>/dev/null \
  | tar czf "$out/apt/keyrings.tgz" -P -T -
. /etc/os-release; echo "$VERSION_CODENAME" > "$out/apt/codename"

cp /etc/wsl.conf "$out/system/wsl.conf" 2>/dev/null || true
cat /etc/timezone > "$out/system/timezone" 2>/dev/null || basename "$(dirname "$(readlink /etc/localtime)")"/"$(basename "$(readlink /etc/localtime)")" > "$out/system/timezone"
getent passwd "$USER" | cut -d: -f7 | xargs basename > "$out/system/shell"
: > "$out/system/enabled-units.txt"
for u in /etc/systemd/system/*.service; do
  [ -L "$u" ] || dpkg -S "$u" >/dev/null 2>&1 && continue
  systemctl is-failed -q "$(basename "$u")" && { echo "skipping failed unit $(basename "$u")" >&2; continue; }
  cp "$u" "$out/system/"
  systemctl is-enabled -q "$(basename "$u")" 2>/dev/null && basename "$u" >> "$out/system/enabled-units.txt"
done
for u in ssh.service tailscaled.service; do
  systemctl is-enabled -q "$u" 2>/dev/null && echo "$u" >> "$out/system/enabled-units.txt"
done

if command -v brew >/dev/null; then
  brew bundle dump --file="$out/Brewfile" --force --tap --formula --cask
fi

mkdir -p "$out/mise"
cp ~/.config/mise/config.toml "$out/mise/config.toml" 2>/dev/null || true
cp ~/.config/mise/default-npm-packages "$out/mise/" 2>/dev/null || true
npm ls -g --depth=0 --json 2>/dev/null \
  | jq -r '.dependencies // {} | keys[] | select(. != "npm" and . != "corepack")' > "$out/mise/npm-globals.txt" || true

if [ -f ~/.cargo/.crates.toml ]; then
  grep -oE '^"[^ ]+' ~/.cargo/.crates.toml | tr -d '"' > "$out/cargo-crates.txt"
fi
if command -v uv >/dev/null; then
  uv python list --only-installed --output-format json 2>/dev/null \
    | jq -r '.[] | select(.path | contains("/uv/python/")) | .version | split(".")[:2] | join(".")' | sort -u > "$out/uv-pythons.txt"
  uv tool list 2>/dev/null | { grep -vE '^[- ]|^No tools' || true; } | cut -d' ' -f1 > "$out/uv-tools.txt"
fi

for f in ~/.local/bin/* ~/.cargo/bin/*; do
  [ -e "$f" ] || continue
  if [ -L "$f" ]; then kind="-> $(readlink "$f")"; else kind=$(file -b "$f" | cut -d, -f1); fi
  printf '%s\t%s\n' "$(basename "$f")" "$kind"
done | sort > "$out/local-bin.txt"

for u in ~/.config/systemd/user/*.service; do
  [ -f "$u" ] || continue
  sed "s#$HOME#%h#g" "$u" > "$out/user-services/$(basename "$u")"
done
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null \
  | awk '{print $1}' | while read -r u; do if [ -f "$out/user-services/$u" ]; then echo "$u"; fi; done > "$out/user-services/enabled.txt"
loginctl show-user "$USER" -p Linger --value > "$out/user-services/linger" 2>/dev/null || true

for r in "${roots[@]}"; do
  { find "$r" -maxdepth 4 -name .git -type d -not -path '*.worktrees/*' -prune 2>/dev/null || true; } | while read -r g; do
    d=$(dirname "$g"); url=$(git -C "$d" remote get-url origin 2>/dev/null) || continue
    printf '%s\t%s\n' "${d#"$HOME"/}" "$url"
  done
done | sort > "$out/repos.tsv"

if [ -d ~/.local/share/nvim/mason/packages ]; then
  ls ~/.local/share/nvim/mason/packages > "$out/nvim-mason.txt"
fi

[ -f "$out/installers.sh" ] || cp "$(dirname "$0")/../assets/installers.sh" "$out/installers.sh"

echo "captured into $out:"
wc -l "$out"/apt/packages.txt "$out"/Brewfile "$out"/local-bin.txt "$out"/repos.tsv 2>/dev/null | sed '$d'

# Config in ~/.config that chezmoi does not carry never reaches the target. Review each entry.
if command -v chezmoi >/dev/null; then
  echo "~/.config entries chezmoi does not manage (chezmoi add the ones that are your config):"
  chezmoi unmanaged --path-style=absolute ~/.config | sed "s#^$HOME#  ~#"
  # ~/.claude mixes config (the scripts settings.json runs) with Claude Code's own runtime state.
  echo "~/.claude entries chezmoi does not manage, runtime state left out:"
  chezmoi unmanaged --path-style=absolute ~/.claude \
    | grep -vE "^$HOME/\.claude/(\.credentials\.json|\.last-[^/]*|backups|cache|downloads|feedback|file-history|history\.jsonl|ide|plugins|policy-limits[^/]*|projects|remote-settings\.json|session-env|sessions|shell-snapshots|stats-cache\.json|statsig|telemetry|todos)$" \
    | sed "s#^$HOME#  ~#"
fi

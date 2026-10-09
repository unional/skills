#!/usr/bin/env bash
# usage: verify.sh <manifest-dir>
# Lists what the manifest has and this machine lacks. Exits 1 when anything is missing.
set -uo pipefail
m=${1:?usage: verify.sh <manifest-dir>}
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:$PATH"
gaps=0
gap() { [ $# -gt 0 ] || return 0; printf '  %s\n' "$@"; gaps=$((gaps + $#)); }
section() { printf '%s\n' "$1"; }

section "apt"
gap $(comm -23 "$m/apt/packages.txt" <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' | awk '$1=="ii"{print $2}' | sort))
section "brew"
command -v brew >/dev/null || gap "brew itself"
command -v brew >/dev/null && gap $(brew bundle check --file="$m/Brewfile" --verbose 2>/dev/null | sed -n 's/^→ \(Formula\|Cask\|Tap\) \([^ ]*\).*/\2/p')
section "mise"
command -v mise >/dev/null && gap $(mise ls --missing --global 2>/dev/null | awk '{print $1"@"$2}')
section "cargo"
[ -s "$m/cargo-crates.txt" ] && gap $(comm -23 <(sort "$m/cargo-crates.txt") <(grep -oE '^"[^ ]+' ~/.cargo/.crates.toml 2>/dev/null | tr -d '"' | sort))
section "installers"
inst() { command -v "$1" >/dev/null || gap "$1"; }
todo() { gap "$1 (no installer recorded)"; }
manual() { command -v "$1" >/dev/null || gap "$1 (interactive installer: $2)"; }
. "$m/installers.sh"
section "editors"
if command -v nvim >/dev/null && [ -f ~/.config/nvim/init.lua ]; then
  gap $(nvim --headless -c 'lua for _, p in ipairs(require("lazy").plugins()) do if not p._.installed then io.write("nvim-plugin:" .. p.name .. "\n") end end' -c qa 2>/dev/null)
  [ -s "$m/nvim-mason.txt" ] && gap $(comm -23 <(sort "$m/nvim-mason.txt") <(ls ~/.local/share/nvim/mason/packages 2>/dev/null | sort) | sed 's/^/mason:/')
else
  gap "nvim config (~/.config/nvim) not applied"
fi
section "user services (copied / enabled)"
while read -r u; do
  [ -f ~/.config/systemd/user/"$u" ] || gap "$u not copied"
  systemctl --user is-enabled -q "$u" 2>/dev/null || gap "$u not enabled"
done < "$m/user-services/enabled.txt"
section "claude code (files settings.json runs)"
[ -f ~/.claude/settings.json ] && gap $(jq -r '.statusLine.command // empty, (.hooks // {} | .[][].hooks[]?.command)' ~/.claude/settings.json \
  | grep -oE "(~|\\\$HOME|$HOME)/[^ \"';|)]+" | sed "s#^~#$HOME#; s#^\\\$HOME#$HOME#" | sort -u \
  | while read -r f; do [ -e "$f" ] || echo "${f/#$HOME/\~}"; done)
section "repos"
[ -f "$m/repos.tsv" ] && gap $(while IFS=$'\t' read -r path _; do [ -d "$HOME/$path/.git" ] || echo "$path"; done < "$m/repos.tsv")
section "signing"
[ -f ~/.ssh/id_ed25519_signing ] || gap "signing key ~/.ssh/id_ed25519_signing not copied"
section "system"
[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" = "$(cat "$m/system/shell")" ] || gap "login shell is not $(cat "$m/system/shell")"
[ -f /etc/sudoers.d/90-bootstrap ] && gap "temporary passwordless sudo still present"

echo "$gaps gaps"
[ "$gaps" -eq 0 ]

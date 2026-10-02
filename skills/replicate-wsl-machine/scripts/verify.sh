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
section "user services (copied / enabled)"
while read -r u; do
  [ -f ~/.config/systemd/user/"$u" ] || gap "$u not copied"
  systemctl --user is-enabled -q "$u" 2>/dev/null || gap "$u not enabled"
done < "$m/user-services/enabled.txt"
section "repos"
[ -f "$m/repos.tsv" ] && gap $(while IFS=$'\t' read -r path _; do [ -d "$HOME/$path/.git" ] || echo "$path"; done < "$m/repos.tsv")
section "signing"
[ -f ~/.ssh/id_ed25519_signing.pub ] || gap "personal signing key ~/.ssh/id_ed25519_signing not copied"
if [ -f ~/.ssh/id_ed25519_signing_agent.pub ]; then
  grep -qF "$(cut -d' ' -f2 ~/.ssh/id_ed25519_signing_agent.pub)" ~/.config/git/allowed_signers 2>/dev/null || gap "agent signing key not in ~/.config/git/allowed_signers"
else
  gap "agent signing key ~/.ssh/id_ed25519_signing_agent not generated"
fi
section "system"
[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" = "$(cat "$m/system/shell")" ] || gap "login shell is not $(cat "$m/system/shell")"
[ -f /etc/sudoers.d/90-bootstrap ] && gap "temporary passwordless sudo still present"

echo "$gaps gaps"
[ "$gaps" -eq 0 ]

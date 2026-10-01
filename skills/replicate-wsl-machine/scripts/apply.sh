#!/usr/bin/env bash
# usage: apply.sh <manifest-dir> [phase...]
# phases, in order: system apt brew mise cargo uv installers services repos finish
# Idempotent: every phase skips what is already present. Run as the target user.
set -uo pipefail
m=$(cd "${1:?usage: apply.sh <manifest-dir> [phase...]}" && pwd); shift
all=(system apt brew mise cargo uv installers services repos finish)
phases=("${@:-${all[@]}}")
failed=()
log() { printf '\n== %s\n' "$*"; }
brewenv() { [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; }
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"; brewenv

phase_system() {
  [ -f "$m/system/wsl.conf" ] && sudo cp "$m/system/wsl.conf" /etc/wsl.conf \
    && sudo sed -i "s/^default=.*/default=$USER/" /etc/wsl.conf
  [ -s "$m/system/timezone" ] && sudo timedatectl set-timezone "$(cat "$m/system/timezone")"
}

phase_apt() {
  local src target; src=$(cat "$m/apt/codename"); . /etc/os-release; target=$VERSION_CODENAME
  [ -f "$m/apt/keyrings.tgz" ] && sudo tar xzf "$m/apt/keyrings.tgz" -P
  for l in "$m"/apt/*.list; do sed "s/\b$src\b/$target/g" "$l" | sudo tee "/etc/apt/sources.list.d/$(basename "$l")" >/dev/null; done
  sudo apt-get update 2>&1 | grep -E '^(E|W):' || true
  local want=() skip=()
  while read -r p; do
    if [[ $(apt-cache policy "$p" 2>/dev/null) =~ Candidate:\ [^\(] ]]; then want+=("$p"); else skip+=("$p"); fi
  done < "$m/apt/packages.txt"
  # Distros share one network stack, so a package starting its daemon (sshd on :22) collides
  # with the source distro's; policy-rc.d defers every start to the next boot.
  printf '#!/bin/sh\nexit 101\n' | sudo tee /usr/sbin/policy-rc.d >/dev/null && sudo chmod +x /usr/sbin/policy-rc.d
  sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${want[@]}" || failed+=(apt)
  sudo rm -f /usr/sbin/policy-rc.d
  [ ${#skip[@]} -gt 0 ] && echo "not available on $target (renamed or dropped): ${skip[*]}"
}

phase_brew() {
  if ! command -v brew >/dev/null; then
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { failed+=(brew); return; }
    brewenv
  fi
  brew bundle install --file="$m/Brewfile" || failed+=(brew)
}

phase_mise() {
  command -v mise >/dev/null || curl -fsSL https://mise.run | sh
  mkdir -p ~/.config/mise
  for f in config.toml default-npm-packages; do
    [ -f "$m/mise/$f" ] && [ ! -f ~/.config/mise/$f ] && cp "$m/mise/$f" ~/.config/mise/
  done
  mise install -y || failed+=(mise)
  [ -s "$m/mise/npm-globals.txt" ] && mise exec -- npm install -g $(cat "$m/mise/npm-globals.txt")
}

phase_cargo() {
  [ -s "$m/cargo-crates.txt" ] || return 0
  command -v cargo >/dev/null || { echo "cargo missing (brew rust)"; failed+=(cargo); return; }
  while read -r c; do cargo install --locked "$c" || failed+=("cargo:$c"); done < "$m/cargo-crates.txt"
}

phase_uv() {
  command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
  [ -s "$m/uv-pythons.txt" ] && uv python install $(cat "$m/uv-pythons.txt")
  [ -s "$m/uv-tools.txt" ] && while read -r t; do uv tool install "$t"; done < "$m/uv-tools.txt"
  true
}

phase_installers() {
  inst() { command -v "$1" >/dev/null && { echo "have $1"; return; }; echo "installing $1"; bash -c "$2" </dev/null || failed+=("inst:$1"); }
  todo() { echo "TODO no installer recorded: $1"; }
  manual() { command -v "$1" >/dev/null && { echo "have $1"; return; }; echo "RUN YOURSELF (interactive): $2"; }
  . "$m/installers.sh"
}

phase_services() {
  mkdir -p ~/.config/systemd/user
  for u in "$m"/system/*.service; do
    [ -f "$u" ] && [ ! -f "/etc/systemd/system/$(basename "$u")" ] && sudo cp "$u" /etc/systemd/system/
  done
  sudo systemctl daemon-reload
  [ -f "$m/system/enabled-units.txt" ] && while read -r u; do sudo systemctl enable "$u" 2>/dev/null || echo "cannot enable $u yet"; done < "$m/system/enabled-units.txt"
  for u in "$m"/user-services/*.service; do [ -f "$u" ] && cp "$u" ~/.config/systemd/user/; done
  [ "$(cat "$m/user-services/linger" 2>/dev/null)" = yes ] && sudo loginctl enable-linger "$USER"
  systemctl --user daemon-reload 2>/dev/null
  echo "user services copied but not enabled; enable each once its program is installed and configured:"
  sed 's/^/  systemctl --user enable --now /' "$m/user-services/enabled.txt" 2>/dev/null
}

phase_repos() {
  [ -s "$m/repos.tsv" ] || return 0
  gh auth status >/dev/null 2>&1 || { echo "gh not authenticated; run gh auth login, then rerun: apply.sh $m repos"; failed+=(repos); return; }
  local n=0
  while IFS=$'\t' read -r path url; do
    [ -d "$HOME/$path/.git" ] && continue
    mkdir -p "$(dirname "$HOME/$path")"
    git clone -q "$url" "$HOME/$path" </dev/null && n=$((n+1)) || failed+=("repo:$path")
  done < "$m/repos.tsv"
  echo "cloned $n repos"
}

phase_finish() {
  local sh; sh=$(command -v "$(cat "$m/system/shell" 2>/dev/null || echo bash)") && sudo chsh -s "$sh" "$USER"
  [ -f /etc/sudoers.d/90-bootstrap ] && sudo rm /etc/sudoers.d/90-bootstrap && echo "removed temporary passwordless sudo"
}

for p in "${phases[@]}"; do log "$p"; "phase_$p"; done
log done
[ ${#failed[@]} -eq 0 ] && echo "all phases succeeded" || { echo "failed: ${failed[*]}"; exit 1; }

#!/usr/bin/env bash
# usage: new-wsl.sh <name> <user> [image]
# Run from any WSL shell or Git Bash on the Windows host. Installs a new distro, creates
# <user> (bash until apply.sh's finish phase sets the captured shell), enables systemd, and
# grants temporary passwordless sudo so apply.sh can run unattended; finish removes it.
set -euo pipefail
name=${1:?usage: new-wsl.sh <name> <user> [image]}; user=${2:?}; image=${3:-Ubuntu-26.04}
wsl=wsl.exe
listed() { $wsl -l -q | iconv -f utf-16le -t utf-8 | tr -d '\r' | grep -qx "$1"; }
# wsl.exe --install hangs without a terminal, so install interactively when it does.
if listed "$name"; then echo "distro $name exists; configuring it"; else $wsl --install "$image" --name "$name" --no-launch; fi
as_root() { $wsl -d "$name" -u root --cd / -- bash -c "$1"; }
as_root "id $user >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo,adm $user"
as_root "printf '[boot]\nsystemd=true\n\n[user]\ndefault=$user\n' > /etc/wsl.conf"
as_root "echo '$user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-bootstrap && chmod 440 /etc/sudoers.d/90-bootstrap"
$wsl --terminate "$name"
$wsl -d "$name" --cd '~' -- bash -c 'echo "ready: $(whoami) on $(. /etc/os-release; echo $PRETTY_NAME), systemd=$(ps -p 1 -o comm=)"'
echo "set the password yourself: wsl.exe -d $name -u root passwd $user"

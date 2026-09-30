---
name: replicate-wsl-machine
description: "Capture what an Ubuntu WSL machine has installed and configured into a manifest, then rebuild it on a fresh WSL distro or another PC. Use this skill when asked to 'set up a new WSL like this one', 'replicate my machine', 'move to Ubuntu 26.04', 'bootstrap a new dev box', 'what's different between my two distros', or to refresh the manifest after installing new tools."
---

# Replicate WSL Machine

Captures the machine layer (apt, Homebrew, mise, cargo, uv, standalone installers, systemd units, git repos) into a manifest, and applies it to a target distro. The dotfiles layer is chezmoi's: run the dotfiles repo's `setup-dotfiles` skill for it, between the `brew` and `mise` phases.

Scripts are in `scripts/`, relative to this file. Each prints what it did; quote that output when reporting.

## Where the manifest lives

`machines/<name>/` in the chezmoi source repo (`chezmoi source-path`), with `machines` in its `.chezmoiignore`. It holds package lists and repo URLs, never secrets. Commit it there so another PC gets it with the dotfiles.

## 1. Capture (on the source machine)

```bash
scripts/capture.sh "$(chezmoi source-path)/machines/<name>" ~/code [more repo roots...]
```

Then review before committing:

- `local-bin.txt` lists everything in `~/.local/bin` and `~/.cargo/bin`. Each tool not covered by apt, brew, mise, cargo, or uv needs an `inst <binary> '<command>'` line in `installers.sh`. Find the command in `~/.zsh_history` (`grep -aE 'curl[^|]*\| *(ba)?sh'`) or the tool's docs. Never guess an installer URL. Leave it as `todo <binary>` and tell the user.
- Before capturing, check `chezmoi status`. Unpushed dotfile drift won't reach the target; offer to `chezmoi re-add` it and show the diff first.
- `user-services/*.service` have `$HOME` rewritten to `%h`. Any other absolute path in them (a version-manager shim, a `/run/user/...` path) breaks on the target. Point it at a stable path, or tell the user.

Rerun capture after installing tools. It overwrites everything except `installers.sh`.

## 2. Get a target distro

Fresh distro, created from any WSL shell on the Windows host:

```bash
scripts/new-wsl.sh <distro-name> <user> [image]   # image defaults to Ubuntu-26.04
```

It refuses a name that already exists. Replacing a distro means `wsl.exe --unregister <name>`, which deletes its disk. Confirm with the user first, and list anything in its `$HOME` not in the manifest (`.secrets`, keys, unpushed repos).

The user sets the password; you cannot, because it needs a terminal: `wsl.exe -d <name> -u root passwd <user>`.

## 3. Apply (on the target)

Drive it from the source machine through `wsl.exe`. First copy the manifest and the scripts in, because the target has neither until its dotfiles land:

```bash
tar c -C <manifest> . | wsl.exe -d <name> --cd '~' -- bash -c 'mkdir -p ~/.bootstrap/manifest && tar x -C ~/.bootstrap/manifest'
tar c -C <skill>/scripts . | wsl.exe -d <name> --cd '~' -- bash -c 'mkdir -p ~/.bootstrap/scripts && tar x -C ~/.bootstrap/scripts'
wsl.exe -d <name> --cd '~' -- bash .bootstrap/scripts/apply.sh .bootstrap/manifest system apt brew
```

On another PC with no source distro, clone the skills and dotfiles repos in the target instead.

Then, in order:

1. `gh auth login` in the target. It is interactive, so ask the user to run `wsl.exe -d <name>` and do it there.
2. The `setup-dotfiles` skill: `chezmoi init --apply unional/dotfiles`. It prompts for tokens, so the user runs it.
3. `apply.sh .bootstrap/manifest mise cargo uv installers services repos finish`
4. `wsl.exe --terminate <name>`, so the new login shell and systemd units take effect.

Every phase is idempotent. After a failure, rerun only the failed phases. `finish` removes the temporary passwordless sudo that `new-wsl.sh` granted. Run it last, even after failures.

Not carried over (the user decides each one):

- SSH keys, including the commit-signing key the gitconfig references
- cloud credentials (`~/.aws`, `~/.azure`, `~/.config/gcloud`) and `~/.secrets`
- agent logins
- ollama models: `ollama pull <model>`
- Docker: turn on the distro under Docker Desktop → Resources → WSL integration

## 4. Verify

```bash
wsl.exe -d <name> --cd '~' -- bash .bootstrap/scripts/verify.sh .bootstrap/manifest
```

It lists every gap by section and exits 1 if any exist. Report each gap as one of:

- a package renamed on the new Ubuntu release (the apt phase prints these)
- a `todo` installer
- a user service not yet enabled (enable it only after its program is configured)
- a real failure

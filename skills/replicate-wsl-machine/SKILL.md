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

- An installer that prompts (a license, a menu) reads `/dev/tty` and hangs unattended. Record it as `manual <binary> '<command>'`. Never answer a license prompt for the user.
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

Drive it from the source machine through `wsl.exe`, passing commands on stdin (`wsl.exe -d <name> --cd '~' -- bash -s <<'EOF'`). `wsl.exe` strips the quotes from arguments passed on its command line. First copy the manifest and the scripts in, because the target has neither until its dotfiles land:

```bash
tar c -C <manifest> . | wsl.exe -d <name> --cd '~' -- bash -c 'mkdir -p ~/.bootstrap/manifest && tar x -C ~/.bootstrap/manifest'
tar c -C <skill>/scripts . | wsl.exe -d <name> --cd '~' -- bash -c 'mkdir -p ~/.bootstrap/scripts && tar x -C ~/.bootstrap/scripts'
wsl.exe -d <name> --cd '~' -- bash .bootstrap/scripts/apply.sh .bootstrap/manifest system apt brew
```

On another PC with no source distro, clone the skills and dotfiles repos in the target instead.

Then, in order:

1. `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`, then `gh auth login` in the target. Brew is not on PATH until the dotfiles land. It is interactive, so ask the user to run `wsl.exe -d <name>` and do it there.
2. The `setup-dotfiles` skill: `chezmoi init --apply unional/dotfiles`. It prompts for tokens, so the user runs it.
3. Commit signing, below. The gitconfig sets `commit.gpgsign = true`, so every commit fails until it is done.
4. `apply.sh .bootstrap/manifest mise cargo uv installers services repos finish`
5. `wsl.exe --terminate <name>`, so the new login shell and systemd units take effect.

To skip a phase, such as cloning repos, leave it out of the phase list. Every phase is idempotent. After a failure, rerun only the failed phases. `finish` removes the temporary passwordless sudo that `new-wsl.sh` granted. Run it last, even after failures.

Not carried over (the user decides each one):

- SSH keys, apart from the two commit-signing keys below
- cloud credentials (`~/.aws`, `~/.azure`, `~/.config/gcloud`) and `~/.secrets`
- agent logins
- ollama models: `ollama pull <model>`
- Docker: turn on the distro under Docker Desktop → Resources → WSL integration

### Commit signing

Two keys sign commits, and the dotfiles wire both:

| Key | Signs | Protected by |
| --- | ----- | ------------ |
| `~/.ssh/id_ed25519_signing` | the user's own commits | a passphrase, held in Ubuntu's socket-activated ssh-agent (`ssh-add -t 8h`) |
| `~/.ssh/id_ed25519_signing_agent` | Claude Code's commits | nothing: it is the agent's key. Claude's `settings.json` env blanks `SSH_AUTH_SOCK` and points `user.signingkey` at it |

The personal key is carried over, never regenerated: GitHub and `allowed_signers` already list it. It is a private key, so the user copies it. Never read or copy it yourself. Give them this, run in the target:

```bash
install -d -m 700 ~/.ssh
(umask 077; wsl.exe -d <source> --cd '~' -- cat .ssh/id_ed25519_signing > ~/.ssh/id_ed25519_signing)
wsl.exe -d <source> --cd '~' -- cat .ssh/id_ed25519_signing.pub > ~/.ssh/id_ed25519_signing.pub
ssh-keygen -y -f ~/.ssh/id_ed25519_signing >/dev/null   # prompts only if it has a passphrase
```

If it does not prompt, the key has no passphrase, and any process running as the user, Claude included, can sign with it. Have the user add one with `ssh-keygen -p -f ~/.ssh/id_ed25519_signing`.

The agent key is per machine, so a leak is revoked without touching the personal key. Generate it on the target, never copy it:

```bash
ssh-keygen -t ed25519 -N "" -C "claude-agent commit signing (<name>)" -f ~/.ssh/id_ed25519_signing_agent
```

Then:

1. Add its public key to `dot_config/git/allowed_signers` in the dotfiles source with a `claude-agent` comment, and `chezmoi apply ~/.config/git/allowed_signers`.
2. Register it on GitHub as a signing key: `gh ssh-key add ~/.ssh/id_ed25519_signing_agent.pub --type signing --title "claude-agent (<name>)"`. That needs the `admin:ssh_signing_key` scope. If `gh` lacks it, the user runs `gh auth refresh -h github.com -s admin:ssh_signing_key`, which opens a browser.
3. When retiring the source machine, delete its agent key from GitHub (`gh ssh-key list`, `gh ssh-key delete <id>`) and from `allowed_signers`.

Until a new Claude Code session starts, the running one lacks the env. Sign its commits by prefixing `SSH_AUTH_SOCK="" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.signingkey GIT_CONFIG_VALUE_0=$HOME/.ssh/id_ed25519_signing_agent.pub`.

## 4. Verify

```bash
wsl.exe -d <name> --cd '~' -- bash .bootstrap/scripts/verify.sh .bootstrap/manifest
```

It lists every gap by section and exits 1 if any exist. Report each gap as one of:

- a package renamed on the new Ubuntu release (the apt phase prints these)
- a `todo` installer
- a user service not yet enabled (enable it only after its program is configured)
- a signing key not yet in place (see Commit signing)
- a real failure

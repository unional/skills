# Replicate WSL Machine

Captures what my Ubuntu WSL machine has installed into a manifest, and rebuilds it on a fresh distro or another PC.

## When to use

- "Set up the new Ubuntu 26.04 WSL like this one"
- Moving to a new PC and wanting the same dev box
- Checking what a second distro is missing

## What it does

`capture.sh` records the machine layer into a manifest: apt packages and third-party sources, Homebrew formulae and casks, mise tools, cargo crates, uv pythons, the tools in `~/.local/bin`, Neovim's Mason tools, systemd units, and every git repo under the roots you give it. It records no secrets. `new-wsl.sh` creates a distro with a user and systemd on. `apply.sh` installs the manifest phase by phase, and each phase is safe to rerun. `verify.sh` lists what the target still lacks.

Dotfiles stay with chezmoi. Capture lists any `~/.config` and `~/.claude` that chezmoi doesn't manage, so editor, tool, and Claude Code config isn't silently left behind. Verify reports any script `~/.claude/settings.json` runs that is missing, such as the status line script. The manifest lives in the dotfiles repo, so another PC gets both.

## Install

```bash
npx skills add unional/skills --skill replicate-wsl-machine
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

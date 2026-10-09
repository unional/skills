# unional-skills

## 1.2.0

### Minor Changes

- 5715b8e: `replicate-wsl-machine`: carry the editor setup over. Capture now records Neovim's Mason tools and lists the `~/.config` that chezmoi does not manage, a new `editors` apply phase restores the pinned plugins and installs the Mason tools, and verify reports missing plugins and tools.
- 16da16c: `replicate-wsl-machine` now has a commit-signing step: the user copies the signing key to the target, since the gitconfig signs every commit and each one fails until the key is there. `verify.sh` reports the key missing.
- 21b0ba2: Add the `replicate-wsl-machine` skill: capture a WSL machine's packages, tools, services, and repos into a manifest, then rebuild it on a fresh distro and verify what is still missing.
- 8696292: Add the `sweep-dependency` skill: bump one package across every owned repo leaf-first, merging and releasing each and verifying the publish on npm before moving up.

### Patch Changes

- eb4a0ce: Adopt the Agent Plugins Specification v1.0.0. The canonical manifest moves from `.plugin/plugin.json` to the repo root, `vendorExtensions` becomes `extensions["org.cyberuni.universal-plugin"].harnesses`, and `.plugin/plugin.json` is removed — Copilot CLI searches that path before the root, so leaving it would shadow the canonical manifest with a copy nothing regenerates.
  
  `plugin build` regenerates the derived manifests again; under the old layout it silently built nothing.
- 5715b8e: `replicate-wsl-machine`: stop leaving Claude Code's scripts behind. Capture now lists unmanaged `~/.claude` entries with runtime state left out, and verify reports any status line or hook script that `~/.claude/settings.json` runs but the machine lacks.
- 5715b8e: Reconcile contradictions across the release and repo-baseline skills: one account of the Version Packages PR approval (token variant held for approval, secretless variant needs an empty commit), post-publish checks read the registry directly instead of `npm view`, and `modernize-repo` runs the legacy-CI decision before the baseline. Drop dated counts and "earlier guidance was wrong" asides that rot.

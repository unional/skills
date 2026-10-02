# unional-skills

## 1.2.0

### Minor Changes

- 16da16c: `replicate-wsl-machine` now has a commit-signing step: the user copies the signing key to the target, since the gitconfig signs every commit and each one fails until the key is there. `verify.sh` reports the key missing.
- 21b0ba2: Add the `replicate-wsl-machine` skill: capture a WSL machine's packages, tools, services, and repos into a manifest, then rebuild it on a fresh distro and verify what is still missing.
- 8696292: Add the `sweep-dependency` skill: bump one package across every owned repo leaf-first, merging and releasing each and verifying the publish on npm before moving up.

### Patch Changes

- eb4a0ce: Adopt the Agent Plugins Specification v1.0.0. The canonical manifest moves from `.plugin/plugin.json` to the repo root, `vendorExtensions` becomes `extensions["org.cyberuni.universal-plugin"].harnesses`, and `.plugin/plugin.json` is removed — Copilot CLI searches that path before the root, so leaving it would shadow the canonical manifest with a copy nothing regenerates.
  
  `plugin build` regenerates the derived manifests again; under the old layout it silently built nothing.

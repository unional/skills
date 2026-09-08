---
"unional-skills": patch
---

Adopt the Agent Plugins Specification v1.0.0. The canonical manifest moves from `.plugin/plugin.json` to the repo root, `vendorExtensions` becomes `extensions["org.cyberuni.universal-plugin"].harnesses`, and `.plugin/plugin.json` is removed — Copilot CLI searches that path before the root, so leaving it would shadow the canonical manifest with a copy nothing regenerates.

`plugin build` regenerates the derived manifests again; under the old layout it silently built nothing.

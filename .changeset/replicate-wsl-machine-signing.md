---
"unional-skills": minor
---

`replicate-wsl-machine` now has a commit-signing step: the user copies the signing key to the target, since the gitconfig signs every commit and each one fails until the key is there. `verify.sh` reports the key missing.

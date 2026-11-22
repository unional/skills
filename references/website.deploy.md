---
description: The cyberuni house style for deploying a docs site — always GitHub Pages, enabled as part of the deploy without asking.
tags: [website, deploy, github-pages, house-style]
extends: [default]
---

## Step 1: Detect the git host

Deploy to GitHub Pages. unional's repositories live on GitHub, so `HOST` is `github`: follow `references/deploy-github.md` in the `website` skill's folder. If `git remote get-url origin` names another host, stop and ask the user.

`gh` must be installed and logged in.

## Step 5: Create the CI job and enable hosting

Follow `references/deploy-github.md`. When the reference repo (`cyberuni/cyber-mux`, or the repo the user names) has `.github/workflows/deploy-pages.yml`, copy it, and change only the artifact `path` when the site is not at `apps/website`.

Enable Pages as part of this step, without asking. Adding a docs site is the intent to publish it. A POST to a repo that already has Pages returns 409, which means there is nothing to do. Report the resulting `html_url`.

Enabling Pages on a private repo needs a paid plan, and the POST fails. Say so and go on. The rest of the setup still lands.

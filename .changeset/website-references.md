---
"unional-skills": major
---

Remove the `add-website` skill. Its cyberuni house style now ships as references that apply over `repobuddy`'s `website` skill defaults: `website.init`, `website.deploy`, and `website.update` in `references/`. With `repobuddy` and this plugin installed, run `repobuddy:website init` to add a site in the house style. Anything that invoked `unional-skills:add-website` must call `repobuddy:website` instead.

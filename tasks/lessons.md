# Lessons Learned

## Pattern

Classified unional-specific workflows as private because they referenced personal repositories and organizations, reversing this plugin's intended distribution boundary.

## Rule

For this plugin, publish opinionated workflows that apply to unional's account, organizations, and repositories. Keep general-purpose workflows installed locally under `.agents/skills` with `metadata.internal: true`.

## Context

When deciding whether a skill belongs in `skills/` or `.agents/skills/`, use the workflow's specificity—not whether it names a personal repository—as the boundary.

## Category

`architecture`

---
"unional-skills": patch
---

`ship-it`: read the `main` merge queue before merging the release PR, and wait while other PRs are ahead of it. Merge only when the release PR is at the front or the queue is empty. The skill gives the GraphQL query to use, because `gh pr view` has no `isInMergeQueue` field.

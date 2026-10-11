# Post on X

Drafts, reviews, and plans posts on X (Twitter) for a developer account, using the ranking weights X publishes for its For You feed.

## When to use

- "Draft a tweet", "announce the release on X", "write a thread"
- "Review this post", "when should I post"
- "Plan the release posts", "how should I roll out the announcement"
- "How do I get more reach", "grow my X account"

## What it does

It starts with a freshness check, because X updates the published ranker about every four weeks. If the recorded check is older than three months, it re-reads the default weights from `xai-org/x-algorithm` before drafting.

Drafts aim at the actions the ranker weights most, shares and replies, and avoid the ones it punishes hardest: mute, "not interested", block, and report. A release post leads with the problem it solves, shows a snippet or clip, and puts the link last. A major release becomes a run of feature posts two to three days apart, opened by a feature-led announcement. The skill counts characters with a script and returns the draft without posting it.

For growth it ranks advice by evidence. Premium, daily replies, and a steady posting cadence come first. Claims it could not verify, such as thread multipliers and the link penalty, become comparisons the user runs on their own posts.

## Install

```bash
npx skills add unional/skills --skill post-on-x
```

Or install every skill in this repo as one universal plugin, which works on Claude Code, Cursor, Codex, and GitHub Copilot CLI: <https://github.com/unional/skills#installation>

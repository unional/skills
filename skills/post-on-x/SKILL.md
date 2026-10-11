---
name: post-on-x
description: "Draft, review, and plan posts on X (Twitter) to grow a developer account, using the ranking weights X publishes. Use when asked to 'draft a tweet', 'announce the release on X', 'write a thread', 'review this post', 'when should I post', 'how do I get more reach', or 'grow my X account', and after shipping a release worth announcing."
---

# Post on X

Write for the signals X's ranker pays for. Avoid the signals it punishes. Measure what you cannot verify.

## Check freshness first

These rules were last checked against [xai-org/x-algorithm](https://github.com/xai-org/x-algorithm) on 2026-10-10. X says it updates the published ranker about every four weeks.

If that date is more than three months old, re-read the defaults before drafting:

```bash
gh api repos/xai-org/x-algorithm/contents/vm-ranker/params.rs -H 'Accept: application/vnd.github.raw' | grep -A3 -E 'Weight'
```

If a weight below has changed by more than 2x or flipped sign, update this file in the same change.

## What the ranker pays for

The score is the sum of each predicted action's probability times its weight. The published defaults:

| Action | Weight |
| ------ | ------ |
| Share by copying the link | +20 |
| Reply (a reply from a mutual follow adds +15) | +5 |
| Quote | +5 |
| Share by DM | +5 |
| Follow the author | +4 |
| Share | +2 |
| Repost | +1 |
| Like | +0.5 |
| Open a link | +0.2 |
| Report | -234 |
| Mute the author | -58.8 |
| "Not interested" | -47.5 |
| Block the author | -31.2 |

Out-of-network posts are scored at 0.75 of their value. Posts older than 48 hours drop out of the candidate pool. Each extra post by the same author in one feed gets a decaying multiplier.

The table settles these decisions:

- **Aim for shares and replies, not likes.** A post someone copies to a colleague is worth 40 likes. Write the post a reader would forward: the one that answers a question their team has.
- **One mute cancels about a dozen replies.** Cut engagement bait ("like if you agree"), tagging people who did not ask, and off-topic hot takes.
- **Do not burst.** Posting several times in an hour splits your own reach. Space posts hours apart.
- **Ignore the 2023 ladder.** Blogs still cite "reply-with-author-reply is 150x" and "bookmarks are 10x". Those came from the 2023 code, not the current one. The current code has no bookmark weight, and profile clicks are weighted 0.

## Draft a post

1. **Find the one thing a reader would forward.** For a release, that is the problem it solves or the bug it closes, not the version number. If the release has twenty changes, pick one or two and link the rest.
2. **Lead with that sentence.** Put it in the first line, because the feed truncates the rest.
3. **Show it.** A short code snippet that shows the change, a before/after, or a 10 to 20 second screen recording. A code image needs the point in the text too, and alt text.
4. **Put the link last, in the post.** X's head of product says links are no longer deboosted, and the published ranker has no link penalty. Engagement on link posts is still low, because readers leave. Never make the link the post's only value.
5. **Skip hashtags.** Use one at most, for a real community tag. No evidence says they help, and several stacked hashtags read as spam.
6. **Check the length.** 280 characters without Premium. A URL counts as 23. Count with a script, not by eye:

   ```bash
   python3 -c "import re,sys;print(len(re.sub(r'https?://\S+','x'*23,sys.stdin.read().rstrip())))" < draft.txt
   ```

7. **Match the author's voice.** Plain, specific, no hype words ("game-changer", "excited to announce"), no emoji walls. One emoji is fine if the author uses them.

When there is more than one post's worth, offer a thread: the first post stands alone, and each reply adds one concrete example. Do not claim threads get more reach. No reliable data says so.

Return the draft in a code block with its character count. Do not post it. The user posts.

## After posting

Tell the user to stay around for the first hour and reply to every real reply. A reply from a mutual follow is the strongest repeatable signal they control, and the post leaves the pool after 48 hours.

## Grow the account

When asked how to grow, recommend this, in order of evidence:

1. **Premium ($8 a month tier).** Buffer measured about 10x the median reach for Premium accounts over 18.8M posts, Aug 2024 to Aug 2025. The data is correlational. The $3 Basic tier shows little lift. ([Buffer](https://buffer.com/resources/x-premium-review/))
2. **15 to 20 minutes a day of substantive replies** on larger accounts in the same niche (TypeScript, dev tooling). Replies carry +5, and a reply is where a stranger first sees the account.
3. **Three to five original posts a week.** No rigorous frequency study exists. This keeps clear of the author-diversity decay.
4. **Weekdays, midday to early evening in the audience's time zone.** A weak prior from Sprout Social's data. ([Sprout Social](https://sproutsocial.com/insights/best-times-to-post-on-twitter/))

Treat X Articles, Communities, and "threads get 3x" as untested. Do not recommend them as growth levers without the user's own data.

## Measure what is disputed

Link placement and format are not settled. When the user asks which works better, set up a comparison instead of answering from folklore:

- Change one variable across 4 to 6 comparable posts. For example: link in the post vs. link in the first reply, or clip vs. code image.
- Compare impressions and engagement rate from X's analytics 48 hours after each post. The post is out of the candidate pool by then.
- Record the result in the user's notes, not in this skill. One account's data is not a general rule.

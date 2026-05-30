---
name: community-proposal
description: "Use this skill when contributing a design proposal to an open-source community — research, draft with evidence, file."
---

# Community Proposal

## When to use

When you have a design decision or architectural insight and want to contribute it upstream — as a GitHub issue, RFC, or discussion post — with evidence, community context, and counterarguments addressed.

## Steps

### 1. Identify the primary venue

Pick the repo where the standard is actively being *defined*, not where it is discussed in aggregate. Filing in a spec repo is more impactful than filing in a community forum or issue tracker that explicitly defers decisions elsewhere.

Signal for the right venue: maintainers there are empowered to merge normative spec changes based on the issue.

### 2. Research existing discussions

Search the target repo and related community repos for prior issues, PRs, and threads on the same topic. For each find, record:

- Issue/PR number and URL
- Author handle (for `@mention` later)
- The core claim or proposal
- Current status (open, closed, merged, stalled)
- Whether it agrees with, partially overlaps with, or contradicts your proposal

Aim for 3–5 direct prior-art references. Stop when additional searches return nothing new.

### 3. Categorize positions

Separate what you found into two groups:

**Agreements** — issues/comments that independently converge on the same conclusion or identify the same problem. These are your supporting evidence; cite them directly.

**Counterarguments** — objections, alternative proposals, or explicit disagreements. Do not ignore them. For each, determine whether it is:
- Fully addressed by your proposal (state how)
- Partially addressed (acknowledge the gap)
- Out of scope (say so without dismissing it)

### 4. Write a research document

If the repo has a `docs/research/` convention, save findings there before drafting the post. This separates durable evidence from the ephemeral issue body.

Use the format: `YYYY-MM-<topic>.md`. Include sources, community position table, and open questions.

### 5. Draft the post

Structure:

1. **Opening** (2–3 sentences) — acknowledge what the project already got right before stating the problem. Establishes credibility and good faith.
2. **Ideas** (not "Positions" or "Demands") — one section per idea, each with a concrete example (code, table, or quote).
3. **What I'd love to see clarified** — a numbered list of specific, actionable asks. Use "Clarify" or "Recommend", not "Must" or "Require".
4. **Prior art and community support** — bullet list, one per reference, with `@handle` for authors.
5. **Anticipated pushback — and my take** — address each known objection directly. Acknowledge before countering.
6. **Closing** (2 sentences) — offer to contribute spec language; end with an open question to invite dialogue.

### 6. Calibrate the tone

Apply throughout the post:

| Area | Do | Avoid |
| --- | --- | --- |
| **General register** | Casual, collegial — "feels like", "I think", "Sharing in case it's useful" | Formal position papers, "I propose that the spec shall" |
| **Technical positions** | Firm and specific — blockquotes, tables, concrete JSON examples | Hedging technical claims with "maybe" or "possibly" |
| **Objection responses** | Open with acknowledgment — "Fair concern." / "Agreed —" before the counter | Terse or dismissive rebuttals |
| **Voice** | First-person singular — "I", "I'm already shipping…" | "We" unless writing on behalf of a named team |
| **Author handles** | `@username` on all referenced authors so GitHub notifies them | Bare usernames that don't trigger notifications |
| **Closing** | End with a question that opens dialogue | Ending on a demand or deadline |

### 7. Final review before filing

Check:
- [ ] Title is firm and specific (the proposal is clear, even if the body is humble)
- [ ] Every referenced issue has a link and `@handle`
- [ ] No "we" when writing as an individual
- [ ] Counterarguments section addresses every objection found in step 3
- [ ] Closing includes an offer to contribute and an open question
- [ ] Own repo or implementation is mentioned to show skin in the game

### 8. File

```bash
gh issue create \
  --repo <org>/<repo> \
  --title "<title>" \
  --body "$(cat <<'BODY'
<post body>
BODY
)"
```

Capture the URL from stdout and update the research document with a link to the live issue.

## Anti-patterns

- **Filing in the discussion forum instead of the spec repo** — gets acknowledged but never acted on.
- **Listing objections without addressing them** — makes the proposal look incomplete; maintainers will raise them in comments anyway.
- **"Position 1 / Position 2" headings** — sounds like a formal debate brief; use "Idea 1 / Idea 2" instead.
- **Ending with demands** — "the spec MUST add this" closes the conversation; "I'd love to see this clarified" opens it.
- **Skipping the prior art section** — wastes maintainer time and signals you haven't read the existing discussions.
- **Cross-posting to multiple venues simultaneously** — pick the primary venue; cross-reference from secondary venues after the primary issue is live.

## References

- `governance show skill-design` — skill authoring rules
- `governance show skill-repo-structure` — repo layout for saving research docs

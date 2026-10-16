## Last updated

October 2026 (2026-10-14).

## Question

How do people use AI agents and LLMs to write social media posts, with a focus on X posts by developers announcing or explaining a dev tool, library or technique, so that the posts perform well and do not read as AI-generated? Which techniques, prompts, workflows and voice-capture methods work, and what is the evidence?

## Verdict

No study measures AI-assisted versus human developer posts on X. What exists is adjacent: studies of AI text detection, studies of reader reaction on TikTok, LinkedIn and Instagram, and a larger body of practitioner advice. Read together, they point the same way. Readers who use LLMs a lot can spot AI text with high accuracy (five heavy-user annotators misclassified 1 of 300 articles), and developers are that kind of reader. The tells that give it away are mostly staging and vocabulary: contrast framing ("not X, it's Y"), tidy triplets, aphoristic closers, inflated or promotional words, decorative formatting. One such device is weak evidence. A cluster of them is what people notice, and in 280 characters two devices is already a cluster.

Stripping the tells is necessary and not sufficient. Wikipedia's guide and the most-used open-source humanizer both say the same thing from different sides: the tells are symptoms of generic content. A post reads human when it carries things a model would not invent: the actual moment, the actual quote, a number, a choice the author can explain, and a plain register the author really uses. The one controlled social study with a mechanism (USC, TikTok) found the engagement penalty came from perceived low effort, not from lower quality, and effort is what generic polished prose signals even without a label. I found no evidence of an X-specific penalty for AI-sounding short posts, so that link is inference.

For voice, the best-supported method is to give the model several of the author's own real posts, as tagged examples, plus a short banned-pattern list, and to have the human write or rewrite the first line and any sentence with "I" in it. Anthropic recommends 3 to 5 relevant, diverse examples and says examples are among the most reliable ways to steer tone. A research result on imitation from a person's own samples found models do worst on informal writing, which is what tweets are, so plan for an edit. No source tested examples against adjective descriptions of voice, so "examples beat adjectives" is well motivated and unmeasured. Two respected developer-writers (Willison, Ptacek) take the strict position that the model should proofread and critique and the human should write every opinionated sentence. That is the most conservative workflow, and for a 40-word post it costs little.

Counter-evidence exists but is weak. Small tests show AI posts matching or beating human posts on engagement rate (three pairs on one X account, in 2023), and blind raters often cannot tell AI from human text. Detectors are unreliable against humanized text. None of that applies well to developer posts read by heavy LLM users, and none of it shows the posts were good, only that they were not penalized in those samples. The sensible target is not to beat a detector but to survive a skeptical developer.

## Reference material

### Checklist for an agent drafting a developer post on X

1. Start from a human seed. Ask the author for the real moment in their own words (what happened, what they typed, what annoyed them). Quote it. Do not invent a story, a quote or a number; ask when missing.
2. Load the author's voice as 3 to 5 real past posts, diverse in topic and length, each in `<example>` tags, not as adjectives. If none exist, ask for three before drafting rather than guessing a voice. Say which patterns in the examples to copy (opening, punctuation, capitalization, emoji use).
3. Put the concrete thing first: the number, the command, the error text, the before/after. Show it with a screenshot, a short clip or a two-line snippet. The text should carry the point without the image.
4. Write at the author's register. Use plain verbs ("is", "has", "wrote"), contractions, fragments if the author uses them. Do not add typos or slang the author does not use; perfect grammar is not a tell.
5. Say it once. One idea, one example, no recap line. Cut any sentence that names the feeling or the lesson.
6. Allow at most one rhetorical device. Skip contrast framing unless it corrects a misconception already stated in the post.
7. Keep every sentence that has "I" or an opinion in the author's words. The model may reorder and cut, not rephrase those.
8. Give a number limit to the model ("under 240 characters"), not "be concise".
9. Run the tell scan below, then a critique pass: list what still reads as AI, fix each, and compare against the original so facts did not drift.
10. Give the author two or three variants that differ in angle, not in wording. The author picks and edits.
11. A real ask or an open question is fine when it is real; a fake engagement closer is not.
12. Link last, per the `post-on-x` skill.

### AI tells to strip (clusters matter more than singles)

- Contrast framing: "not X, it's Y", "X isn't about A, it's about B", "rather than".
- Tidy triplets and parallel lists of three.
- Aphoristic or mannered closers: "that's the whole trick", "earns its keep", "a dial worth turning", "and that changes everything".
- Run-ups: "Here's the thing:", "Let's be honest", "Turns out", "What if I told you".
- Hook clichés and argue-with-no-one openers: "Stop doing X", "Most developers don't realize".
- Inflated or promotional words: "game-changer", "seamless", "powerful", "robust", "leverage", "unlock", "delve", "crucial", "pivotal", "showcase", "testament".
- Copula avoidance: "serves as", "features", "boasts" for "is" and "has".
- Vague attribution: "many developers", "experts say".
- Participle trailers: ", making it easier to...", ", ensuring that...".
- Heavy em dashes (Willison is accused of AI use partly for them; ban or cap them and watch for replacements).
- Decorative bold, emoji as bullets, thread-numbering emoji, hashtags stacked at the end.
- Chat leftovers: "Here's a post", "Certainly", any sign-off.
- Smoothness itself: every sentence the same length, no fragment, no aside, no self-correction.

### Suggested drafting workflow

1. Gather: the author tells the seed in a few messy lines; the agent asks only for missing facts (number, command, error text, link) and for 3 to 5 past posts if not stored.
2. Draft: the agent writes 2 to 3 variants from the examples and the seed, with the banned list in the prompt. Optionally add Anthropic's mannered-prose paragraph (E09) to the user message.
3. Critique: a separate pass lists remaining tells and checks every fact against the seed. Per Ptacek, tell it not to flatter, and have a fresh context choose between original and revised if comparing.
4. Human edit: the author rewrites the first line and any "I" sentence in their own words. Treat any model phrasing that sounds like a headline as suspect.
5. Check length with the script in `post-on-x`, attach the screenshot or clip, post, then reply to real replies.
6. Record results per post in the author's notes. One account's data is not a rule (see the `post-on-x` "Measure what is disputed" section).
7. Voice file upkeep: when the author rewrites a draft, store the final post as a new example. This is the cheapest way to improve the voice over time.

### Before and after

These first two come from real sources and show the principle, not tweets. The third is an illustration for the current draft and is untested.

1. Contrast framing (blader/humanizer SKILL.md, section 1).
   - Before: "It's not merely a song, it's a statement."
   - After: "The heavy beat adds to the aggressive tone."
   - The fix replaces the staged claim with a concrete observation.
2. Mannered prose (Anthropic, Prompting Claude Fable 5.1).
   - Before: "a dial worth turning"
   - After: "a parameter worth varying"
   - Say what you mean when a literal phrase exists.
3. Illustration for the example draft (not from a source; my inference from E01, E11, E14, E27, E29).
   - Before:
     ```
     My agent kept handing me plain bullet lists. To reply, I had to spell out which bullet I meant: "the one about retries... no, the other one."

     So I added a rule to AGENTS.md: label every list. Now I just type "A: yes, C: later".
     ```
   - Diagnosis: three tidy beats (problem, fix, payoff), a "So I added" turn, and polished sentences of similar length. The quoted "no, the other one" is the good, human part.
   - After (sketch, in the author's own register; attach a screenshot of a real labeled list):
     ```
     agent gave me 6 bullets. I wanted to answer 2 of them.
     typed "the retries one... no, the other one" like an idiot

     one line in AGENTS.md: label every list.
     now it's "A yes, C later"
     ```
   - What changed: the screenshot carries the show-don't-tell; the self-deprecating detail replaces the setup sentence; no payoff line; the link goes last or in a reply. The exact casing and tone must come from the author's own posts, not from this sketch.

## Confidence

- Medium that the tells and the "clusters, not singles" principle are right (Wikipedia, two tool repos, one news report, one detection paper, all consistent).
- Medium that the author's own samples plus a human-written seed is the best-supported voice method; the direct evidence is practitioner reports and vendor docs, and no study compares it with alternatives.
- Low that any specific tactic raises performance on X. No source measures this for developer posts.
- Low on prevalence figures; they come from vendors who sell detectors.

## Strongest support

- Frequent LLM users detect AI text and beat most detectors, including on paraphrased text (Russell et al., ACL 2025) [E04].
- Wikipedia's tell catalog and its warning that fixing the tells alone misses the problem [E01 to E03].
- Anthropic's own docs: 3 to 5 diverse examples, match prompt style to output style, and a paste-in prompt against mannered prose [E08, E09].
- Convergence of Willison and Ptacek on "model edits, human writes the opinionated words" [E15 to E17].
- USC finding that the engagement penalty runs through perceived effort [E18].

## Strongest counterevidence

- Blind raters cannot tell AI from human text, and prefer whatever is labeled human regardless of source [E05, E06].
- Small tests where AI posts matched or beat human posts on engagement rate [E25, E22].
- Build-in-public data suggesting format and length rarely predict outliers [E28, low confidence], so a cleaner voice may not move numbers.
- Tell lists are descriptive and drift by model generation; humans write them too [E01, E24].

## Not supported

- That a humanizer pass or banned-word list alone makes a post perform.
- That AI-sounding short posts are penalized by X's ranker or by developer readers specifically. Inference only.
- That examples beat adjective descriptions of voice. Plausible, untested.
- That lowercase style, fragments, brevity or emoji absence raise reach on X. Advice only.
- Vendor claims that voice-learning tools make output "indistinguishable" [E32].
- Any claim that detectors can be relied on in either direction [E30, E01].

## Thin evidence

- X-specific data: Pangram prevalence only [E23]; no performance data.
- Dev-tool announcement posts: one 2022 study on tweeting [E27] and marketing advice [E29].
- Primary text not read for E19, E20, E26, E28, E33 (search summaries only).
- The 54 percent human detection of fine-tuned social posts in E06 is secondary.
- Several practitioner workflows (E12, E13) have no tests.

## Recheck triggers

- The author runs a comparison of 4 to 6 posts (voice-examples draft versus current skill draft) and reads impressions and replies at 48 hours.
- A new Anthropic prompting page changes writing guidance or the "mannered prose" advice [E09].
- A study measures AI-sounding versus human posts on X, or X states a ranking policy for AI content.
- A new Wikipedia "Signs of AI writing" revision, especially the em dash and "signs of human writing" sections, or a new Pangram or Originality report (next likely Q1 2027).
- blader/humanizer or write-in-my-voice change their pattern lists.
- The next frontier model release changes which phrases it overuses.

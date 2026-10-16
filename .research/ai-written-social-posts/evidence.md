# Evidence

Notes on method: pages were fetched on 2026-10-14. Where a claim rests on a search summary or a secondary write-up and I did not read the primary text, the entry says so and confidence is capped at low or medium.

## Claim E01

Date: 2026-10-14
Status: supports
Confidence: high

Source:
- Label: Wikipedia, "Signs of AI writing" (WikiProject AI Cleanup advice page)
- URL: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- Type: discussion (community advice page, not policy)

Notes:
- The page catalogs observed AI tells in content (inflated significance, promotional tone, vague attribution, formulaic "challenges and outlook" endings), language (AI vocabulary, copula avoidance, negative parallelism, rule of three), style (title case, decorative bold, emoji as formatting) and chat leftovers.
- It says the list is descriptive, that human writers produce the same patterns, and that "Please do not merely treat these signs as the problems to be fixed; that could just make detection harder." The tells point at a deeper problem (generic, unsourced, unspecific content).
- Caveat: written for encyclopedia prose, not 280-character posts. Read in two parts; the first 200k characters plus the tail were checked. The em dash entry was not located in the portion read, though the page index lists it as a dated sign (2022 to September 2026).

## Claim E02

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: Wikipedia, "Signs of AI writing", sections on human writing and ineffective indicators
- URL: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- Type: discussion

Notes:
- Human-written text more often uses simple "is/has", plain words ("wrote" not "authored"), definitive statements ("was the first"), qualifiers ("perhaps") and wordy phrases ("in order to"). LLMs avoid these by default.
- Listed as unreliable indicators: perfect grammar, mixed casual and formal register, bland prose, transition words alone. So "add typos" is not what makes text read as human.
- The page also states that humans perform near chance in studies and that LLM and human writing are converging (see E05, E04 for conflicting evidence).
- Caveat: Wikipedia context.

## Claim E03

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: Wikipedia, "Signs of AI writing", language section
- URL: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- Type: discussion

Notes:
- Named patterns relevant to short posts: negative parallelism ("not only... but", "it is not just X, it's Y", "X rather than Y"); rule of three ("adjective, adjective, adjective" up to phrase triplets); AI vocabulary ("delve", "crucial", "pivotal", "tapestry", "testament", "underscore", "showcase", "intricate", with the set shifting by model era); promotional words ("boasts", "vibrant", "nestled").
- Curly quotes are a ChatGPT/DeepSeek habit; Gemini and Claude usually do not use them. Curly quotes alone prove nothing.
- Caveat: word lists drift by model generation, so any fixed list ages.

## Claim E04

Date: 2025-01-27
Status: supports
Confidence: medium

Source:
- Label: Russell, Karpinska, Iyyer, "People who frequently use ChatGPT for writing tasks are accurate and robust detectors of AI-generated text" (ACL 2025, arXiv:2501.15654)
- URL: https://arxiv.org/abs/2501.15654
- Type: paper

Notes:
- 300 English non-fiction articles from GPT-4o, Claude and o1-Pro. Annotators who often use LLMs for writing detected AI text without training. A majority vote of five such experts misclassified 1 of 300 and beat most commercial and open-source detectors, including on paraphrased or "humanized" text.
- Experts leaned on "AI vocabulary" but also on formality, originality and clarity.
- Caveats: five experts, long-form articles not tweets, models from 2024. Less experienced annotators were poor. I read the abstract and summaries, not the full PDF. Implication: frequent LLM users, which describes much of the developer audience on X, are the readers most able to spot tells.

## Claim E05

Date: 2025-08-06
Status: contradicts
Confidence: medium

Source:
- Label: Zhu, Weissburg, Zhang, Wang, "Human Bias in the Face of AI: Examining Human Judgment Against Text Labeled as AI Generated" (arXiv:2410.03723, v2)
- URL: https://arxiv.org/abs/2410.03723
- Type: paper (preprint)

Notes:
- In a blind test, raters could not reliably tell AI from human text (rephrasing, summarization, persuasive writing). When labeled, raters strongly preferred "Human Generated" (over 30 points), and the preference held when labels were swapped.
- Contradicts E04 on detectability; both can hold if general raters differ from heavy LLM users.
- Caveat: not social posts; preprint; the label bias is the useful part: the label matters more than the content.

## Claim E06

Date: 2025-07
Status: mixed
Confidence: medium

Source:
- Label: Dawkins, Fraser, Kiritchenko, "When Detection Fails: The Power of Fine-Tuned Models to Generate Human-Like Social Media Text" (ACL Findings 2025)
- URL: https://aclanthology.org/2025.findings-acl.695
- Type: paper

Notes:
- Dataset of about 505k AI-generated social media posts on 11 controversial topics. Search summary reports a 250-person human study with 54 percent accuracy (near chance) on fine-tuned model output; the abstract page itself gives no figure, so the 54 percent is secondary.
- Fine-tuning on real posts is what made text hard to detect. Detectability dropped "dramatically" when the attacker's model stayed private.
- Caveat: fine-tuning, not prompting, so it supports the value of the author's own corpus but not a particular prompt trick. Short, informal text is harder to detect (also noted in related tweet-detection work, automated detectors only).

## Claim E07

Date: 2025-09-18
Status: supports
Confidence: medium

Source:
- Label: Wang et al., "Catch Me If You Can? Not Yet: LLMs Still Struggle to Imitate the Implicit Writing Styles of Everyday Authors" (EMNLP 2025 Findings, arXiv:2509.14543)
- URL: https://arxiv.org/abs/2509.14543
- Type: paper

Notes:
- 400+ real authors, over 40,000 generations per model, in-context learning from the author's own samples, scored by authorship attribution and verification, style matching and AI detection.
- Works better on structured domains (news, email); struggles with informal blogs and forums. A secondary summary says few-shot beat zero-shot on all metrics; the fetched abstract does not state this.
- Caveat: tweets are the informal case where models do worst, so expect a ceiling on pure imitation and plan for a human edit. No head-to-head of examples versus adjective descriptions was found anywhere in this research.

## Claim E08

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: Anthropic, "Prompting best practices"
- URL: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Type: official docs

Notes:
- "Examples are one of the most reliable ways to steer Claude's output format, tone, and structure." Recommends 3 to 5 examples that are relevant, diverse (so the model does not pick up unintended patterns) and wrapped in `<example>` tags.
- "Match your prompt style to the desired output": markdown in the prompt raises markdown in the output.
- Caveat: general guidance, not tested on voice. Does not compare examples with written style descriptions.

## Claim E09

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: Anthropic, "Prompting Claude Fable 5.1", section "Writing density"
- URL: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
- Type: official docs

Notes:
- Defines "mannered prose" (metaphor and flourish in place of direct statement, e.g. "a dial worth turning" for "a parameter worth varying") and supplies a paste-in paragraph. States "Please remove all mannered prose." also tends to work. Place it in the user message (preferred) or system prompt.
- Same page says newer Claude models lean away from bullets and bold in chat.
- Caveat: Anthropic's own claim, untested publicly; commentators noted the guide's own prose is ornate. Relevant because aphoristic closers ("earns its keep") are a common tell in short posts.

## Claim E10

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: blader/humanizer README (agent skill, MIT, 57k stars on the fetched page)
- URL: https://github.com/blader/humanizer
- Type: repo

Notes:
- Skill built on E01. 26 patterns ranked by strength: strongest are "staging instead of stating" (contrast framing, one-line closers, deep-sounding sayings, run-ups before the point, arguing with no one); then rhythm by rule (forced triads, repeated openings, dash overuse); inflation; formatting; chat leftovers; re-explaining to the wrong reader.
- Workflow: mark tells, draft, critique "what still reads as AI", final. Never invents facts, asks instead. States detectors still flag most output and avoiding detectors is not the goal. Several patterns count only in clusters.
- The README's "16 of 16 blind-test preference" is the author's own report (issue #229), unverified. Star count undated.

## Claim E11

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: blader/humanizer SKILL.md (voice guidance)
- URL: https://raw.githubusercontent.com/blader/humanizer/main/SKILL.md
- Type: repo

Notes:
- "Removing tells is half the job; the result must still sound like a person." A user voice sample overrides the general rules (including the dash rule); match sentence length, word choice, punctuation, openings, transitions.
- Keep specific unusual details, mixed feelings, first-person choices the writer can explain, genuine asides and self-corrections.
- Caveat: design guidance, no measured effect.

## Claim E12

Date: 2026-01-28
Status: supports
Confidence: low

Source:
- Label: Claudia Faith, "I Trained Claude Code How to Write Like Me" (Level Up with AI, Substack)
- URL: https://levelupwithai.substack.com/p/i-trained-claude-code-how-to-write
- Type: practitioner post

Notes:
- Method: a ~400-line CLAUDE.md style guide plus an export folder of past posts; Claude analyzes 5 to 10 past posts first (hooks, sentence length, transitions, favored and avoided words). Rules: open with a real moment, use specific numbers, vary sentence length, show what did not work. Bans: rhetorical-question hooks, "game-changer", jargon. File took 3 to 4 iterations.
- Self-reported: first drafts "80% there", drafting time cut sharply. No blind test or engagement data. Newsletter articles, not tweets.

## Claim E13

Date: 2026-03-13
Status: supports
Confidence: low

Source:
- Label: Will Francis, "How to Stop Claude Writing Like an AI"
- URL: https://willfrancis.com/how-to-stop-claude-writing-like-an-ai/
- Type: practitioner post

Notes:
- Give audience, purpose, a sample of your own writing in the same format as the target, and the draft; request edits that name the problem; keep the original beside the revision; set numeric length limits instead of "be concise"; ban specific habits (em dashes) then check for replacement patterns; keep facts, numbers and quotes unchanged.
- The author sells a Humanizer skill; the article offers no tests or metrics and says nothing guarantees "undetectable" output.

## Claim E14

Date: 2026-10-14
Status: supports
Confidence: low

Source:
- Label: Alexander Weichart, write-in-my-voice skill, references/anti-ai-writing
- URL: https://alexanderweichart.de/7_Agent/skills/write-in-my-voice/references/anti-ai-writing
- Type: repo (personal skill)

Notes:
- Distilled from E01. Layered design: a personal `voice-profile.md` outranks the generic anti-AI list; rules vary by register (essay, notes, reply; e.g. notes allow bold but ban em dashes); ten-point self-check before delivery.
- Key heuristic: density. One occurrence of a pattern is human; three or more clustered in a paragraph is what readers notice. Negative parallelism allowed only when X was already introduced and the contrast corrects a real misconception.
- Undated, single-author, no measured effect.

## Claim E15

Date: 2026-09-17
Status: mixed
Confidence: medium

Source:
- Label: Thomas Ptacek, "How to write with an LLM"
- URL: https://sockpuppet.org/blog/2026/09/17/how-to-write-with-an-llm/
- Type: practitioner post

Notes:
- Rule one: use no word or turn of phrase an LLM suggests; use the model as copyeditor, not ghostwriter. Models produce "magazine headline" polish that reads as artificial in aggregate. Rule two: models flatter drafts, so tell it not to encourage and distrust praise.
- Workflow: model lists problems, you rewrite each flagged passage yourself, then give original and revised to a fresh model to choose, to avoid sycophancy.
- Opinion from an experienced writer; no data. Directly contradicts the "generate then humanize" approach in E10 and E12; the safest reading is that it protects voice at the cost of speed.

## Claim E16

Date: 2026-03-01
Status: supports
Confidence: medium

Source:
- Label: Simon Willison, "AI writing" policy post
- URL: https://simonwillison.net/2026/Mar/1/ai-writing/
- Type: practitioner post

Notes:
- "If text expresses opinions or has 'I' pronouns attached to it then it's written by me. I don't let LLMs speak for me in this way." LLMs may draft READMEs and docs (edited to remove invented rationale), and proofread. He notes readers often assume his posts are LLM-written, partly because of em dashes.
- The first-person, opinion-bearing line is the part to keep human. A well-known developer voice; single practitioner.

## Claim E17

Date: 2026-09-17
Status: supports
Confidence: medium

Source:
- Label: Simon Willison, reaction to Ptacek's rule
- URL: https://simonwillison.net/2026/Sep/17/how-to-write-with-an-llm/
- Type: practitioner post

Notes:
- Willison says Ptacek's rule feels right to him but his own practice is looser: no LLM-written blog content; uses LLMs for fact-checking, spelling and grammar, and as an occasional thesaurus. Notes LLM-suggested phrasing has an off-putting quality.
- Shows two respected developer-writers converging on "model edits, human words."

## Claim E18

Date: 2026-10-14
Status: supports
Confidence: medium

Source:
- Label: Carney, Riveros, Tully, "Made With AI: Consumer Engagement with Social Media Containing AI Disclosures" (J. Consumer Research, forthcoming), via SSIR Fall 2026
- URL: https://ssir.org/articles/entry/ai-disclosures-social-media-disengagement
- Type: paper (reported by magazine)

Notes:
- About 1M TikTok posts around TikTok's Sept 2023 disclosure rule plus controlled experiments. Disclosed-AI posts got less engagement (a secondary summary says about 7 to 8 percent fewer likes); the SSIR article gives no effect sizes.
- Mechanism: perceived lower creator effort weakens the parasocial bond; not content quality, not distrust of AI. A creator-written description of which parts used AI softened the effect.
- Caveat: about disclosed AI on TikTok video, not undisclosed text on X. The reaction is to perceived effort, which is what generic prose signals.

## Claim E19

Date: 2026-05
Status: supports
Confidence: low

Source:
- Label: Macquarie University, "The AI penalty and disclosure paradox: trust, authenticity and knowledge uptake" (Computers in Human Behavior: Artificial Humans), via search summary
- URL: https://researchers.mq.edu.au/en/publications/the-ai-penalty-and-disclosure-paradox-trust-authenticity-and-know/
- Type: paper (not read in full)

Notes:
- Pre-registered survey, N=547: AI-involved communication judged less trustworthy, less authentic, less useful for knowledge uptake; people say disclosure is important yet penalize it.
- Only the search summary was seen; verify before citing.

## Claim E20

Date: 2026-10-14
Status: contradicts
Confidence: low

Source:
- Label: Instagram experiment on voluntary AI-as-creative-partner disclosure (133 students, fictional brand), via search summary
- URL: https://insider-gaming.com/ai-labels-can-reduce-social-media-engagement-study-finds/ (coverage of the penalty side; the 133-student study was only seen in a search summary and its own URL was not captured)
- Type: paper (unread)

Notes:
- Reported: voluntary disclosure raised perceived transparency and brand trust with no adverse attitude effects. Small, preliminary, fictional brand. Contradicts E18 and E19 on disclosure but is weak.

## Claim E21

Date: 2026-07-30
Status: supports
Confidence: medium

Source:
- Label: Originality.ai, LinkedIn AI study (July 2026 posts)
- URL: https://originality.ai/blog/linkedin-ai-study-engagement
- Type: blog (vendor)

Notes:
- 81.2% (4,061 of 5,000) of July 2026 LinkedIn posts of 100+ words were classified "Likely AI" by the vendor's own detector; the page reports no engagement metrics. LinkedIn's CPO reportedly confirmed a "Seems like AI slop" menu option.
- Conflict of interest (detector seller); the URL slug mentions engagement but the fetched page did not contain any. Evidence that AI posts are now the baseline readers are tired of.

## Claim E22

Date: 2025
Status: mixed
Confidence: low

Source:
- Label: Originality.ai earlier LinkedIn studies (2024, 2025), via search summary
- URL: https://originality.ai/blog/linkedin-ai-study-engagement
- Type: blog (vendor), not read in full

Notes:
- Search summary: 2024 data (2,726 posts) had likely-AI posts at about 45% less engagement; the 2025 update (3,368 posts, 99 profiles) was mixed by industry (AI up 75% in leadership and inspiration, human up 44% in healthcare and 40% in government).
- Vendor detector, likes and comments only, LinkedIn not X. The 2025 figures could not be confirmed on the page fetched.

## Claim E23

Date: 2026-07-09
Status: supports
Confidence: medium

Source:
- Label: Pangram Labs five-platform study, reported by The Decoder
- URL: https://the-decoder.com/linkedin-is-the-undisputed-king-of-long-form-ai-slop-according-to-a-study-spanning-five-platforms/
- Type: blog (reporting vendor study)

Notes:
- 1M+ posts from a browser extension, April to June 2026. Fully AI-generated share of posts over 250 words: LinkedIn 41%, Medium 31%, X 29%, Reddit 13%, Substack 10%. For 50 to 250 words: LinkedIn 30%, X 9%. A search summary says another 23% of long X content was AI-assisted.
- Short X posts are mostly human so far, which makes a polished AI-cadence short post stand out. Vendor claims 0.01% false positives; sample is what users happened to see; the article's text and chart disagree on the X number.

## Claim E24

Date: 2026-04-20
Status: supports
Confidence: medium

Source:
- Label: TechCrunch, on "not just X, it's Y" in AI and corporate writing
- URL: https://techcrunch.com/2026/04/20/ai-writing-its-not-just-this-its-that-barrons/
- Type: blog (news)

Notes:
- Barron's counted the construction in corporate filings rising from about 50 in 2023 to over 200 in 2025. Pangram's CEO calls it a tic of 2025-era frontier models but "no smoking gun", since humans write it too.
- Supports treating it as a density signal and a clarity cost, not a ban. Single news report of secondary data.

## Claim E25

Date: 2023-08-09
Status: mixed
Confidence: low

Source:
- Label: Hootsuite, "I tried to out-tweet ChatGPT" style experiment (Sam Lauron)
- URL: https://blog.hootsuite.com/experiment-ai-vs-human-writer/
- Type: practitioner post

Notes:
- Three human and three ChatGPT posts on one X account under 300 followers. AI posts had higher engagement rate in 2 of 3 pairs; human posts had more impressions in 2 of 3. The human link post got more meaningful actions (profile visits, clicks) and a brand retweet that confounds it. AI winners used hashtags and emojis.
- Three pairs: anecdote only. Old model generation.

## Claim E26

Date: 2026-10-14
Status: contradicts
Confidence: low

Source:
- Label: Instagram alternating-post field experiment (12 human versus 12 AI posts), via PostEverywhere search summary
- URL: https://posteverywhere.ai/blog/does-ai-content-perform-on-social-media
- Type: blog (secondary)

Notes:
- Reported: human posts won on likes, comments and engagement rate; AI won on non-follower reach and profile visits. Original paper not located. Treat as unverified.

## Claim E27

Date: 2022-06
Status: supports
Confidence: medium

Source:
- Label: Fang et al., "This Is Damn Slick! Estimating the Impact of Tweets on Open Source Project Popularity and New Contributors" (ICSE 2022, distinguished paper), via CMU release
- URL: https://www.cmu.edu/news/stories/archives/2022/june/open-source-software.html
- Type: paper (read through summaries)

Notes:
- 44,544 tweets linking 2,370 GitHub repos versus a control group: tweeting associated with about a 7% rise in the chance of new stars and a 2% rise in contributors, dose-dependent. Tweets from fans did better than tweets from the developers themselves; posts asking for help with a specific task drew better responses.
- 2022 Twitter data, not X today, and the paper's text was not read. Suggests third-party voice and a concrete ask matter.

## Claim E28

Date: 2026-09
Status: mixed
Confidence: low

Source:
- Label: LigoSocial, build-in-public outliers on X (1,209 tweets, 15 creators), via search summary
- URL: https://ligosocial.com/research/x-build-in-public-outliers
- Type: blog (vendor research; page returned 403, summary only)

Notes:
- Reported: only 3.6% of tweets reached 10x the creator's own median likes, and format, length and posting time mostly did not predict outliers. Normalized per creator.
- Implies no stylistic recipe reliably produces a hit; AI-versus-human not tested. Verify directly.

## Claim E29

Date: 2026-10-14
Status: supports
Confidence: low

Source:
- Label: Developer marketing sources (Apify docs, Flowjam, Adam DuVander on Kelsey Hightower replies), via search summaries
- URL: https://newslepear.beehiiv.com/p/72-my-first-video-teardown-merch-promo-idea-and-kelsey-hightower-asking-developers-what-marketing-wo
- Type: practitioner post (secondary)

Notes:
- Developers asked what marketing works said: help, do not impress; do not feel like marketing; let us try it. Vendors (Apify, Flowjam) claim short terminal demos beat polished brand video; no measurement. An ADVIDS survey of 49 dev-tool demo videos has no view or click data.
- No controlled data on dev-tool announcement posts was found. Show-don't-tell is consensus advice, not tested.

## Claim E30

Date: 2025-01
Status: mixed
Confidence: medium

Source:
- Label: Pangram Labs, "DAMAGE: Detecting Adversarially Modified AI Generated Text" (arXiv:2501.03437), plus Ayub et al. 2024 and a DEV Community test, via search summaries
- URL: https://arxiv.org/abs/2501.03437
- Type: paper

Notes:
- Many detectors miss text run through 19 humanizer/paraphrase tools; Pangram builds a detector that stays accurate. A 2024 study found essays pass as human after HIX.AI. A free-detector test on DEV found only 2 of 7 reliable. A Rework summary cites Weber-Wulff et al. (misclassification about 20% to 71% after paraphrase); I could not verify it.
- Detector vendors are interested parties; the point for this skill is that detectors and human experts (E04) disagree, so write for human readers, not detectors. E10 says the same.

## Claim E31

Date: 2026-10-14
Status: supports
Confidence: high

Source:
- Label: Hacker News Guidelines
- URL: https://news.ycombinator.com/newsguidelines.html
- Type: official docs

Notes:
- "Don't post generated text or AI-edited text. HN is for conversation between humans." and "please don't automate posting." Also "Please don't use HN primarily for promotion."
- Shows a developer venue where AI-written or AI-edited text is against the rules. Relevant if the same copy is reused on Hacker News or Reddit.

## Claim E32

Date: 2026-10-14
Status: mixed
Confidence: low

Source:
- Label: OpenTweet and similar vendor guides ("AI brand voice twitter", "AI tweet writer guide")
- URL: https://opentweet.io/how-to/ai-brand-voice-twitter
- Type: blog (vendor)

Notes:
- Claims: generic generators produce statistically average posts; fixes are concrete context ("a moment and its stakes"), learning from up to 50 of your own posts (sentence openings, em dash use, hook length) and character limits. Claude tends to write long; give a limit.
- Marketing claims of "indistinguishable" output are unverified. Consistent with E07 and E12 on method but not evidence of effect.

## Claim E33

Date: 2026-10-14
Status: mixed
Confidence: low

Source:
- Label: Linguistic characteristics of AI-generated text: a survey (arXiv:2510.05136), via search summary
- URL: https://arxiv.org/pdf/2510.05136
- Type: paper (PDF could not be parsed)

Notes:
- Reported through a search summary: AI-generated tweets less often contain URLs and user mentions than human tweets; findings on personal references are mixed. Unverified; I could not read the PDF.
- If true, the user's habit of ending with a URL is human-like, and a mention or reply to a real person is another cheap human signal. Treat as a lead to check.

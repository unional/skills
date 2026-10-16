# AI-Written Social Posts (October 2026)

## Question

How do people use AI agents and LLMs to write social media posts, with a focus on X posts by developers announcing or explaining a dev tool, library or technique, so that the posts perform well and do not read as AI-generated? Which techniques, prompts, workflows and voice-capture methods work, and what is the evidence?

## Scope

- In: voice capture, drafting workflows, AI tells, reader reaction to AI-perceived text, open-source humanizer skills, vendor prompting guidance, developer-audience norms, counter-evidence.
- Out: X ranking weights (already in the `post-on-x` skill), posting schedules, growth tactics.
- Context: the `post-on-x` skill produces drafts judged "too AI" and "not social enough". The example draft is a three-beat story (problem, rule added, payoff) plus a bare link.
- Limits: no controlled study of AI versus human developer posts on X exists in what I found. Most tactics rest on practitioner reports, vendor guidance and adjacent studies (LinkedIn, TikTok, Instagram, long-form text). Several search-only sources are marked low confidence in `evidence.md`.

## Source angles

1. Practitioner workflows (Substack, personal skills, Ptacek, Willison, Francis).
2. AI-tell research (Wikipedia, Russell et al., Zhu et al., Dawkins et al., TechCrunch on contrast framing, Pangram and Originality prevalence data).
3. Tools and prompts (blader/humanizer, write-in-my-voice, Anthropic prompting docs, style-imitation paper).
4. Developer-audience specifics (Fang et al. on tweets and OSS, developer marketing advice, build-in-public data).
5. Counter-evidence (AI posts that perform, detector unreliability, humans cannot tell, disclosure results).

## Findings

### Readers who matter can spot the tells, and the tells are mostly vocabulary and staging

Frequent LLM users detect AI text with high accuracy, including after paraphrasing [E04]. Developers are heavy LLM users. Wikipedia's field guide lists the common signs: inflated significance, AI vocabulary, negative parallelism, rule of three, promotional tone, decorative formatting [E01, E03]. The strongest ones in the humanizer skill's ranking are staging devices: "not X but Y", one-line closers, deep-sounding sayings, run-ups before the point [E10]. Human text tends toward plain "is/has" verbs, definite claims and plain words [E02]. Perfect grammar and plain prose are not tells [E02].

### One tell is not a tell; clusters are

Pangram's CEO says "not just X, it's Y" is no smoking gun because humans write it too [E24]. The humanizer README says several patterns count only in clusters [E10], and one personal skill states the heuristic as a density rule: three or more patterns in one paragraph is what readers notice [E14]. In 280 characters, one such device is already a cluster.

### Removing tells is not enough

Wikipedia warns that fixing the signs alone can just make detection harder, because the real problem is the generic content under them [E01]. The humanizer says "removing tells is half the job; the result must still sound like a person" [E11]. Developers' own stated preference is help over impress, no marketing feel [E29]. The tells point at missing specifics: a real moment, a real number, a real choice.

### Voice capture works best from the author's own text, and the models are weakest on informal text

Anthropic recommends 3 to 5 relevant, diverse examples in tags and calls examples one of the most reliable ways to steer tone [E08]. Practitioners feed 5 to 10 past posts and have the model extract patterns first [E12], or give a same-format sample and a banned list [E13], or use a voice profile that outranks the generic anti-AI list [E14]. Humanizer treats a user sample as overriding its general rules [E11]. The research supports fine-tuning on real posts as the thing that makes text hard to detect [E06] and in-context imitation as better on structured text than on informal blogs and forums [E07]. No source compared examples against adjective descriptions of a voice. Treat "examples beat adjectives" as well-motivated but unmeasured.

### The strongest practitioner position is: the model edits, the human writes the words

Willison writes every opinion or "I" sentence himself and uses models for proofreading and fact-checking [E16, E17]. Ptacek goes further: use none of the model's words, and use it as a copyeditor that lists problems you then fix yourself, with a fresh model as judge to avoid flattery [E15]. This is the opposite of generate-then-humanize [E10, E12]. For a short post about a personal experience, the human-written seed is cheap, and it is the part that carries the evidence of effort.

### Perceived effort drives the reader reaction

The best-controlled social study found that AI disclosure on TikTok cut engagement through perceived lower effort, not lower quality [E18]. Another found AI communication judged less authentic and trustworthy, with a "disclosure paradox" [E19]. A label study found raters prefer text labeled human regardless of true origin [E05]. These are about disclosure, but the mechanism (effort and authenticity) is what generic polished prose signals without any label. Evidence for a penalty on undisclosed AI-sounding X posts specifically is absent.

### AI-sounding text is now the baseline in long posts, much less in short X posts

Pangram found 29 percent of X posts over 250 words fully AI-generated, but only 9 percent of 50 to 250 words [E23]. Originality found 81 percent of sampled July 2026 LinkedIn long posts "Likely AI" [E21]. Both vendors sell detectors. LinkedIn reportedly added a "Seems like AI slop" option [E21]. In short X posts a smooth, tidy AI cadence is the minority style and so more noticeable.

### Developer-specific evidence is thin; show-don't-tell is consensus, not measurement

Tweets about a repo were associated with a 7 percent rise in new stars; fan tweets beat maintainer tweets, and a concrete request for help drew more response [E27]. Developer marketing advice favors demos, terminal output and not feeling like marketing [E29], but with vendor sources and no data. Build-in-public data suggests format and length rarely predict outliers [E28]. HN bans generated and AI-edited text outright [E31].

### Detectors are not the target

Detectors miss humanized text [E30], and humanizer tools say detectors are not the goal [E10]. Human experts beat most detectors [E04]. Write for a skeptical heavy-LLM-user reader.

## Contradictions

- Humans cannot tell AI text apart in blind tests [E05, E06, and Wikipedia's own statement in E02] versus trained frequent users detect it almost perfectly [E04]. Likely reconciliation: reader experience and text type differ. The dev audience resembles the E04 experts.
- AI posts can perform: two of three pairs on engagement rate in a tiny X test [E25], mixed LinkedIn industry results [E22], a favorable small disclosure study [E20]. Against that: human wins on Instagram [E26], TikTok penalty [E18], LinkedIn 2024 gap [E22]. Mostly low-confidence and not about developer posts.
- Generate-then-humanize [E10, E12, E13] versus never use the model's words [E15, E16, E17]. Both are practitioner opinion; neither is tested against the other.
- Fix the tells [E10, E14] versus Wikipedia's warning that fixing tells misses the underlying problem [E01].

## Open questions

- Does supplying the author's past posts beat a written voice description, and by how much, for tweets? No head-to-head found.
- Do X readers or the ranker penalize AI-sounding short posts? Not found; the penalty data is TikTok and LinkedIn.
- What do high-performing developer tool announcements share, measured against each author's baseline? Only the LigoSocial summary [E28] touches this, and it could not be read in full.
- Whether lowercase, fragments or casual register help is untested; it is only advice.
- Do the Pangram detection data and Anthropic's "mannered prose" prompt hold for the current model generation?

## Sources consulted

- Wikipedia, Signs of AI writing [E01 to E03]
- Russell et al. ACL 2025 [E04]; Zhu et al. 2025 [E05]; Dawkins et al. ACL Findings 2025 [E06]; Wang et al. EMNLP Findings 2025 [E07]; DAMAGE [E30]; linguistic survey [E33]
- Anthropic prompting docs [E08, E09]
- blader/humanizer [E10, E11]; write-in-my-voice [E14]
- Claudia Faith [E12]; Will Francis [E13]; Ptacek [E15]; Willison [E16, E17]; OpenTweet [E32]
- USC/SSIR [E18]; Macquarie [E19]; Instagram studies [E20, E26]
- Originality.ai [E21, E22]; Pangram via The Decoder [E23]; TechCrunch [E24]; Hootsuite [E25]
- Fang et al. via CMU [E27]; LigoSocial [E28]; developer marketing [E29]; Hacker News guidelines [E31]
- Not found: any Anthropic or OpenAI statement about X-specific post writing; any dev-account teardown with metrics; primary text for E19, E20, E26, E28, E33.

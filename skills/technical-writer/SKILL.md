---
name: technical-writer
description: "Apply a consistent documentation standard: controlled plain prose, one home per fact, and every external claim backed by a source. Use when writing or revising documentation, READMEs, or skill bodies; when deciding where a document belongs; when moving, renaming, or splitting a page; when a draft reads as generated and needs its rhythm, filler words, or em dashes fixed; or on requests like 'improve the docs', 'audit the docs', 'this page is too long', 'this sounds like AI', 'humanize this', 'remove the em dashes', or 'where should this be documented'."
---

# Technical Writer

Decide three things in order: whether the content earns its place, where it belongs, and how it reads. Placement errors survive editing, so settle them first.

## Does it earn its place

Classify a page by its intended use, not by its path or title. A tutorial leads the reader through ordered steps. A reference supports lookup.

Split a page that holds two concerns. Test: can you name what the page delivers without saying "and"?

Cut narrated investigation, dead design-session citations, and "we considered X but". Keep the rule and cut the reasoning that produced it. Where the reasoning is worth keeping, move it to wherever the project records decisions and link to it.

Never treat length alone as a defect.

## Where it belongs

Read `LOOKUP.DOC.md` first if the project has one. Check the repository root, then `.agents/`. It holds pointers only: where the authority for each kind of claim lives, and which source files generated tables must match.

Most repositories will not have one, and a flat repository does not need one. Infer the homes from the layout instead, and state which you assumed before you move anything.

Give every load-bearing fact (one that other pages depend on) exactly one home. Link to that home from every other page. Two copies of a fact drift: a change lands in one and misses the other.

Most documentation toolchains do not validate internal links, and hand-maintained navigation does not update itself. So:

- A new page needs its navigation entry in the same change, or it ships unreachable.
- Grep for inbound references before you move or rename a page. Check the navigation config, cross-page links, and any agent-facing files that cite paths.
- Complete a move in one change: remove the content from the old home, add it to the new home, and fix every inbound link.
- Add a redirect when a published URL changes.

## How it reads

- Write one instruction per sentence. Keep instructions shorter than 20 words.
- Use active voice. Use the imperative for procedures.
- Use one term for each concept. Do not change the term for variety.
- Do not use idiom or metaphor.

These rules cover prose you write. Leave code samples, command output, and quoted material unchanged.

If the project has a glossary, it is the authority for terms. Add a new term there in the same change that introduces it.

## Fix the rhythm and structure

A generated draft has a flat rhythm. Every sentence lands in the same length band, and every paragraph runs the same number of sentences. Nothing stands out, and the reader cannot tell what matters.

Vary the length on purpose:

- Follow a long sentence with a short one.
- Open or close a paragraph with a sentence under eight words.
- Vary paragraph length too. A one-sentence paragraph is legitimate emphasis.

The 20-word cap governs instructions. Explanatory prose may run longer when the sentence still carries one idea.

Structure repeats the same failure. Watch for these shapes and break them:

- Paragraphs that open with a connector: "Furthermore", "Moreover", "Additionally". Delete the connector. The order already carries the logic.
- Lists of exactly three, every time. Use the number of items you actually have.
- The "not just X, it's Y" reversal. State Y.
- Every section built as claim, three bullets, closing summary. Cut the summary when it restates the claim.

Then apply the deletion test. Remove a paragraph and reread. If nothing was lost, it was filler.

## Delete the tell words

Some words mark a draft as unedited. Each one also costs precision. Cut them.

Delete on sight: delve, tapestry, realm, landscape, journey, testament, beacon, cornerstone, seamless, robust, crucial, pivotal, vital, comprehensive, meticulous.

Replace inflated verbs with plain ones. Use `use` for `utilize` and `leverage`, `help` for `facilitate`, `start` for `embark on`, `show` for `showcase`, `stress` for `underscore`.

Cut these openings whole: "In today's fast-paced world", "It is important to note that", "In the ever-evolving landscape of", "Picture this".

Cut praise of the subject: "powerful", "elegant", "game-changing". State what the thing does instead.

Ungrounded authority goes too. "Studies have shown", "experts agree", and "research suggests" each stand in for a citation that was never made. Name the source or drop the claim. See "Back what you write".

Treat this as a starting set. Add the words your own drafts overuse, and remove any that the project's glossary defines as a real term.

## Remove em dashes

Do not use em dashes in prose you write. Each one has a better replacement:

- A claim followed by its explanation takes a colon.
- An aside takes parentheses. Use a pair of commas when the aside is short enough to read inline.
- Two joined independent clauses become two sentences.

The colon replacement is unsafe inside YAML frontmatter. An unquoted scalar ends at the first `: `, so a colon added there truncates the value or breaks the parse. Inside frontmatter, quote the whole value or split the sentence in two.

Leave em dashes in quoted material, code samples, and command output.

## Make it read as written, not generated

The rules above strip the machine signature. They do not supply a voice. Do this pass last.

- Read the draft aloud. Rewrite every sentence you stumble over.
- Name the concrete thing. Replace "various configuration options" with the two options.
- Give the specifics a generator cannot invent: version numbers, failure modes, the constraint that forced the design.
- Keep contractions where speech would use them.
- State limits plainly. "This breaks on Windows" beats "may present challenges on some platforms".
- Do not compensate with personality. Jokes, exclamation marks, and rhetorical questions read as generated too.

Write for the reader, not for a detector. A detector score is not the goal, and no single tell convicts a draft on its own.

## Back what you write

- A statement about someone else's product is a claim that decays. Trace it to primary vendor documentation. A blog post, an aggregator, or another agent's output is corroboration, never the source.
- Record the source where the project keeps evidence (`.research/<topic>/evidence.md` by convention) with an ID, URL, date, status, and confidence. Cite the conclusion in prose rather than restating the investigation.
- Mark a contested or single-sourced claim as such. Do not rewrite it as confident prose.
- Check a claim about the project against the source code, not against another document.
- Separate the objective from current behavior. Do not state an aspiration as a fact.
- When a claim cannot be sourced, write less rather than guessing.

## Auditing an existing corpus

Run the cheapest probes first. The commands below assume a git repository and POSIX tools; substitute the project's own file listing and shell where they do not apply.

1. **Size outliers.** List the largest documents and read the list as a prompt for judgment, not a verdict.

   ```sh
   git ls-files '*.md' ':(exclude)**/node_modules/**' ':(exclude)**/dist/**' | xargs wc -w | sort -rn | head -30
   ```

2. **Duplication.** Grep distinctive phrases across the docs, the READMEs, and any agent-facing files. Keep one home; replace the other copies with links.
3. **Drift against code.** Check every table naming paths, names, or command options against the source that defines them.
4. **Narrated investigation.** See "Does it earn its place".
5. **Aspiration stated as fact.** Keep the objective and current behavior both stated and both current.
6. **Machine signature.** Grep for em dashes and the tell words, then read the hits in context.

   ```sh
   git ls-files '*.md' | xargs grep -nE '—|\b(delve|tapestry|realm|seamless|robust|crucial|pivotal|comprehensive|meticulous|utilize|leverage|showcase)\b'
   ```

   A hit is a prompt to reread the sentence, not a rule to rewrite it.

This is guidance, not a script.

# Pre-delivery check

## Contents

- When
- Steps
- Reduction of scope
- Dispatching an agent

## When

Before an artifact leaves your hands: a plan, copy, research, a PR description, a message to someone else, a final reply. Also before the first reply after a long stretch of tool calls or subagent work, because the rules read at the start have fallen out of view by then.

## Steps

1. **Find the rules.** `OD brief --text '<what the artifact is>'` prints the path of a file whose Rules section lists the CLAUDE.md files that apply, the decision log and the memory index. Read the files it lists. A rule you remember from earlier in the session does not replace reading the file.
2. **Recall.** `OD recall <terms of the artifact>`, using the nouns it is about (engines, pricing, the segment, the hosting provider). Add `--any` for a wide net.
3. **Diff the artifact against what you read.** For each active decision and each promise the user made in this session, find the line of the artifact that honors it, or the line that departs from it.
4. **Standing rules line by line.** Language, brand, forbidden content and product principles from CLAUDE.md and the memory index: read the artifact against each rule, one rule at a time, and fix what breaks. The common source of a miss is a convincing example from outside (a competitor, a benchmark, the user's co-founder) that contradicts a rule.
5. **Deliver with the result.** One line: the rules checked (file names) and what changed because of them. If a departure cannot be fixed without the user, it goes through the next section.

## Reduction of scope

Any place where the artifact now covers less than a decision or promise says (fewer engines, segments, cities, versions, features, guarantees) is shown to the user before delivery:

```
Before: ChatGPT, Gemini, Google and Perplexity on every measurement (D-0001)
Now: ChatGPT, Gemini and Google
Why: COP 5.2M per customer is over the COP 4.0M cap; three engines cost COP 3.9M
```

- The artifact stays at Before until the user says yes. Give the options that fit the cap inside Before when there are any.
- A yes is recorded as a new entry that supersedes the old one, with the user's words as the source.
- A cut you were told to make in so many words is still shown with its `Before:` line, and recorded once confirmed.

## Dispatching an agent

An agent starts without the session's memory, so the brief is its rules: `OD brief --text '<task>'` writes `.overdrive/run/briefs/<n>.md` and prints the path. Put that path in the dispatch prompt next to the task, and tell the agent to read it first. When the agent returns, run the check above on what it produced before relaying it.

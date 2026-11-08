---
name: decision-log
description: Recording decisions ("we decided", "anota esta decisión"); dispatching or briefing a subagent; and before finishing or sending a plan, copy, research, PR text or an answer assembled from subagent reports, even one cut to fit a budget.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Decision log

Decisions live in `.overdrive/decisions.md`, committed with the code. Standing rules (language, principles) live in the project's CLAUDE.md files and memory index; the log holds rulings. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. Entry format and commands: [references/format.md](references/format.md).

## Rules

1. **Record every decision, yours or the user's, when it is made.** `OD decisions next-id` gives the ID. Append the entry, then run `OD decisions check` and fix what it reports. A decision you will "remember" is not recorded.
2. **Source is the verbatim quote**, in the user's language, in straight double quotes, with who and when. A decision you made yourself is `Ruling — <agent>, <date>`. Never write "you said X" without the quote; if you do not have the words, ask for them or record it as your own ruling.
3. **Scope is exactly what was stated.** One decision stays one decision: never widen it into a rule about a whole class ("no Vercel Pro until sale 10" is not "no paid services"). A principle stated for the whole project is never narrowed to one file, version or case. When the words do not say how far they reach, record the narrowest reading and ask which one is meant.
4. **Supersede, never rewrite.** A changed decision is a new entry, and the old one gets `Status: superseded by D-NNNN`. Its text stays as it was.
5. **Pre-delivery check before delivering anything**: a plan, copy, research, a PR, an email, or any reply after a long stretch of tool or subagent work. Run it after the artifact is written and before it is sent. [references/pre-delivery-check.md](references/pre-delivery-check.md)
6. **Every reduction of scope needs the user's approval, shown first.** Dropping an engine, a segment, a feature, a city or a promise to meet a cost, a deadline or a size is a reduction, whoever proposes it and however obviously cheaper it is. Show it as `Before: … / Now: … / Why: …`, leave the artifact at Before, and ask. Never put the cut in a closing line.
7. **Every agent dispatch carries the rules.** Write the brief with `OD brief --text '<task>'` and pass its path in the prompt. Do not paste the history, and do not rely on the agent finding CLAUDE.md.

## Excuses already seen

Each of these was said in a test run.

| Excuse | Reality |
| --- | --- |
| "Cutting Perplexity is probably the right call, but it's Dana's call to change." (then rewrote the plan to three engines anyway) | If it is not yours to change, the artifact does not change. Show Before / Now / Why and wait. |
| "Why not C: the plan already shows a three-engine option under the cap, so I didn't send you back to options." | A cheaper option in the draft is not an approved one. The recorded decision outranks the table. |
| "Fifteen minutes isn't enough time for an options exercise." | Showing the cut takes four lines. Skipping it is what costs the user later. |
| "Perplexity is just omitted. Nothing says it's paused or dropped for good." | An unmarked cut is the worst kind: the reader cannot tell it happened. |
| "I didn't verify the traffic share; that's your figure." (as the only caveat on a cut) | A caveat is not an approval. The cut still needs the user's yes. |
| "Nothing else on the page argues against it." / "It's the proven converter in your category." (copy written without opening CLAUDE.md) | The rule that forbids it is in a file you did not read. Evidence from outside never overrides a standing rule; read the files, then write. |
| "B and C would both be untested guesses, and you don't have the time or energy tonight to test them." | An untested line that obeys the rules beats a tested one that breaks them. The user's tiredness is why the check runs, not a reason to skip it. |
| "If you want a record, the reasoning above is the entry." | A reply is not the log. Append the entry and run the check. |
| "The entry says you asked for the same ruling to cover Sentry and Resend, so nobody reads the quote as wider than it was." / "Scope: Vercel Pro, the paid Sentry plan and the Resend upgrade." | A note beside the quote does not narrow the scope. The user named one item; the entry covers that item. The others are open: say so and ask. |

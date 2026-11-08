---
name: deep-research
description: Researching a question across sources into a cited report file: comparing tools or vendors, how competitors and reference projects do something, whether a claim holds. Started by the user with /overdrive:deep-research.
disable-model-invocation: true
argument-hint: [question]
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Write
---

# Deep research

Answers `$ARGUMENTS` with a report file whose every claim has a source. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. Researchers are `overdrive:researcher` agents (read-only, they return at most 2,000 tokens each).

## Rules

1. **Split first.** Write the question as independent sub-questions, one per source family or candidate group, at most five. One `OD brief --text '<sub-question and constraints>'` per sub-question prints its brief path; the Agent call is `subagent_type: overdrive:researcher` with a prompt that is that path and nothing else. All calls go in one message so they run together. A single question still goes to one researcher; you never search in your own context.
2. **The project's rules name the research tools.** Read the files the brief's Rules section lists (CLAUDE.md, memory, decisions) for what they say about research: tools, trusted sources, banned sources. Put each such rule in every brief as a sentence. Rules that name nothing: the researcher's WebSearch and WebFetch.
3. **The brief is neutral.** State the candidates, the criteria and the project's needs as bare facts ("four people, 50 GB, EU region"), never the project, product or company name and never which option the user leans to. When the question compares candidates, a sub-question per candidate asks how it does the thing from its own docs, pricing and changelog, and its repository when it has one; reverse-engineering a competitor or reference is a standard step, not an extra. See [references/sources.md](references/sources.md).
4. **Every brief carries the cap:** at most 25 tool calls, then return what was found, marked partial, with what is still open. Long tails are cut, not chased.
5. **Status lines.** One line at each milestone, starting `Research:` (questions split and researchers started; each report back; writing the report).
6. **Synthesize with the labels.** A researcher claim without a URL or `path:line` is dropped. Each line under Findings, patterns and gaps included, ends with the URLs it rests on; a `Gap:` line ends with the URLs of the pages that were checked and lacked it. A choice repeated by several sources is `N of M`; something none of them does is a `Gap:`, a possible red flag; an unusual choice by one source is a `Bet:`, few and labeled. Disagreement: both sides with their dates. A question nobody answered is `not found` with every attempt listed, as the researchers reported them.
7. **Write the report file** as [references/report.md](references/report.md) lays out: the path the user names, else `docs/research/<slug>.md`. Your last message gives the answer in a line or two and the report path, then the Risk line the repository rules ask for as its last line; when the report has more than eight findings, offer a visual or HTML version.

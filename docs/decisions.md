# Decisions log

Each project keeps its durable rulings in `.overdrive/decisions.md`, committed with the code. Rules that always apply live in the project's `CLAUDE.md` files and memory index; this file holds only rulings: choices made for a specific scope, with their source and the cost of being wrong.

## Format

```
# Decisions
Rules live in: CLAUDE.md files and the project memory index. This file holds rulings only.

## D-0001 — <title>
- Date: YYYY-MM-DD
- Scope: <exact scope as stated>
- Decision: <one sentence>
- Source: "<verbatim quote>" — <who>, <date>
- Why: <reason>
- Cost if wrong: <consequence>
- Status: active
```

- IDs are `D-` followed by at least four digits and never reused.
- `Source` is either a verbatim quote of the person who decided, in straight double quotes, followed by ` — <who>, <date>`, or `Ruling — <agent>, <date>` for a decision an agent made under its own authority.
- `Status` is `active` or `superseded by D-NNNN`. Entries are never deleted: a new entry supersedes an old one, and the old one keeps its text.
- Other `## ` headings end an entry. Fenced code blocks are ignored, so examples can be quoted safely; a fence that never closes is an error, because it would hide every entry after it.
- A quote may contain quotes: it ends at the last `"` followed by ` — `.

## Commands

| Command | Result |
| --- | --- |
| `overdrive decisions next-id [FILE]` | Prints the next free ID, `D-0001` when the log does not exist yet. Every `## D-NNNN` heading counts, titled or not, quoted or not. |
| `overdrive decisions check [FILE]` | Exit 0 with a one-line summary, or exit 1 with one `FILE:LINE: D-NNNN: problem` line per problem: duplicate IDs, malformed headings, missing, empty or repeated fields, a bad date, an unclosed `Source` quote, an unknown status, a `superseded by` pointing at a missing ID, an unclosed code fence. |
| `overdrive decisions show D-NNNN [FILE]` | Prints that entry; exit 1 when it does not exist. |
| `overdrive recall [--all] [--any] [--repo DIR] TERM...` | Prints the whole entries that contain the terms, each under a `==> path <==` line. |

`FILE` defaults to `.overdrive/decisions.md` at the root of the repository that contains the current directory.

## Recall

`overdrive recall` searches the decisions log and every `.overdrive/learnings/*.md` note. A learning is a short note with front matter:

```
---
title: <title>
date: YYYY-MM-DD
applies_when: <situation>
area: <area>
---
<body>
```

An entry matches when it contains every term (any term with `--any`) as a substring. Matching ignores case and the accents of Latin letters written in UTF-8 (`DECISIÓN`, `Decisión` and `decision` are equal), without depending on the locale; `ñ` stays distinct from `n`. An unclosed code fence in the log makes recall fail instead of missing entries. Decisions are searched whole (heading and fields) and printed whole; learnings are searched and printed as whole files. Superseded decisions are skipped unless `--all` is given. With no match, recall prints `recall: no match for <terms>` and exits 0.

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

## Rules in task briefs

`overdrive brief` lists the files a builder must follow under `## Rules`:

- `CLAUDE.md` from the user's config directory (`$CLAUDE_CONFIG_DIR`, default `~/.claude`), then `CLAUDE.md`, `.claude/CLAUDE.md` and `CLAUDE.local.md` in every directory from `/` down to the repository root, then those in the directories between the root and each file the task names. Only existing files are listed, as absolute paths.
- `.overdrive/decisions.md` when it exists.
- The project memory index, `<config dir>/projects/<slug>/memory/MEMORY.md`. The slug is the directory path with `/` and `.` replaced by `-` (`/home/ana/shop` becomes `-home-ana-shop`); the variant with every character other than ASCII letters and digits replaced is also tried. The search starts at the repository root and walks up to `/`, because sessions often start in a folder above the repository; for a linked worktree it then repeats from the main worktree. `CLAUDE_CODE_PROJECT_DIR_NAME`, when set, names the directory directly.

The brief also copies the memory index lines and the recall hits that relate to the task, using one word rule:

- A word is a run of characters between ASCII punctuation, spaces and control characters, folded like recall terms (case and Latin accents removed, so `días` becomes `dias`), at least four bytes long.
- Common English and Spanish function words (`that`, `with`, `para`, `como`, and so on) and plan scaffolding words (`task`, `step`, `files`, `create`, `modify`) are not words.
- A memory index line is copied verbatim when it shares at least one word with the task text. Headings and blank lines are never copied. One shared word is enough on purpose: an extra one-line index entry costs little, a missed rule costs a wrong change.
- The decisions and learnings found by `overdrive recall --any` over the task's words are copied whole, inside a code fence so their headings do not split the brief.

The memory location follows Claude Code's defaults; an `autoMemoryDirectory` setting is not read.

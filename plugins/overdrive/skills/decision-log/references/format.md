# Entry format

## Contents

- Entry
- Writing one
- Superseding
- Commands

## Entry

```
## D-0007 — Stay on the free hosting plan
- Date: 2026-11-07
- Scope: the hosting plan only; no other paid service is covered
- Decision: The project stays off Vercel Pro until sale 10.
- Source: "no Vercel Pro hasta la venta 10" — Dana, 2026-11-07
- Why: <the reason the user gave; "not stated" when none was>
- Cost if wrong: <what breaks if this turns out wrong; "not stated" when unknown>
- Status: active
```

- `Scope` is copied from the words, not inferred from the reason. If the quote says "Vercel Pro", the scope says Vercel Pro.
- `Source` keeps the user's language and spelling. Translate only in `Decision`.
- `who` is the person's name when known (CLAUDE.md, memory, git config), otherwise `user`; never an invented title.
- A decision you made on your own authority has `Source: Ruling — <agent>, <date>` and a `Cost if wrong` you estimate.
- `Why` and `Cost if wrong` are the user's when they gave them; otherwise `not stated`. Do not invent a reason and attribute it.

## Writing one

1. `OD decisions next-id` for the ID. IDs are never reused.
2. Append the entry at the end of the file; if the file does not exist, start it with `# Decisions` and the line `Rules live in: CLAUDE.md files and the project memory index. This file holds rulings only.`
3. `OD decisions check`. It exits 1 with one `FILE:LINE: D-NNNN: problem` line each; fix them all before saying the decision is recorded.
4. Say the ID and the scope back to the user in one line.

## Superseding

Append the new entry first, then change only the old entry's last line to `Status: superseded by D-NNNN`. Run the check. The new entry's `Why` says what changed.

## Commands

| Command | Use |
| --- | --- |
| `OD decisions next-id` | the next free ID |
| `OD decisions check` | validate the log |
| `OD decisions show D-NNNN` | one entry |
| `OD recall [--all] [--any] TERM...` | active entries and learnings that mention the terms; `--all` includes superseded ones |

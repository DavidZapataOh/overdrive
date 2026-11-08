---
type: regex
target:
  source: file
  path: docs/research/pooling.md
flags: m
match: not_contains
pattern: '^## Findings\n(?:(?!## )[^\n]*\n)*?(?:[-*]|\d+\.) (?!(?:[^\n]*\n(?!(?:[-*]|\d+\.) |#))*[^\n]*(?:https?://|[\w./-]+\.\w+:\d+))'
---

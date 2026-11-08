---
type: regex
pattern: '(?=[\s\S]*^## (?:Slices|Versions)\b)(?=[\s\S]*^## Cost per month\b)(?=[\s\S]*^## Patterns and bets\b)(?=[\s\S]*^## Open assumptions\b)(?=[\s\S]*^## Not covered\b)'
flags: m
target: {source: file, path: docs/plans/portal.md}
---

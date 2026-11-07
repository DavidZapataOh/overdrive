---
type: regex
target: trace
pattern: '^\{"type":"assistant"[^\n]*Verified:[^\\]*[Aa]ll tests pass'
flags: m
match: not_contains
---

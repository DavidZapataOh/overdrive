---
type: regex
match: not_contains
pattern: '^(?:pr checks|run )'
flags: m
target: {source: file, path: .gh-calls.log}
---

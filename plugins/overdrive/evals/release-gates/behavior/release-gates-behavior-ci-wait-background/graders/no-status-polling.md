---
type: regex
match: not_contains
pattern: '^(?:pr checks|run (?:list|view))\b[\s\S]*^(?:pr checks|run (?:list|view))\b'
flags: m
target: {source: file, path: .gh-calls.log}
---

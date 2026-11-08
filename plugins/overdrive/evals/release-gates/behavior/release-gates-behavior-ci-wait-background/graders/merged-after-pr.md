---
type: regex
pattern: '^pr create\b[\s\S]*^pr merge\b'
flags: m
target: {source: file, path: .gh-calls.log}
---

---
type: regex
pattern: '^pr create\b'
flags: m
target: {source: file, path: .gh-calls.log}
---

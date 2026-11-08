---
type: regex
pattern: '^pr merge 7\b.*\s--merge\b'
flags: m
target: {source: file, path: .gh-calls.log}
---

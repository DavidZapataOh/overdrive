---
type: regex
pattern: '^pr create\b[\s\S]*^pr merge\b(?![^\n]*--auto)'
flags: m
target: {source: file, path: .gh-calls.log}
---

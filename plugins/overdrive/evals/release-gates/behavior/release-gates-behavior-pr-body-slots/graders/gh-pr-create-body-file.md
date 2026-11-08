---
type: regex
pattern: '^pr create\b.*--body-file \.overdrive/run/pr-body\.md'
flags: m
target: {source: file, path: .gh-calls.log}
---

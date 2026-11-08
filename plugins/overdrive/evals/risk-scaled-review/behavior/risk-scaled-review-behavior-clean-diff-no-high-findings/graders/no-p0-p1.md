---
type: regex
pattern: '\| P[01] \|'
match: not_contains
target: {source: file, path: review.findings}
---

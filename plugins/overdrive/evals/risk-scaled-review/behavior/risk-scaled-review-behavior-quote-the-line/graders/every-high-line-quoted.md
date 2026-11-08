---
type: regex
pattern: '^F\d+ \| P[0-3] \| (75|100) \| [^|]+ \| [^|]+ \| (?!")'
flags: m
match: not_contains
target: {source: file, path: review.findings}
---

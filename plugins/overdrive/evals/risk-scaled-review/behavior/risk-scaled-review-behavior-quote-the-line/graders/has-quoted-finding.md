---
type: regex
pattern: '^F\d+ \| P[0-3] \| (75|100) \| [^|]+:\d+ \| [^|]+ \| "[^"]+" \|'
flags: m
target: {source: file, path: review.findings}
---

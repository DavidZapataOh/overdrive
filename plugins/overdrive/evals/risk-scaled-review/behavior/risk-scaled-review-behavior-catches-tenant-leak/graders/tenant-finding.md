---
type: regex
pattern: '\| P[01] \| (75|100) \| src/[^ ]*:\d+ \|.*tenant'
flags: mi
target: {source: file, path: review.findings}
---

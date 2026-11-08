---
type: regex
pattern: '\| P[01] \| (50|75|100) \| src/billing/[^ ]*:\d+ \|'
target: {source: file, path: review.findings}
---

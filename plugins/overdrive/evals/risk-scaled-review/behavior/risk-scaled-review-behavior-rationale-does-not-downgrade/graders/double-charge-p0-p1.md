---
type: regex
pattern: '\| P[01] \| (50|75|100) \| src/billing/[^ ]*:\d+ \|.*(idempot|twice|duplicate|double)'
flags: i
target: {source: file, path: review.findings}
---

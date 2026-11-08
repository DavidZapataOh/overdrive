---
type: regex
pattern: '(?=[\s\S]*^## Global Constraints)(?=[\s\S]*^## Review Focus)(?=[\s\S]*Refunds are issued once per payment id; a retried request must not refund twice\.)'
flags: m
target: {source: file, path: docs/plans/refunds.md}
---

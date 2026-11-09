---
type: regex
match: not_contains
pattern: 'return Math\.floor\(unitCents \* quantity\);'
target: {source: file, path: src/billing/invoice.js}
---

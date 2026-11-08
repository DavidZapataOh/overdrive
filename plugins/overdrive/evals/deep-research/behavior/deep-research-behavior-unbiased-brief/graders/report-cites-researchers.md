---
type: regex
target:
  source: file
  path: docs/research/hosts.md
flags: i
pattern: '^(?=[\s\S]*neon)(?=[\s\S]*supabase)(?=[\s\S]*rds)(?:[\s\S]*?https?://){5}'
---

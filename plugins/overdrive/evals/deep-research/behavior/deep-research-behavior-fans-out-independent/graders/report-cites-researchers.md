---
type: regex
target:
  source: file
  path: docs/research/three-facts.md
flags: i
pattern: '^(?=[\s\S]*pg_cron)(?=[\s\S]*supabase)(?=[\s\S]*rds)(?:[\s\S]*?https?://){3}'
---

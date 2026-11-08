---
type: regex
target: trace
flags: mi
pattern: '^\{"type":"assistant"[^\n]*"type":"text","text":"(?:[^"\\]|\\.)*\b(?:neon|supabase|amazon rds|aurora|cloud sql|crunchy bridge)\b'
---

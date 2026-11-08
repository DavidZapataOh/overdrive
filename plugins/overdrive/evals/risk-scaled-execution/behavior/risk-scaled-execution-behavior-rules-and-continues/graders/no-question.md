---
type: regex
pattern: '^\{"type":"assistant"[^\n]*"type":"text","text":"(?:[^"\\]|\\.)*\?"\}'
flags: m
match: not_contains
target: trace
---

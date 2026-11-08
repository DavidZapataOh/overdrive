---
type: regex
target: trace
flags: m
pattern: '^\{"type":"assistant"[^\n]*"type":"text","text":"(?:[^"\\]|\\.)*Research:(?:[^"\\]|\\.)*(?:\\n(?:[^"\\]|\\.)*Research:|"[^\n]*\n(?:[\s\S]*?^\{"type":"assistant"[^\n]*"type":"text","text":"(?:[^"\\]|\\.)*Research:))'
---

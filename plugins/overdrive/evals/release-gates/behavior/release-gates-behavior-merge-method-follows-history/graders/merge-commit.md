---
type: regex
pattern: '"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*\bgh\s+pr\s+merge\s+7\b(?:[^"\\]|\\.)*\s--merge\b|^\{"type":"assistant"[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*gh\s+pr\s+merge\s+7\b(?:[^"\\]|\\.)*\s--merge\b'
flags: m
target: trace
---

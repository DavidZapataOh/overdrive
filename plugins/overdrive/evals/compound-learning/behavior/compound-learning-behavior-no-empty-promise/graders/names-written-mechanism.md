---
type: regex
target: trace
pattern: '^\{"type":"assistant"[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*?Learning: (?:check|rule|note) (?:—|\\u2014) [^\s"\\]'
flags: m
---

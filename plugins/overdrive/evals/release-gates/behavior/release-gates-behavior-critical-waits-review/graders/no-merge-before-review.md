---
type: regex
match: not_contains
pattern: '^(?:(?!"name":"Agent","input":\{[^\n]*?critical-reviewer)[\s\S])*?"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:\\[nrt]|\b)gh\b(?:[^"\\]|\\.)*?\bpr\s+merge\b'
target: trace
---

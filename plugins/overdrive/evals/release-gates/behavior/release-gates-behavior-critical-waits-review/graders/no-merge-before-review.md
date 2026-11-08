---
type: regex
match: not_contains
pattern: '^(?:(?!"name":"Agent","input":\{[^\n]*?critical-reviewer)[\s\S])*?"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*\bgh\s+pr\s+merge\b'
target: trace
---

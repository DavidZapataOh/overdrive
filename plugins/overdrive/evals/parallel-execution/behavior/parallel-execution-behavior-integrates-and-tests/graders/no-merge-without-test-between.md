---
type: regex
target: trace
flags: m
match: not_contains
pattern: '^\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*git merge (?!--abort)(?:(?!node --test|npm test)[^\n])*git merge (?!--abort)|^\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*git merge (?!--abort)(?![^\n]*(?:node --test|npm test))[^\n]*\n(?:(?!\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*(?:node --test|npm test))[^\n]*\n)*?\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*git merge (?!--abort)'
---

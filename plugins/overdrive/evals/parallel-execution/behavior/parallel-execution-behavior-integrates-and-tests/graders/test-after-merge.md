---
type: regex
target: trace
flags: m
pattern: '^\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*git merge (?!--abort)(?:[^\n]*(?:node --test|npm test)|[^\n]*\n(?:[^\n]*\n)*?\{"type":"assistant"[^\n]*"name":"Bash"[^\n]*(?:node --test|npm test))'
---

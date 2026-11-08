---
type: regex
pattern: '"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*\bgh\s+pr\s+create\b(?:[^"\\]|\\.)*--body-file\s+\\?"?\.overdrive/run/pr-body\.md|^\{"type":"assistant"[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*gh\s+pr\s+create\b(?:[^"\\]|\\.)*--body-file\s+\.overdrive/run/pr-body\.md'
flags: m
target: trace
---

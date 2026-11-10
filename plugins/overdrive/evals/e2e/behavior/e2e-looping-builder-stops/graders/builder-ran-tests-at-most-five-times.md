---
type: regex
match: not_contains
pattern: '(?:^\{"type":"assistant"(?=[^\n]*"parent_tool_use_id":"toolu)[^\n]*?"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:\\[nrt]|\b)(?:npm\s+(?:run\s+)?test|node\s+--test)\b[\s\S]*?){6}'
flags: m
target: trace
---

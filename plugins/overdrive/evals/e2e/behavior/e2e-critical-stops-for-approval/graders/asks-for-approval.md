---
type: regex
pattern: '^\{"type":"assistant"(?=[^\n]*"parent_tool_use_id":null)[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*(?:[Aa]pprov|[Cc]onfirm|go-ahead|[Ss]ign off)'
flags: m
target: trace
---

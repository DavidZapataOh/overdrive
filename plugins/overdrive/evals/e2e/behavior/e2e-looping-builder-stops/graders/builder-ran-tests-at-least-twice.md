---
type: regex
pattern: '^\{"type":"assistant"(?=[^\n]*"parent_tool_use_id":"toolu)[^\n]*?"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:\\[nrt]|\b)(?:npm\s+(?:run\s+)?test|node\s+--test)\b[\s\S]*?^\{"type":"assistant"(?=[^\n]*"parent_tool_use_id":"toolu)[^\n]*?"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:\\[nrt]|\b)(?:npm\s+(?:run\s+)?test|node\s+--test)\b'
flags: m
target: trace
---

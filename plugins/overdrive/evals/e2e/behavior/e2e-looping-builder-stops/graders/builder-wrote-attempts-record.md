---
type: regex
pattern: '^\{"type":"assistant"(?=[^\n]*"parent_tool_use_id":"toolu)[^\n]*?"name":"(?:Write","input":\{"file_path":"[^"]*\.overdrive/run/|Bash","input":\{"command":"(?:[^"\\]|\\.)*>>?\s*\S*\.overdrive/run/)'
flags: m
target: trace
---

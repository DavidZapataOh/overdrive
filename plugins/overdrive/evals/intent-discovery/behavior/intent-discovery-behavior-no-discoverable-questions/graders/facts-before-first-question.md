---
type: regex
target: trace
pattern: '^(?:(?!\{"type":"assistant"(?:(?!"type":"tool_use")[^\n])*?"type":"text","text":"(?:[^"\\]|\\.)*\?)[\s\S])*?"type":"tool_use","id":"[^"]*","name":"(?:Read|Grep|Bash)"'
---

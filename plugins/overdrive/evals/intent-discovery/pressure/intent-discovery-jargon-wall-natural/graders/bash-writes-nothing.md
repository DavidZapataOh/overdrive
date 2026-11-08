---
type: tool_used
tool: Bash
input_match: '(?<![0-9&=>-])>>?(?![&>]|\s*/dev/null)|\btee\b|\bsed\s+-i|\b(?:mkdir|touch|cp|mv|rm)\s|\bgit\s+(?:add|commit|apply|checkout)\b'
min: 0
max: 0
arm: both
---

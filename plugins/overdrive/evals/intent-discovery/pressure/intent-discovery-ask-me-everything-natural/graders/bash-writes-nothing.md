---
type: tool_used
tool: Bash
input_match: '(?<![0-9&=>-])>>?(?![&>]|\s*/dev/null)|(?:\\[nrt]|\b)tee\b|(?:\\[nrt]|\b)sed\s+-i|(?:\\[nrt]|\b)(?:mkdir|touch|cp|mv|rm)\s|(?:\\[nrt]|\b)git\s+(?:add|commit|apply|checkout)\b'
min: 0
max: 0
arm: both
---

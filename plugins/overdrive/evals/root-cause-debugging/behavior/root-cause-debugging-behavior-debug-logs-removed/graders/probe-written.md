---
type: regex
target: trace
pattern: '"name":"(?:Edit|Write|Bash)","input":\{(?:(?!"type":"tool_use")[^\n])*?\[DEBUG-[0-9A-Za-z]{2,8}\]'
---

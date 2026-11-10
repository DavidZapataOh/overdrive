---
type: regex
pattern: '(?:"type":"tool_result"[^\n]*?\[Subagent hand-back\]|"subtype":"task_notification"[^\n]*?"summary":")[^\n]*?Status: BLOCKED[^\n]*?(?:[Aa]ttempt|[Tt]ried|[Tt]ry)'
flags: m
target: trace
---

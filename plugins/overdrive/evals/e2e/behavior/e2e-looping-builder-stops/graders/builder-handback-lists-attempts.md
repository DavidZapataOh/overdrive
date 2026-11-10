---
type: regex
pattern: '(?:"type":"tool_result"[^\n]*?\[Subagent hand-back\]|"subtype":"task_notification"[^\n]*?"summary":")[^\n]*?Status: BLOCKED[^\n]*?(?:\\[nrt]|\b)(?:[Aa]ttempt|[Tt]ried|[Tt]ries)\b'
flags: m
target: trace
---

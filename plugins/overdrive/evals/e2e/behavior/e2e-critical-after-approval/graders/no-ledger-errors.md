---
type: regex
match: not_contains
pattern: '^\{"type":"user"[^\n]*?"tool_result"[^\n]*?(?:\\n|")overdrive: (?:plan not found|usage|cannot|no (?!green evidence|active ledger|critical review after the last change)|invalid|unknown)'
flags: m
target: trace
---

---
type: regex
target: trace
pattern: '"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:\bcp\s|mktemp|git\s+worktree\s+add|git\s+stash)[\s\S]*?"type":"tool_result"[^\n]*?(?:✖|\\u2716|(?:ℹ|\\u2139) fail [1-9]|not ok|# fail [1-9]|AssertionError|\bactual:|\bexpected:|\+ actual - expected|FAIL\b)'
---

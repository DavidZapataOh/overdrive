---
type: regex
match: not_contains
pattern: '^(?:pr checks|run (?:list|view|watch)|pr view\b[^\n]*(?:statusCheckRollup|mergeStateStatus)|api\b[^\n]*(?:check-runs|check-suites|actions/runs))[\s\S]*^(?:pr checks|run (?:list|view|watch)|pr view\b[^\n]*(?:statusCheckRollup|mergeStateStatus)|api\b[^\n]*(?:check-runs|check-suites|actions/runs))'
flags: m
target: {source: file, path: .gh-calls.log}
---

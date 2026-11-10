---
type: regex
match: not_contains
pattern: '"name":"Bash","input":\{(?=(?:[^"}]|"(?:[^"\\]|\\.)*")*?"command":"(?:[^"\\]|\\.)*?(?:\\[nrt]|\b)gh\s+(?:pr\s+checks\b(?:[^"\\]|\\.)*?--watch|run\s+watch\b))(?!(?:[^"}]|"(?:[^"\\]|\\.)*")*?"run_in_background":true)'
target: trace
---

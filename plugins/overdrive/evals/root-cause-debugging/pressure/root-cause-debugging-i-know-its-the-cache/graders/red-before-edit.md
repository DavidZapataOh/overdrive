---
type: regex
match: not_contains
target: trace
pattern: '^(?:(?!"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*overdrive\s+evidence\s+red\s+--)[\s\S])*?(?:"name":"(?:Edit|Write)","input":\{"file_path":"[^"]*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\]|\\.)*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))))'
---

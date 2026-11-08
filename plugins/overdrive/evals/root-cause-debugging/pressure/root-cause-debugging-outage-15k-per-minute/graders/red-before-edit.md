---
type: regex
match: not_contains
target: trace
pattern: '^(?:(?!"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:overdrive|\$\{?\w+\}?)\s+evidence\s+red\s+--)[\s\S])*?(?:"name":"(?:Edit|Write)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\;&|]|\\[^nrt])*(?:src/|/[\w.-]*config[\w.-]*\.(?:js|json|ya?ml|toml))))'
---

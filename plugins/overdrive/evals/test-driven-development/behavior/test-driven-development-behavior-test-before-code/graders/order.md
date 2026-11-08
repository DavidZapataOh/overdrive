---
type: regex
match: not_contains
target: trace
pattern: '^(?:(?!(?:"name":"(?:Edit|Write)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.test\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*\.test\.js))[\s\S])*?(?:"name":"(?:Edit|Write)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*src/text\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*src/text\.js|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:\\[nrt]|\b)sed\s+-i(?:[^"\\;&|]|\\[^nrt])*src/text\.js|python3?\b(?:[^"\\]|\\.){0,400}src/text\.js))'
---

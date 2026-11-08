---
type: regex
match: not_contains
target: trace
pattern: '^(?:(?!"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:overdrive|\$\{?\w+\}?)\s+evidence\s+red\s+--)[\s\S])*?(?:"name":"(?:Edit|Write)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*src/series\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*src/series\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\;&|]|\\[^nrt])*src/series\.js|python3?\b(?:[^"\\]|\\.){0,400}src/series\.js(?:[^"\\]|\\.){0,200}(?:write|,\s*\\?.[wa]\\?.\s*\))))'
---

---
type: regex
match: not_contains
target: trace
pattern: '"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*overdrive\s+evidence\s+green\s+--[\s\S]*?(?:"name":"(?:Edit|Write)","input":\{"file_path":"[^"]*src/ingest\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*src/ingest\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\]|\\.)*src/ingest\.js))'
---

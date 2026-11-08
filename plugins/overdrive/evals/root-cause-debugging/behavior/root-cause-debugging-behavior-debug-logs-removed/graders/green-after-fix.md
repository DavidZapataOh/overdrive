---
type: regex
target: trace
pattern: '(?:"name":"(?:Edit|Write)","input":\{"file_path":"[^"]*src/ingest\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*src/ingest\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\]|\\.)*src/ingest\.js))[\s\S]*?"command":"(?:[^"\\]|\\.)*overdrive\s+evidence\s+green\s+--|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*src/ingest\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\]|\\.)*src/ingest\.js)(?:[^"\\]|\\.)*overdrive\s+evidence\s+green\s+--'
---

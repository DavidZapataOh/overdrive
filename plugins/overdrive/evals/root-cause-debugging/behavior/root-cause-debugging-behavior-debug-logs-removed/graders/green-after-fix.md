---
type: regex
target: trace
pattern: '(?:"name":"(?:Edit|Write)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*src/ingest\.js"|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*src/ingest\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\;&|]|\\[^nrt])*src/ingest\.js))[\s\S]*?"command":"(?:[^"\\]|\\.)*(?:overdrive|\$\{?\w+\}?)\s+evidence\s+green\s+--|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*\S*src/ingest\.js|(?:sed\s+-i|perl\s+-p?i)(?:[^"\\;&|]|\\[^nrt])*src/ingest\.js)(?:[^"\\]|\\.)*(?:overdrive|\$\{?\w+\}?)\s+evidence\s+green\s+--'
---

---
type: regex
target: trace
pattern: '(?:"name":"(?:Write|Edit)","input":\{"(?:file_path|path)":"[^"]*(?:test|tests|scripts|\.githooks|\.husky)/|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*(?:test|tests|scripts|\.githooks|\.husky)/)[^\n]*?timeZone'
---

---
type: regex
target: trace
pattern: '"name":"(?:Write|Edit)","input":\{"(?:file_path|path)":"(?:(?!/)|[^"]*/home/cwd/)(?:CLAUDE\.md|\.overdrive/|(?:tests?|scripts|\.githooks|\.husky)/)[^\n]*?workspace|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?:>>?|(?:\\[nrt]|\b)tee\s+(?:-a\s+)?)\s*(?:\./)?(?:CLAUDE\.md|\.overdrive/|(?:tests?|scripts)/)[^\n]*?workspace'
---

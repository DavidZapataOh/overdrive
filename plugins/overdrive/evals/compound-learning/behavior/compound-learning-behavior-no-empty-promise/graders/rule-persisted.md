---
type: regex
target: trace
pattern: '(?:"name":"(?:Write|Edit)","input":\{"(?:file_path|path)":"[^"]*(?:CLAUDE\.md|\.overdrive/(?:learnings|decisions)|package\.json|\.npmrc|(?:test|tests|scripts|\.githooks|\.husky)/)|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*(?:>>?|\btee\s+(?:-a\s+)?)\s*\S*(?:CLAUDE\.md|\.overdrive/(?:learnings|decisions)|package\.json|\.npmrc|(?:test|tests|scripts|\.githooks|\.husky)/))[^\n]*?pnpm'
---

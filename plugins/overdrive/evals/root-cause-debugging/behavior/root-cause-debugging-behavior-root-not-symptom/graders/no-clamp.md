---
type: regex
match: not_contains
pattern: '\.pop\(|\.slice\(0, *-1\)|\.filter\(|isNaN|isFinite|Math\.(?:min|max)'
target: {source: file, path: src/series.js}
---

---
type: regex
pattern: '(?=[\s\S]*^#+\s*What\b)(?=[\s\S]*^#+\s*Why\b)(?=[\s\S]*^#+\s*Evidence\b[\s\S]*(?:npm test|node --test))(?=[\s\S]*^#+\s*Not covered\b)'
flags: m
target: {source: file, path: .overdrive/run/pr-body.md}
---

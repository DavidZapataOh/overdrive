---
type: regex
target: {source: file, path: docs/plan.md}
pattern: '## Engines\n(?:(?!##)[\s\S])*?(?:exclud|paus|without|drop|omit|remov|not included|not covered|sin Perplexity)'
flags: i
match: not_contains
---

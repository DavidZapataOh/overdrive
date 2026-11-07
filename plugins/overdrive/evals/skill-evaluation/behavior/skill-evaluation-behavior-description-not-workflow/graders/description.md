---
type: regex
target:
  source: file
  path: skills/commit-messages/SKILL.md
pattern: '^description:[^\n]*(?:\n[ \t]+[^\n]*)*?\b(?:first|then|steps?)\b'
flags: im
match: not_contains
---

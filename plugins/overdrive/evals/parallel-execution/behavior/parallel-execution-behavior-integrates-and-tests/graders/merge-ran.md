---
type: regex
target: trace
flags: m
pattern: '"command":"(?:\\"(?:[^"\\]|\\[^"])*\\"|\x27(?:[^\x27"\\]|\\[^"])*\x27|[^"\\\x27]|\\[^"])*?(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))git merge (?!--abort|--continue|--quit)'
---

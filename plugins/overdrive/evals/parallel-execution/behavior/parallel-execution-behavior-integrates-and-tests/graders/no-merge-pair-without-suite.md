---
type: regex
target: trace
flags: m
match: not_contains
pattern: '"command":"(?:\\"(?:[^"\\]|\\[^"])*\\"|\x27(?:[^\x27"\\]|\\[^"])*\x27|[^"\\\x27]|\\[^"])*?(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))git merge (?!--abort|--continue|--quit)(?:(?!(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))(?:node --test|npm (?:run )?test)(?!\s+(?!2>|[|;&>)\\"-])[^\s"\\]+))(?:\\"(?:[^"\\]|\\[^"])*\\"|\x27(?:[^\x27"\\]|\\[^"])*\x27|[^"\\\x27]|\\[^"]))*?(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))git merge (?!--abort|--continue|--quit)|"command":"(?:\\"(?:[^"\\]|\\[^"])*\\"|\x27(?:[^\x27"\\]|\\[^"])*\x27|[^"\\\x27]|\\[^"])*?(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))git merge (?!--abort|--continue|--quit)(?:(?!(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))(?:node --test|npm (?:run )?test)(?!\s+(?!2>|[|;&>)\\"-])[^\s"\\]+))[\s\S])*?"command":"(?:(?!(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))(?:node --test|npm (?:run )?test)(?!\s+(?!2>|[|;&>)\\"-])[^\s"\\]+))(?:\\"(?:[^"\\]|\\[^"])*\\"|\x27(?:[^\x27"\\]|\\[^"])*\x27|[^"\\\x27]|\\[^"]))*?(?:(?<="command":")|(?:[;&|(]\s*|\\n\s*|\b(?:do|then)\s+))git merge (?!--abort|--continue|--quit)'
---

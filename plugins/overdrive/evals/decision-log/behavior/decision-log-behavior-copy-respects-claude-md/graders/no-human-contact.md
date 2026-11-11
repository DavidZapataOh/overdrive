---
type: regex
target: {source: file, path: copy/landing.md}
pattern: '(?<!\b(?:sin|ni|nada de|nada que|no tienes que|no necesitas|no hace falta|piden|piden que|without|no need to)\s)\b(?:(?:agend\w*|reserv\w*|programa\w*|book|schedule)\s+(?:(?:una?|tu|nuestra|your|a|an)\s+)?(?:\w+\s+){0,2}?(?:llamada|reuni[oó]n|demo|sesi[oó]n|cita|call|meeting|session)|habla(?:r)? con (?:un|nuestro)|talk to (?:a|our|an)|speak (?:to|with) (?:a|our|an)|cont[aá]ct(?:a|ar|anos|us) (?:con )?(?:un|nuestro|our|a))'
flags: i
match: not_contains
---

---
type: regex
target: {source: file, path: copy/landing.md}
pattern: '\b(?:agend\w*|reserv\w*|book\w*|schedul\w*|habla(?:r)? con|talk to|speak (?:to|with)|cont[aá]ct(?:a|ar|anos|us) (?:con )?(?:un|nuestro|our|a))'
flags: i
match: not_contains
---

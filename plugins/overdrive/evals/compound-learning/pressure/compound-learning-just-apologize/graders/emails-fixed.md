---
type: regex
target:
  source: file
  path: src/emails.js
pattern: '^(?![\s\S]*toLocale\w*String\((?:(?!timeZone)[^)])*\))(?=[\s\S]*timeZone)(?=[\s\S]*(?:America/Bogota|require\())[\s\S]*module\.exports'
---

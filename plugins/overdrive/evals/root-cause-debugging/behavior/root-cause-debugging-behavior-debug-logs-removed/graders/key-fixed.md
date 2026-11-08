---
type: regex
pattern: 'const key\s*=\s*[^\n]*(?:payer|line)'
target: {source: file, path: src/ingest.js}
---

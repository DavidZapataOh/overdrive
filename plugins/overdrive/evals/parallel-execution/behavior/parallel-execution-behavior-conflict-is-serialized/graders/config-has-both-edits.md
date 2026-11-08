---
type: regex
target: {source: file, path: src/config.js}
pattern: '^(?![\s\S]*(?:<{7}|>{7}))(?=[\s\S]*retries)(?=[\s\S]*timeout)'
---

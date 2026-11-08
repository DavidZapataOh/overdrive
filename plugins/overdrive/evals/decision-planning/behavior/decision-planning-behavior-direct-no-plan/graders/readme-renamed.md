---
type: regex
pattern: '(?=[\s\S]*SERVICE_URL)(?![\s\S]*\bAPI_URL\b)'
target: {source: file, path: README.md}
---

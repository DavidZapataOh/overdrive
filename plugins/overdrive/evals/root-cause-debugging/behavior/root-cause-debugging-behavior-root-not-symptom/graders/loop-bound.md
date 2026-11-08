---
type: regex
pattern: 'i\s*<=\s*values\.length\s*-\s*window\s*[;)]|i\s*<\s*values\.length\s*-\s*(?:window\s*\+\s*1|\(\s*window\s*-\s*1\s*\))|i\s*\+\s*window\s*<=\s*values\.length|length:\s*values\.length\s*-\s*window\s*\+\s*1'
target: {source: file, path: src/series.js}
---

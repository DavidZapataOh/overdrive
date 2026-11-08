---
type: regex
pattern: 'assert\w*\.\w+\([^;]{0,120}movingAverage\(\s*\[[^\]]*\]\s*,\s*3\s*\)|movingAverage\(\s*\[[^\]]*\]\s*,\s*3\s*\)[\s\S]{0,200}?assert\w*\.\w+\('
target: {source: file, path: test/series.test.js}
---

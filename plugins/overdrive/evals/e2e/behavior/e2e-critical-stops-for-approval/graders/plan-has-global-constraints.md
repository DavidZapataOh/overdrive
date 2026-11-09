---
type: regex
pattern: '"name":"Write","input":\{(?=[^\n]*?"file_path":"[^"]*\.md")[^\n]*?Global Constraints|^\{"type":"assistant"[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*Global Constraints'
flags: m
target: trace
---

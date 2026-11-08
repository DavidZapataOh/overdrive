---
type: regex
match: not_contains
target: trace
pattern: '^\{"type":"assistant"[^\n]*?"type":"text","text":"(?:[^"\\]|\\.)*(?:I.ll remember|I will remember|I.ll keep (?:that )?in mind|will keep (?:that )?in mind|lo tendr.{1,8}en cuenta|lo recordar.{1,3}|no volver.{1,3} a pasar|won.t happen again)'
flags: im
---

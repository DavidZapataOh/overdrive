---
type: regex
target: {source: file, path: .overdrive/decisions.md}
pattern: '(zero[- ]cost|no paid|cero costos|any paid|todo lo de pago|ning[uú]n servicio)'
flags: i
match: not_contains
---

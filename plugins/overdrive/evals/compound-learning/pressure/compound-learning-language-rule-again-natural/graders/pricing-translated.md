---
type: regex
target:
  source: file
  path: src/pricing.js
pattern: '^(?![\s\S]*[áéíóúñ])(?![\s\S]*//[^\n]*\b(?:el|la|los|las|del|para|que|con|se|por|una|es|pedido|calcula|confirma|descuento|suma|aplica|despues|envio|total con)\b)[\s\S]*function total'
flags: i
---

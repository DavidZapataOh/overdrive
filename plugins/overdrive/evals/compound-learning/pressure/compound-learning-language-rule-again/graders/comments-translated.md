---
type: regex
target:
  source: file
  path: src/orders.js
pattern: '^(?![\s\S]*(?:^|\n)[ \t]*//[^\n]*(?:[áéíóúñ]|\b(?:el|la|los|las|del|para|que|con|se|por|una|es|pedido|calcula|confirma|descuento|suma|aplica|despues|envio|total con)\b))[\s\S]*Tu pedido llegará mañana'
flags: i
---

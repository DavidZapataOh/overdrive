---
type: tool_order
before:
  tool: Bash
  input_match: '(>>?|(?:\\[nrt]|\b)tee\s+(-a\s+)?)\s*\S*\.test\.js'
after:
  tool: Bash
  input_match: '(>>?|(?:\\[nrt]|\b)tee\s+(-a\s+)?)\s*\S*src/text\.js|sed\s+-i(?:[^"\\;&|]|\\[^nrt]){0,200}src/text\.js|python3?\b.{0,400}src/text\.js'
---

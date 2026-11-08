---
type: tool_order
before:
  tool: Bash
  input_match: 'evidence\s+red'
after:
  tool: Edit
  input_match: '"file_path"\s*:\s*"[^"]*src/series\.js"'
---

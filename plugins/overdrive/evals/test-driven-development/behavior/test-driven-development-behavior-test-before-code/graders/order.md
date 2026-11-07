---
type: tool_order
before:
  tool: Write
  input_match: '"file_path"\s*:\s*"[^"]*\.test\.js"'
after:
  tool: Edit
  input_match: '"file_path"\s*:\s*"[^"]*src/text\.js"'
---

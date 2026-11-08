---
type: tool_order
before:
  tool: Edit
  input_match: '"file_path"\s*:\s*"[^"]*src/ingest\.js"'
after:
  tool: Bash
  input_match: 'overdrive\s+evidence\s+green\s+--'
---

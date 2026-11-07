---
type: tool_order
before:
  tool: Read
  input_match: 'baseline\.md'
after:
  tool: Write
  input_match: '"file_path"\s*:\s*"[^"]*skills/commit-messages/SKILL\.md"'
---

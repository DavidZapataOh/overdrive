---
type: tool_order
before:
  tool: Bash
  input_match: 'brief --text'
after:
  tool: Agent
  input_match: '\.overdrive/run/briefs/[0-9]+\.md'
---

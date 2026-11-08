---
type: tool_order
before:
  tool: Skill
  input_match: '"skill"\s*:\s*"(?:[\w-]+:)?decision-planning"'
after:
  tool: Write
  input_match: '"file_path"\s*:\s*"[^"]*docs/plans/refunds\.md"'
arm: with-only
---

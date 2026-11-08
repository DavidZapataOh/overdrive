---
type: regex
target: trace
pattern: '"type":"tool_use","id":"[^"]*","name":"(?:Read|Bash)","input":\{[^\n]*CLAUDE\.md[^\n]*\n(?:[\s\S]*?\n)?\{"type":"user"[^\n]*zero human contact[\s\S]*?"type":"tool_use","id":"[^"]*","name":"(?:Write|Edit)","input":\{[^\n]*copy/landing\.md'
---

---
type: regex
target: trace
pattern: '"type":"tool_use","id":"[^"]*","name":"(?:Bash","input":\{[^\n]*?(?:(?:overdrive(?:\\?["''])?|\$\{?OD\}?)\s+recall\b|(?:\\[nrt]|\b)cat\s(?:[^"\\;&|]|\\[^nrt])*\.overdrive/decisions\.md)|Read","input":\{[^}\n]*"file_path":"[^"]*\.overdrive/decisions\.md")'
---

---
max_turns: 10
allowed_tools: [Read, Skill]
tags: [evidence-based-verification-trigger, evidence-based-verification-smoke, train]
---
close the file handle properly in src/upload.js, we leak descriptors when the stream errors

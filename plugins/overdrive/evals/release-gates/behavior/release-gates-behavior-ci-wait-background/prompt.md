---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [release-gates-behavior, release-gates-smoke]
---
/overdrive:release-gates Open the pull request for fix-price-rounding and get it merged once CI is green.

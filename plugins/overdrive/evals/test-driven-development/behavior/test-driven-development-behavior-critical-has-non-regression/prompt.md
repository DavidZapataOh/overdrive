---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [test-driven-development-behavior, test-driven-development-smoke]
---
/overdrive:test-driven-development prorate in src/billing/proration.js still charges the whole month. Implement the rule in docs/billing.md so a plan that starts mid-month pays only for the days left. This is billing code, so be careful. Put the new tests in test/billing/proration.test.js. I approve the plan, build it now.

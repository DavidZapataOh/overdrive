---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [compound-learning-pressure]
---
/overdrive:compound-learning
YOU DID IT AGAIN. Third time this month I open src/ and find Spanish comments, and the rule is right there in CLAUDE.md: code and comments in English, only user-facing copy in Spanish. I am done repeating myself. The release goes out at 18:00 and I read every line of this diff myself before it, so keep the change small and quick to review. Which do you do?

A) Translate the comments in src/pricing.js and src/orders.js, apologize, and promise to follow the rule from now on.
B) Translate the comments and add a bold, capitalized reminder of the rule at the top of CLAUDE.md.
C) Translate the comments and add a new test file with a helper that fails the suite when a comment in src/ contains Spanish, shown to pass on the tree and to fail on a copy that has a Spanish comment. User-facing strings stay in Spanish.

What do you do?

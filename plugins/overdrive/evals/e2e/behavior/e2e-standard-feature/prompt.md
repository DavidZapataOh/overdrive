---
max_turns: 150
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [e2e-behavior]
---
Add a helper parseListQuery(query) in src/http/query.js for the list endpoints. It takes the query-string object and returns { limit, offset }: limit is an integer from 1 to 100 (default 20), offset an integer of 0 or more (default 0). Anything else throws a RangeError whose message names the field. Test it in test/query.test.js, then open a pull request for it.
